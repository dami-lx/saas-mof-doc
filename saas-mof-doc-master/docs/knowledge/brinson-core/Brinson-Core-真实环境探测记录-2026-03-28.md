# Brinson-Core 真实环境探测记录（2026-03-28）

## 1. 本次探测目标

这次探测不是为了直接完成全部导出，而是为了确认三件“能否继续重构”的前置事实：

- DNS 不稳定后，直接使用 IP 是否可以访问真实 Datayes / Redis
- 请求里的关键主键是否真的能映射到外部数据源
- Redis 里的 Brinson 关键数据是否存在，以及当前 Python 环境能否直接解码

## 2. 网络连通性结论

### Datayes MySQL

- 原域名 `db-dydbdev-ro.wmcloud.com`
- 当前可解析到 `10.22.220.50`
- `10.22.220.50:3313` 可成功连接并执行查询

### Risk Model MySQL

- `10.27.30.247:3310` TCP 可连接
- 但执行 `SELECT 1` 时返回 `Lost connection to MySQL server during query`

这说明：

- 风险库不是简单的“网络不通”
- 更可能是协议、网关、权限、白名单、SQL 代理层策略等问题
- 现阶段不能把 risk model 的主路径设计成“只靠这个 MySQL 直连”

### Redis Cluster

- `10.24.95.67:6379`、`10.24.95.68:6379`、`10.24.95.69:6379` 都可连通
- AUTH 和 PING 成功
- 这是一个 Redis Cluster，不是单机 Redis
- 对很多 key 直接 `GET` 会返回 `MOVED`

这意味着：

- 后续 exporter 必须实现 cluster-aware 访问
- 不能只把一个节点当作单机 Redis 用

## 3. 请求主键口径确认

针对 `brain-brinson-test/a-brinson-request.json` 里的样例做了核对：

- `consPositionId` 可以直接映射到 `md_security.SECURITY_ID`
- 例如：
  - `2895 -> 601058 -> 赛轮轮胎`
  - `260193 -> 09988 -> 阿里巴巴-W`
  - `10003956 -> 00700 -> 腾讯控股`

这是一个非常关键的结论，因为它说明：

- 请求里的证券标识可以直接作为 reference data join key
- Rust `SecurityUniverse` 后续完全可以基于 `consPositionId` 构建稳定索引

## 4. Benchmark 1782 的真实映射含义

这是本次最重要的一个数据口径发现。

### 4.1 直接查 `IDX_MAPPING_MOM.ID = 1782`

得到的并不是“沪深300”，而是一条别的指数映射记录。

### 4.2 按旧 Python 代码语义核对

`lib/data_loader/dy_mysql/benchmark.py` 中的真实逻辑是：

- 输入的 benchmark id 会当作 `IDX_MAPPING_MOM.SECURITY_ID`
- 再映射到 `SRC_ID`
- `WEIGHT_LOCATED_TABLE` 决定去哪个权重表查成分

对应 1782 的结果是：

- `SECURITY_ID = 1782`
- `SRC_ID = 1782`
- `SEC_SHORT_NAME = 沪深300`
- `WEIGHT_LOCATED_TABLE = csi_idx_weight`
- `IDX_MAPPING_MOM.ID = 158`

也就是说：

- `brain` / `mom` 业务侧传来的 benchmark id，并不是映射表主键
- 它在这条链路中的语义更接近“benchmark security_id”

这在 Rust 重构里必须显式建模，不能误用成 `mapping_id`。

## 5. 已确认的 Redis 关键 key 口径

结合源码与真实访问，已经确认：

- 股票收益 key
  - `stock:ret:d:{td}`
- 行业 key
  - `ind:SW1:21:{td}`
  - 这对应业务侧的 `SW21_1`
- benchmark 成分 key
  - `bm:{benchmark_id}:{td}`
- SW21 风险模型
  - `fret_sw21:d:{td}`
  - `sret_sw21:d:{td}`
  - `rm_sw21:exp:{td}`
  - `rm_sw21:cov:short:{td}`
  - `rm_sw21:srisk:short:{td}`

这里有一个重要翻译关系：

- 业务行业口径 `SW21_1`
- Redis 实际 key 口径 `ind:SW1:21:{td}`

所以 provider 不能只保留一个拼接字符串，而应该保留结构化字段：

- category = `SW`
- version = `21`
- level = `1`

## 6. Redis 中数据是否存在

答案是存在。

已经通过 Redis Cluster 重定向拿到真实 payload 的 key 包括：

- `stock:ret:d:20250110`
- `ind:SW1:21:20250110`
- `bm:1782:20250110`
- `fret_sw21:d:20250110`
- `rm_sw21:exp:20250110`
- `rm_sw21:cov:short:20250110`
- `rm_sw21:srisk:short:20250110`

所以现在的主要阻碍不是“数据缺失”，而是“旧序列化格式兼容”。

## 7. 当前解码阻碍

在本地当前 Python 环境中，直接解码 Redis payload 时遇到两类兼容问题：

### 7.1 旧版 pandas pickle 模块路径变化

典型报错：

- `No module named 'pandas.core.indexes.numeric'`

这通常意味着：

- Redis 中的对象是由更老版本 pandas 序列化的
- 当前环境 pandas 版本较新，旧模块路径已经消失

### 7.2 pandas 内部 BlockManager 结构变化

典型报错：

- `Argument 'placement' has incorrect type (expected pandas._libs.internals.BlockPlacement, got slice)`

这通常意味着：

- 即使模块路径兼容了，DataFrame 内部 pickle 结构也和当前 pandas 版本不兼容

## 8. 对重构策略的影响

这次探测带来一个很明确的结论：

- reference data 的“在线读取”与“算法计算”必须继续解耦

推荐路线没有变，反而更被验证了：

1. 先做 snapshot exporter
2. 把旧 Redis / MySQL 数据转成我们自己的稳定中间格式
3. Rust 核心只消费 snapshot，不直接依赖旧 pickle 生态

这也是 `FileSnapshotReferenceDataProvider` 路线正确的直接证据。

## 9. 兼容性补丁验证结论

后续在 Python 3.11 导出环境里继续验证时，已经确认下面两层 shim 能成功解开本次 Brinson 的关键 Redis payload：

- 为旧 pickle 注入 `pandas.core.indexes.numeric`
- patch `pandas._libs.internals._unpickle_block`，把旧 `slice / ndarray placement` 包装成 `BlockPlacement`

基于这个兼容层，已经成功读取：

- `stock:ret:d:20250102`
- `ind:SW1:21:20250102`
- `bm:1782:20250102`
- `rm_sw21:exp:20250102`
- `rm_sw21:cov:short:20250102`
- `rm_sw21:srisk:short:20250102`

这说明当前最大的工程突破已经从：

- “能不能读到真实数据”

变成了：

- “Rust 的 reference model 能不能完整表达 benchmark 全成分”

## 10. 下一步建议

下一步建议优先做下面两件事：

### 9.1 做一个只读 probe / exporter 工具

职责：

- cluster-aware 访问 Redis
- 查询 Datayes benchmark 映射
- 尝试读取指定日期的股票收益、行业、benchmark 成分、风险模型数据
- 输出“存在性 + 解码兼容性 + 样本元信息”

当前仓库里已经补了脚本：

- `tools/brinson_snapshot_probe.py`

### 9.2 解决旧 pickle 兼容

可以考虑两条路：

- 使用与旧 `brain` 更接近的 pandas 版本单独开一个导出环境
- 或者直接借用现有 `brain` 代码环境执行导出，让导出脚本只负责调用和落盘

从稳定性看，第二条通常更稳。
