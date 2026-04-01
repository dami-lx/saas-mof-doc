# Brinson-Core Exporter 与旧 Pandas 兼容方案

## 1. 为什么需要 exporter

Brinson 的真实 reference data 目前散落在两类旧依赖里：

- Datayes MySQL
- Redis Cluster 中的历史 pickle / xz-pickle payload

Rust 重构如果直接依赖这些在线数据源，会立刻碰到几个问题：

- Redis 是 cluster，需要处理 `MOVED`
- Redis payload 是旧 pandas 版本写入的 pickle
- `brain` 整个 Python 运行时还有日志、配置、第三方包等启动副作用

因此当前推荐路线仍然是：

1. 先做只读 exporter
2. 导出稳定的 snapshot JSON
3. Rust 只消费 snapshot，不直接耦合旧系统

## 2. 当前 exporter 位置

已新增脚本：

- `tools/export_brinson_snapshot.py`

职责：

- 读取捕获的 `brain` Brinson 请求
- 复刻 Rust 当前 request normalization 的 security universe 顺序
- 直连 Datayes MySQL / Redis Cluster
- 导出 `FileReferenceDataSnapshot` 可直接消费的 JSON

## 3. Python 3.11 下旧 pickle 的兼容补丁

真实验证后，下面两个兼容补丁已经足够把本次 Brinson 关键数据读出来。

### 3.1 兼容旧 pandas 模块路径

旧 pickle 会引用：

- `pandas.core.indexes.numeric`

在新 pandas 中这个模块已不存在，所以 exporter 在启动时显式注入：

- `Int64Index`
- `UInt64Index`
- `Float64Index`

对应的 shim module。

### 3.2 兼容旧 Block placement

某些 DataFrame 在反序列化时会报：

- `Argument 'placement' has incorrect type (expected pandas._libs.internals.BlockPlacement, got slice)`
- 或 `got numpy.ndarray`

处理方式是 monkey patch：

- `pandas._libs.internals._unpickle_block`

如果 `placement` 不是 `BlockPlacement`，则先包装成 `BlockPlacement` 再交还给原始逻辑。

## 4. 已验证可解码的数据集

在这个兼容层下，已经成功读取：

- `stock:ret:d:{td}`
- `ind:SW1:21:{td}`
- `bm:{benchmark_id}:{td}`
- `fret_sw21:d:{td}`
- `rm_sw21:exp:{td}`
- `rm_sw21:cov:short:{td}`
- `rm_sw21:srisk:short:{td}`

这意味着：

- 行业 Brinson 所需的股票收益、行业、基准成分已经具备真实导出能力
- 风格归因后续需要的因子收益、暴露、协方差、特异风险也已经具备真实导出能力

## 5. 当前 snapshot 可承载的数据

目前 exporter 输出：

- `tradingDays`
- `securityReturns`
- `benchmarkWeights`
- `benchmarkReturns`
- `securityIndustries`
- `factorReturns`
- `factorExposures`
- `riskCovariance`
- `specificRisks`
- `styleFields`
- `industryFields`
- `frequency`

这与 Rust 当前的 `FileReferenceDataSnapshot` 对齐。

## 6. 一个必须记录的结构性限制

虽然 exporter 能从 Redis 取到 benchmark 全量成分，但 Rust 当前 reference model 仍有一个关键限制：

- `benchmarkWeights` 里的 `securityIndex` 只能引用请求持仓 universe 里的证券

而真实 benchmark 成分里，大量证券并不在组合持仓中。

这会带来一个直接后果：

- 当前 Rust 行业 stage 最多只能看到“组合持仓与基准成分的交集”
- 无法完整表达 benchmark 的全成分行业分布
- 因此**不可能**和 `brain` 的最终结果严格一致

这不是 exporter 的问题，而是 Rust 数据模型的边界问题。

## 7. 对后续 Rust 重构的建议

如果目标是“结果和 brain 严格一致”，下一阶段必须把 reference model 从“持仓索引绑定”调整为“外部证券主键绑定”。

更具体地说：

- portfolio 持仓仍然可以保留本地 `security_index`
- 但 reference data 应优先用外部 `security_id` / canonical security key 表达
- benchmark 成分、股票收益、行业、暴露等都不应被限制在持仓 universe 内

只有这样，Rust 才能真正重建 benchmark 的全量行业和风格暴露。

## 8. 当前结论

到这一步可以认为：

- “真实数据抽取”这条路径已经打通
- “Rust 与线上结果完全一致”当前仍卡在数据模型，而不是卡在环境连通或旧 pickle

因此后面的工作应分成两层：

1. 继续利用 exporter 产出 snapshot，沉淀测试样例
2. 重构 Rust 的 security / benchmark 数据模型，解决全成分 benchmark 表达问题
