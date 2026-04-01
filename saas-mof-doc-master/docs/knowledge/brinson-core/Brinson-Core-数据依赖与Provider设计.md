# Brinson-Core 数据依赖与 Provider 设计

## 1. 文档目标

这篇文档回答三个重构阶段里最关键的问题：

- Rust 版本 Brinson 最少要吃哪些数据，才能闭环算出结果
- 这些数据在旧 `brain` 链路里分别来自哪里
- 新工程里应该怎样把这些依赖抽象成可替换、可缓存、可测试的 provider

这篇文档是后续接 Redis、MySQL、离线导出文件和本地回归样例的统一依据。

## 2. 最小数据依赖集合

如果目标是先完成行业 Brinson 的闭环，最小依赖集是：

- `trading_days`
  - 计算期间内的有效交易日序列
- `security_returns`
  - 证券在各归因日期上的收益率
- `benchmark_weights`
  - 基准在各归因日期上的成分股权重
- `benchmark_returns`
  - 基准本身在各归因日期上的收益率
- `security_industries`
  - 证券在各归因日期上的行业映射

如果目标继续扩展到风格归因，则还需要：

- `factor_returns`
  - 风格因子收益
- `factor_exposures`
  - 个股因子暴露
- `risk_covariance`
  - 因子协方差矩阵
- `specific_risks`
  - 个股特异风险

## 3. 旧链路中的真实来源

从 `brain` 当前代码分析，Brinson 的 reference data 并不是简单“直接查库”，而是分两层：

### 第一层：brain 内部 data_loader / brain_redis

典型路径：

- `lib/data_loader/brain_redis/stock.py`
- `lib/data_loader/brain_redis/benchmark.py`
- `lib/data_loader/brain_redis/risk_model.py`

这一层负责：

- 优先从 Redis 拿缓存结果
- 用统一 key 约定屏蔽底层表结构差异
- 作为算法模块读取外部数据的直接入口

### 第二层：dy_mysql 物理表

当缓存未命中或需要底层回源时，会落到 MySQL 表。

已识别的关键表包括：

- 交易日历
  - `md_trade_cal`
- 证券基础映射
  - `md_security`
- benchmark 映射与成分
  - `IDX_MAPPING_MOM`
  - `IDX`
  - 以及 `WEIGHT_LOCATED_TABLE` 指向的权重表
- SW21 风险模型
  - `dy1d_exposure_sw21`
  - `dy1d_factor_ret_sw21`
  - `dy1d_specific_ret_sw21`
  - `dy1d_covariance_sw21`
  - `dy1d_srisk_sw21`

## 4. 已识别的 Redis key 口径

根据 `brain_redis` 的实现，当前已确认的 key 模式包括：

- 股票收益
  - `stock:ret:{freq_short}:{td}`
- 行业映射
  - `ind:{type+level}:{version?}:{td}`
- benchmark 成分
  - `bm:{benchmark_id}:{td}`
- 风险模型
  - 因子收益 / 暴露 / 协方差 / 特异风险分别有 sw21 / cne6 对应 key

这一点非常重要，因为 Rust 重构时不一定要直接模仿 Python 包结构，但必须保留同一批“数据语义对象”。

## 5. 新工程里的 provider 分层建议

当前 `brinson-core` 已经把外部数据边界统一成：

- `BrinsonReferenceDataProvider`
- `ReferenceDataBundle`

建议后续坚持三层 provider 策略：

### 5.1 FileSnapshotProvider

职责：

- 读取本地 JSON / parquet / csv 导出的 reference snapshot
- 用于开发、调试、回归测试和离线对账

优点：

- 最稳定
- 最适合先把算法内核跑通
- 不依赖网络、账号、线上环境波动

当前 Rust 工程已经先落了第一版：

- `FileReferenceDataSnapshot`
- `FileSnapshotReferenceDataProvider`

它负责：

- 按请求日期范围裁剪数据
- 只保留当前请求 benchmark 的相关数据
- 校验 `security_index` 是否在请求的证券 universe 范围内
- 标准化 `style_fields` / `industry_fields`

### 5.2 MySqlProvider

职责：

- 直接从底层物理表回源
- 用于补数据、离线构建 snapshot、验证 Redis 缓存内容

更适合扮演：

- snapshot 构建器
- 数据核对器
- fallback loader

而不一定要成为运行时第一入口。

### 5.3 RedisAwareProvider

职责：

- 优先读取 Redis 的逻辑快照
- 必要时回落 MySQL

这会最贴近现有生产行为，但实现复杂度也最高，所以建议放在第三阶段。

## 6. 为什么先做 FileSnapshotProvider

因为它能同时解决三个重构痛点：

- 把“算法逻辑”和“数据接入波动”拆开
- 把 QA case 扩展成真正可复用的测试资产
- 为后续做 benchmark / 行业 / 风险模型逐层替换建立稳定输入格式

换句话说，先把 provider 做成 snapshot 友好，后面就能：

- 用线上导出结果做 parity test
- 用一份 snapshot 同时喂 Rust 和 Python，对比中间过程
- 将来把 Redis / MySQL 的不稳定性隔离在导出层，而不是算法层

## 7. 当前还缺的真实环境信息

目前最现实的连接问题不是代码，而是基础设施连通性：

- 一个 MySQL host 走域名，当前环境 DNS 不稳定
- Redis cluster 也需要确认当前机器的可达性

后续只要补齐以下映射信息，就可以继续把 provider 往真实数据源推进：

- MySQL 域名对应 IP
- 如果 Redis 需要走代理，也要给出代理 IP / port
- 如果某些表只允许内网访问，需要确认当前工作环境是否已具备路由

## 8. 推荐的落地顺序

1. 先用文件快照跑通行业 Brinson 最小闭环
2. 用 MySQL 连接脚本把交易日、benchmark、收益率、行业映射导出成 snapshot
3. 补风格归因所需风险模型数据导出
4. 再实现 RedisAwareProvider，使其兼容现网缓存逻辑

## 9. 重构约束

这部分在未来很容易被忽略，但必须持续强调：

- 不要求内部实现与 Python 同构
- 必须保证输出结果稳定
- 必须保证 reference data 语义一致
- 必须能被固定样例和 golden case 持续回归

所以 provider 设计的核心不是“像不像旧代码”，而是：

- 输入语义是否稳定
- 数据边界是否可测
- 后端来源是否可替换
