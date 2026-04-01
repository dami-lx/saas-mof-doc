# Brinson-Core 重构问题日志

## 1. 记录目的

这个文档专门记录重构过程中真实遇到的问题、定位方式、修复动作和结论。

和“架构设计文档”不同，这里更强调：

- 哪里踩坑了
- 为什么会踩坑
- 当时是怎么验证和修掉的
- 以后再遇到类似问题应该怎么快速判断

## 2. 问题：旧 `brain` 模块无法直接 import

### 现象

在 Python 3.11 环境里直接 import `lib.data_loader.cal` / `lib.data_loader.risk_model` 时，最开始连续遇到：

- `../etc/brain.conf` 找不到
- `handlers.ConcurrentRotatingFileHandler` 不兼容
- 日志文件路径不存在
- `DBUtils` 缺失
- Redis cluster 初始化在 import 阶段直接连接

### 根因

`brain` 代码不是“纯模块式”设计，很多 import 会连带触发：

- 配置加载
- logging 初始化
- 数据库连接池初始化
- Redis 连接初始化

这意味着它并不适合作为“轻量数据访问库”直接复用。

### 修复/绕开方式

没有继续强行把整个 `brain` 运行时抬起来，而是改成两层策略：

1. 只把源码当作“行为说明书”
2. 真实 exporter 直接绕过 `brain` 初始化副作用，自行连接 MySQL / Redis

### 经验

以后看 `brain` 其他功能时，优先判断：

- 是不是“代码逻辑值得复用”
- 还是“只能借它的 key 命名、SQL、口径定义”

不要默认“能 import 就能复用”。

## 2.1 问题：`style_stability` 的 risk/weight 不能沿用主 stage 的 period 口径

### 现象

在 case1 / case2 里，`style_factor_attr`、`portfolio_style_factor_attr` 已经基本对齐后，
`style_stability_df` / `portfolio_style_stability_df` 仍然稳定残留：

- `active_risk` 最大偏差约 `2.3868e-4`
- `active_weight` 最大偏差约 `3.8617e-3`

而且偏差高度集中在：

- `2025-01`
- 最后一个月的 weight / risk 稳定性

### 最初误判

一开始容易以为：

- 是 risk 公式错了
- 或者是月均值聚合错了

但继续往下比后发现：

- `2024-12` 月份是对的
- 只有 `2025-01` 偏
- 这更像是“样本日期集合不一致”，不是公式不一致

### 根因

Python `brain` 的 advanced 路径里：

- `calc_style_stability(data_param)` 直接遍历完整 `trading_day_list`
- 对 risk / weight 稳定性，会把最后一个持仓日也算进去

Rust 当时是直接复用 `request.positions().windows(2)`：

- 只覆盖到倒数第二个权重日
- 最后一个持仓日没有被纳入 stability 的 risk / weight 统计

### 修复动作

在 `brinson-core/src/engine/stages.rs` 里把 style stage 拆成两条口径：

1. 累计归因口径
   - 继续沿用 `windows(2)` 的 period 数据
2. stability 专属口径
   - 新增 `compute_style_risk_weight_snapshot(...)`
   - 直接按完整持仓日计算 risk / weight snapshot

### 二次踩坑

第一次修时，把“完整持仓日”的 risk / weight 序列直接拿去做累计均值，导致：

- `style_stability_df` 收口了
- 但 `style_factor_attr.active_weight` 被带偏了

这次踩坑非常关键，说明：

- Python 的 style 主链累计口径
- 和 advanced 的 stability 专属口径

并不是一条数据流，不能偷懒复用。

最终修法是：

- period 累计均值继续使用 `windows(2)` 结果
- stability 再单独使用 full trading-day snapshot

### 结果

修完后，case1 / case2 的以下表重新收口到浮点误差级别：

- `style_factor_attr`
- `portfolio_style_factor_attr`
- `style_stability_df`
- `portfolio_style_stability_df`

### 经验

以后只要看到：

- “主表已经对齐，但 stability 只在最后一个月偏”

优先检查：

- 这条 stability 是不是独立 helper 路径
- 样本日期集合是不是包含 terminal holding date
- 是否错误复用了主 stage 的 period 序列

## 2.2 问题：case2 的 3 个 deviation 很可能走了和 summary 不同的 period 样本集合

### 现象

在 case2 里，以下指标一直残留小幅偏差：

- `m_sector_allocation_deviation`
- `m_security_selection_deviation`
- `m_interaction_deviation`

但与此同时：

- `m_sector_allocation`
- `m_security_selection`
- `m_interaction`
- `manage_return`
- `timing_return`

都已经和 brain 对齐到浮点误差级别。

### 为什么这件事很特别

如果是 Brinson 主公式错了，通常会一起影响：

- mean / accumulated summary
- deviation

但现在只有 deviation 不对，这说明更像是：

- deviation 用的 period 样本集合
- 和 summary 用的 period 样本集合

并不完全相同。

### 已做的实验 1：只给 snapshot 补 `preBeginDate`

动作：

- 在 exporter 中让 `preBeginDate` 进入 `tradingDays`
- 在 Rust snapshot provider 中允许保留 `pre_begin_date`
- 基于现有 case2 snapshot，手工合成一版带 `20231231` reference data 的 synthetic snapshot

结果：

- 对最终 Rust 输出几乎没有影响

根因：

- 只补 snapshot 不够
- Rust / request 主链仍然只会对 `position` 中显式存在的持仓日做 `windows(2)`
- request 本身没有 `20231231` 这期持仓快照

### 已做的实验 2：同时给 request 也补一版 synthetic pre-begin 持仓

动作：

- 把 case2 的第一期持仓复制一份，日期改成 `20231231`
- 再配合 synthetic pre-begin snapshot 回放

结果：

- `m_sector_allocation_deviation` 几乎直接收口
  - diff 从 `0.0013056703`
  - 降到 `0.0000015184`
- 但同时：
  - `m_sector_allocation`
  - `m_security_selection`
  - `m_interaction`
  - `manage_return`
  - `timing_return`

  都被带偏了

### 结论

这个实验非常关键，它说明：

- “多一段首期 period” 的确能解释 deviation 的变化方向
- 但 brain 的 summary 平均值并没有吃掉这段 synthetic period

因此更可信的真实结论是：

- case2 的 deviation 统计路径
- 和 summary / accumulated 路径

很可能真的使用了不同的 observation 集合。

### 当前最合理的下一步

优先不要再改 Rust 主公式，而是继续验证：

- Python `pack_accumulate_results()` 里的 `mng_ability_per`
- 它真实来自哪些 period rows
- 是否存在一条“只进 std、不进 accumulated summary”的首期样本

### 经验

以后只要出现：

- mean 对了
- std 不对
- 并且加一段 synthetic 首期样本后 std 收口、mean 反而坏掉

优先怀疑：

- 同一业务名词下，其实有两条 period 样本路径
- 不能默认 `std(periods)` 和 `mean(periods)` 一定来自同一组 period

## 3. 问题：Redis 历史 payload 无法在新 pandas 里直接解码

### 现象

真实 Redis payload 起初出现两类典型报错：

- `No module named 'pandas.core.indexes.numeric'`
- `Argument 'placement' has incorrect type (expected pandas._libs.internals.BlockPlacement, got slice / ndarray)`

### 根因

这些 payload 是老 pandas 版本写出来的 pickle，新环境里的 pandas 内部模块路径和 BlockManager 结构都变了。

### 修复方式

在 exporter 启动时注入了两个兼容层：

1. shim `pandas.core.indexes.numeric`
2. patch `pandas._libs.internals._unpickle_block`

### 结果

成功解码：

- `stock:ret:d:{td}`
- `ind:SW1:21:{td}`
- `bm:{benchmark_id}:{td}`
- `fret_sw21:d:{td}`
- `rm_sw21:exp:{td}`
- `rm_sw21:cov:short:{td}`
- `rm_sw21:srisk:short:{td}`

### 经验

只要 pickle 兼容问题还停留在 pandas 内部对象层，而不是自定义类层，这种 shim/patch 路线通常值得优先尝试。

## 4. 问题：最初的 snapshot 只能表达 benchmark 与持仓的交集

### 现象

第一版 case1 snapshot 里：

- `benchmarkWeights` 只有 24 条
- overlap securities 只有 2 只

Rust 跑出来的行业数明显少于 brain，`m_sector_allocation` 也偏离较大。

### 根因

最初 exporter 和 Rust provider 都把 reference data 绑定在“请求持仓 universe 的 `security_index`”上。

这样一来：

- benchmark 里不在组合持仓中的证券
- 根本无法被 snapshot 表达

### 修复方式

做了两层调整：

1. `SecurityReturnPoint` / `SecurityIndustryPoint` / `BenchmarkConstituentWeight`
   增加 `security_id`
2. `security_index` 从必填改成可选

同时 exporter 改成：

- `target_security_ids = 持仓权益证券 ∪ benchmark 全成分证券`

### 结果

case1 重新导出后：

- `securityReturns` 从 72 增加到 3648
- `securityIndustries` 从 192 增加到 3768
- `benchmarkWeights` 从 24 增加到 3600

Rust case1 结果也明显靠近 brain：

- `m_sector_allocation` 从 `0.1168` 提升到 `0.1287`
- brain 为 `0.1337`
- 行业覆盖数从极少数提升到与 brain 一样的 `28`

### 经验

“能跑”不等于“数据模型正确”。

如果 benchmark 本身是全成分口径，就不能让 reference model 只围绕 portfolio universe 设计。

## 5. 问题：Exporter 一开始虽然输出了 benchmark-only 权重，但没有输出对应收益和行业

### 现象

在第一轮修复后，`benchmarkWeights` 已经可以包含 benchmark-only 证券，但 `securityReturns` / `securityIndustries` 仍然只覆盖持仓 universe。

### 根因

Exporter 里初始实现仍用了：

- `security_id_to_index.keys()`

作为收益和行业导出的过滤范围。

### 修复方式

把导出目标集合改成：

- `持仓权益证券 ∪ benchmark 全成分证券`

然后收益、行业都按这个全集导出。

### 经验

只修“主表”不够。

只要 reference data 是多表联动的，主键集合必须在所有相关数据集上保持一致。

## 6. 问题：离线计算与 snapshot 导出并行时可能读到旧文件

### 现象

一次并行执行中，`compute_snapshot` 可能在 exporter 尚未完成写盘前就读到旧版 snapshot。

### 根因

这是任务编排时序问题，不是计算逻辑问题。

### 修复方式

流程上改成：

1. 等 exporter 结束
2. 确认 snapshot 统计量已变化
3. 再执行 `compute_snapshot`

### 经验

后续如果要自动化回归，最好把：

- export
- verify snapshot metadata
- compute
- compare

串成一个明确的 pipeline，而不是手动并行触发。

## 7. 问题：当前 `timing_return` 仍为 0

### 现象

case1 当前 Rust 输出：

- `timing_return = 0.0`

而 brain 输出是：

- `timing_return = 0.5376291565452067`

### 根因

这不是数值误差，而是当前 stage 还没有实现 timing 部分。

目前 Rust 里仍然是：

- `annual_timing_return: 0.0`
- `deannual_timing_return: 0.0`

### 已确认的上游线索

在 `mars/attribution/holding/equity_attribution.py` 中已经确认 timing 公式入口，例如：

- `timing_return = (abs_sum_p_weight - abs_sum_b_weight) * R_benchmark`

以及累计口径相关逻辑：

- `accumulate_timing_return(...)`

### 经验

这个问题不应再从“猜公式”开始，而应直接对照：

- `mars` 单期 timing
- `brain` 累计/年化装配

做逐层迁移。

## 12. 问题：style/risk 的 benchmark-only 数据一度仍然丢失

### 现象

虽然 exporter 已经把查询 universe 扩成了：

- 持仓权益证券
- benchmark 全成分证券

但 Rust style stage 早期对账时仍然出现：

- `sf_country_return`
- `sf_factor_return`
- `sf_country_risk`
- `sf_factor_risk`
- `style_preference`
- `style_goodat`

整体偏差很大。

### 根因

问题不在 Rust 公式主干，而在 exporter 写 snapshot 时还残留了旧过滤：

- `security_index is None -> continue`

这会把 benchmark-only 成分的：

- `factorExposures`
- `specificRisks`

再次裁掉。

### 修复方式

Exporter 改成：

1. 风格暴露和 specific risk 都按 `target_security_ids` 导出
2. snapshot 记录显式带 `securityId`
3. 不再因为 `security_index is None` 丢弃 benchmark-only 记录

Rust provider / schema 也同步允许：

- `security_index: Option<usize>`
- `security_id: Option<i64>`

### 结果

补齐 snapshot 后，case1 / case2 的：

- `sf_country_return`
- `sf_industry_return`
- `sf_factor_return`
- `sf_specific_return`
- `sf_country_risk`
- `sf_industry_risk`
- `sf_factor_risk`
- `sf_specific_risk`
- `style_preference`
- `style_goodat`

都已经和 brain 对齐到浮点误差级别。

### 经验

如果某条链路里同时存在：

- overlap 证券
- benchmark-only 证券

那就不要只盯住“权重主表是否齐全”，还要同步检查：

- 收益
- 行业
- factor exposure
- factor covariance
- specific risk

是不是也覆盖了同一套 security universe。

## 13. 问题：累计均值类字段的分母不能偷懒用 `periods.len()`

### 现象

case2 一度出现一个非常迷惑的信号：

- style risk
- style exposure
- 行业累计 `wp/wb/wa`
- 行业累计 `deannual_rp/rb/ra`

会出现统一比例偏差，典型上接近：

- `254 / 253`

### 根因

`brain` / `mars` 在这类“累计均值”字段上，分母并不是简单的 period 数，而是：

- `annualization_observation_count()`

对于 case2：

- observation count = 254
- 但 period count = 253

如果误用了 `periods.len()`，长样本下就会出现统一比例放大。

### 修复方式

Rust 里统一把以下逻辑的分母改成：

- `request.annualization_observation_count().max(1) as f64`

覆盖了：

- style risk 累计
- style exposure 累计
- specific risk 累计均值
- 行业累计权重
- 行业累计 return 均值

### 结果

修完后：

- case2 的 style summary 已全部回到浮点误差级别
- `accum_brinson_industry_attr`
  按 `sector` 作为 key 对齐后，也已经与 brain 一致到浮点误差级别

### 经验

以后凡是看到“所有行业/因子都按同一个比例整体放大或缩小”，优先怀疑：

- observation count
- period count
- 年化/去年化缩放次数

不要先怀疑单个公式。

## 14. 问题：数组按下标 compare 容易把已经对齐的结果误判成不一致

### 现象

在 case2 的完整 compare 里，某一阶段看起来：

- `accum_brinson_industry_attr` 有大量偏差

但按行业 key 对齐后，实际已经完全一致。

### 根因

这类表格输出在不同实现里，排序可能受：

- 原始字段顺序
- pack 装配顺序
- JSON 序列化前的 map 展开顺序

影响。

如果直接按数组下标 compare，很容易把“顺序差异”误看成“数值差异”。

### 修复方式

这轮回归里把诊断方式改成两步：

1. 先用完整 compare 找大类不一致位置
2. 对表格类字段再按业务 key 对齐复核

例如：

- `accum_brinson_industry_attr` 按 `sector`
- `style_preference` / `style_goodat` 按 `style_name`

### 经验

后续如果做自动回归，表格类字段最好直接做：

- keyed compare
- 或 compare 前先标准化排序

否则会持续制造噪音。

## 15. 问题：修改 observation-count 口径后，最小单测预期也要一起更新

### 现象

这轮把累计均值口径统一后，两个最小单测立刻失败：

- `industry_stage` 里的 benchmark-only 行业权重样例
- `style_stage` 里的最小因子模型样例

### 根因

测试原本默认：

- 行业累计权重除以 period 数
- style exposure / risk 也除以 period 数

但现在实现已经改成与 `brain` 一致的 observation-count 分母。

### 修复方式

更新单测预期：

- benchmark-only 行业权重从 `0.7` 改到 `0.35`
- style 最小样例里的
  - `active_beta_risk` 从 `0.03` 改到 `0.015`
  - `active_beta_exposure` 从 `0.1` 改到 `0.05`

### 经验

当单测是“构造性最小样例”时，它常常隐含了某个历史口径假设。

一旦底层口径修正，不要机械地把失败看成代码回退，先判断：

- 是实现错了
- 还是测试的业务口径已经过期

## 16. 问题：行业 risk 的累计分母和 return 不同，但最终仍然要按 observation-count 对齐 brain

### 现象

在完成行业 risk 公式迁移后：

- case1 的 `manage_risk / timing_risk` 已经直接对齐
- case2 的 `manage_risk / timing_risk` 仍然统一偏大

偏差比例非常稳定，接近：

- `254 / 253`

### 排查过程

先对照 `mars.attribution.holding.helper_func` 会看到：

- `accumulate_timing_risk = mean(period_timing_risk)`
- `accumulate_management_risk = sum(period_df) / len(periods)`

表面上看，应该直接除以 period 数。

但实际用 QA case2 对账时发现：

- 直接除以 `periods.len() = 253`
  会比 brain 偏大一个 `254 / 253`

### 当前结论

在这个真实调用链里，最终想和 brain 结果一致时，行业 risk 累计仍应按：

- `annualization_observation_count()`

做均值分母。

### 经验

这里再次说明一件很重要的事：

- `mars` 源码里的局部 helper
- `brain` 服务最终对外输出

不一定在“分母口径”上完全等价。

如果真实 QA 对账已经给出稳定比例残差，应该优先信：

- 真实输出基线

再回过头解释为什么局部 helper 看起来不完全一致。

## 17. 问题：`portfolio_return` 的 linking 不能沿用 active-return 的 benchmark

### 现象

在行业 risk 已收口后，`portfolio_style_factor_attr` 里仍然有明显偏差，但主要集中在：

- `attribution_type = active_return`
- `portfolio_*` 表，不影响 active summary

### 根因

继续对照 `mars` 的 `EquityStyleFactorAttribution.get_accumulate_attribution_result()` 后发现：

对 portfolio 分支，Python 会先做：

- `annualized_total_return_df_bk.loc['benchmark'] = 0`

然后再调用 portfolio 的 accumulate。

也就是说：

- active return 的 linking 用 `(portfolio, benchmark)`
- portfolio return 的 linking 用 `(portfolio, 0)`

### 修复方式

Rust 已改成：

1. active return 继续使用真实 portfolio/benchmark total return
2. portfolio return / portfolio specific return 单独构造 benchmark=0 的 total-return 序列再做 linking

### 结果

修完后：

- case1 / case2 的 `portfolio_style_factor_attr`
  按 key 对齐后已经收口到浮点误差级别

### 经验

看起来都叫“style factor accumulated return”，但：

- active
- portfolio

在 Python 里其实走的是不同 linking 背景。

后续不要把 portfolio/active 两条 accumulate 路径混成一个。

## 18. 问题：style stability 的 risk/weight 不是直接复用主 style stage period 结果

### 现象

在 style summary、portfolio factor attr 都已对齐后，仍然残留：

- `portfolio_style_stability_df` 的少量 `active_risk`
- `portfolio_style_stability_df` 的少量 `active_weight`

局部月份值偏差。

### 根因

继续排查 `equity_attribution_advanced.py` 后发现：

advanced 输出里的 stability，不完全直接复用 `sf_res` 里的 period 数据。

它会先单独调用：

- `calc_style_stability(data_param)`

而这个 helper 的 universe 交集是：

- portfolio weight
- benchmark weight
- exposure
- specific risk

并不会再交 `security_return`。

这和主 style attribution 的 period 计算路径不同。

### 当前状态

目前 Rust 主链路已经完成：

- active/portfolio style summary
- portfolio_style_factor_attr

但 `style_stability_df / portfolio_style_stability_df`
里与 risk/weight 相关的那条“特殊 stability 分支”还没有单独移植。

### 经验

不要默认：

- summary 用的中间量
- stability table 用的中间量

一定来自同一条 period pipeline。

真实系统里，稳定性报表往往会为了“展示稳定性”单独走一条更宽松或更专门的采样路径。

## 8. 问题：`industry_goodat` 口径仍有显著偏差

### 现象

case1 当前 Rust 的 `industry_goodat` 第一名仍出现非常大的值，例如：

- `汽车 = 71.0905`

而 brain 对应行业量级约为：

- `汽车 = 1.9100`

### 当前判断

这说明：

- 行业覆盖和 benchmark 全成分问题已经基本解决
- 但“good at / preference” 的装配口径还没有和 Python 对齐

当前 Rust 用的是：

- `行业主动收益 / 行业主动权重绝对值`

## 9. 问题：linking 系数在 timing / management 累积里一开始用了倒数

### 现象

在引入真实 `mars` 口径后，Rust 的：

- `timing_return`
- `manage_return`
- `industry_goodat`

虽然方向逐渐接近，但数值仍被系统性压小，尤其 case1 的：

- `timing_return` 只有 `0.02x`
- brain 是 `0.5376291565452067`

### 根因

`mars.attribution.holding.attribution` 里的累计公式，用的是：

- `C_T = (R_p - R_b) / (ln(1 + R_p) - ln(1 + R_b))`

而 Rust 第一版误复用了另一处 helper，实际算成了：

- `(ln(1 + R_p) - ln(1 + R_b)) / (R_p - R_b)`

也就是 reciprocal。

### 修复方式

把 linking 拆成两类 helper：

1. `accumulation_linking_coefficient`
   用于 `accumulate_timing_return` / `accumulate_management_return`
2. `logarithmic_beta_coefficient`
   用于 sector return 的 `beta = k_t / k`

### 经验

同样都叫 “linking coefficient”，但在老 Python 代码里其实有两套不同口径：

- 一套给累计器
- 一套给 period beta

后续迁移别再复用一个统一 helper。

## 10. 问题：行业权重/行业收益一开始按“绝对权重直减”实现，和 `mars` 不一致

### 现象

在修完 benchmark-only universe 后，case1 的：

- `industry_preference`
- `m_interaction`
- `m_security_selection`

仍然明显偏。

最典型现象是：

- top3 preference 和 brain 完全不同
- 某些行业的 `wa / wb` 量级明显偏大

### 根因

`mars` 的单期行业归因不是直接用：

- `组合行业绝对权重 - 基准行业绝对权重`

而是：

1. 先把行业权重转成各自组合内部的 share
2. 用 share 做 allocation / selection / interaction
3. 最后统一乘回 `abs_sum_p_weight`

同时：

- 行业权重输出里的 `benchmark`
  也是 `组合总绝对权重 * benchmark_sector_share`
- 行业收益输出里的 `benchmark`
  也是 `组合总绝对权重 * benchmark_sector_share * R_benchmark_sector`

### 修复方式

Rust 新增了 sector 级输出口径：

- `portfolio_share`
- `benchmark_share`
- `effective_*_share`
- `portfolio_weight / benchmark_weight`
- `portfolio_return / benchmark_return`
- `allocation / selection / interaction`

全部按 `mars` 的 share + `abs_sum_p_weight` 缩放方式实现。

### 结果

修完以后，case1 的：

- `industry_preference`
- `industry_top3_preference`

已经和 brain 对齐。

### 经验

Brinson 里“看起来只是多乘少乘一个权重”的差异，最终会沿着：

- 行业权重
- 行业收益
- goodat / preference
- summary 指标

整条链一起放大。

## 11. 问题：case1 旧 snapshot 实际少了 `preBeginDate`

### 现象

虽然 request 明确带了：

- `beginDate = 20250101`
- `preBeginDate = 20241231`

但最初的 `case1-snapshot.json` 只有 12 个日期，起始是：

- `20250102`

缺了：

- `20241231`

### 根因

之前落盘的 snapshot 是旧版本导出物，不是当前 exporter 的完整产物。

这会导致：

- 第一个 period 被跳过
- `timing_return`
- `manage_return`
- 行业累计结果

整体都被低估。

### 修复方式

重新用真实 MySQL / Redis 导出 case1，得到：

- `brain-brinson-test/output/case1-snapshot-latest.json`

新 snapshot 已包含：

- `20241231 ~ 20250117`
- 共 13 个日期

### 结果

在“完整 snapshot + 新 sector/share 口径 + 正确 linking”三者同时到位后，case1 的 Brinson summary 已经和 brain 对齐到浮点误差级别。

### 经验

如果发现：

- summary 看起来只差一点
- 但 timing 总差一大截

优先确认 snapshot 是否真的包含：

- `preBeginDate`
- 第一个权重日
- 对应 benchmark / industry / return

## 12. 问题：`rp / rb / ra` 字段不是“累计年化行业收益”，而是“最后一期单期行业收益”

### 现象

当 case1 summary 已经完全对齐后，`accum_brinson_industry_attr` 里仍有最后一类差异：

- `deannual_rp / deannual_rb / deannual_ra` 已对齐
- 但 `rp / rb / ra` 明显不对

### 根因

最初直觉上把：

- `rp / rb / ra`

理解成了“累计行业收益的 annualized 版本”。

但对照老 Python `pack_accum_annualized_unannualized_industry_attr` 后确认：

- `deannual_rp / deannual_rb / deannual_ra`
  才是累计 unannualized 行业收益
- `rp / rb / ra`
  实际取的是 `sector_return_df.loc[max_date]`
  也就是最后一期 period 的行业收益

### 修复方式

Rust 改成：

- `sector_returns_deannual` = 累计 unannualized sector return
- `sector_returns_annual` = 最后一期 period sector return

虽然字段名历史上叫 `annual`，但为了兼容老输出，这里必须沿用旧装配语义。

### 经验

在迁移老系统时，字段名不一定代表真实业务含义。

对齐优先级应该是：

1. 看旧 pack 真正从哪里取数
2. 再决定 Rust 内部字段怎么命名/解释

## 13. 问题：大样本 exporter 会刷大量 `FutureWarning`

### 现象

在 case2 这种长时间区间导出时，终端会刷出大量来自 pandas 的：

- `FutureWarning: Downcasting object dtype arrays on .fillna ...`

### 影响

- 干扰人工判断任务是否卡住
- 污染日志
- 在长样本下显著降低调试体验

### 修复方式

在 `tools/export_brinson_snapshot.py` 入口增加：

- `warnings.filterwarnings(..., category=FutureWarning, module="__main__")`

优先压住这些“已知兼容性噪音”。

### 经验

当 exporter 已经是“已知只读 + 已知兼容 shim”的工具时，
这类不会影响结果正确性的 warning 应该被主动收口，不然很容易把真正的卡点淹没掉。

而 Python 侧可能还有更细的过滤、累计或归一化口径。

### 经验

当一个指标的“方向对了、量级不对”时，优先检查：

1. 分母定义
2. 绝对值/符号处理
3. 年化与去年化口径
4. 排序前是否做了过滤

## 9. 当前阶段性结论

到目前为止，已经比较明确地把问题分层了：

- 数据连通：已解决
- 旧 pickle 解码：已解决
- benchmark 全成分表达：已解决第一阶段
- 行业 stage 可运行：已解决
- timing return：未实现
- goodat / preference 装配口径：未完全对齐

这意味着下一阶段不需要再花时间在环境问题上，而应该集中在：

1. 对齐 `mars` timing return
2. 对齐 `brain` accumulate_results 的行业汇总口径

## 14. 问题：annualization 分母不能简单使用 `periods.len()`

### 现象

case2 在 Brinson deannual 指标已经与 brain 完全一致后，annual 指标仍统一偏了一小截：

- `manage_return_deannual` 精确一致
- `timing_return_deannual` 精确一致
- 但 `manage_return / timing_return` 都略大

### 根因

brain 的 annualization 分母不是简单的：

- `periods.len()`

而是一个“观察点数量”：

- 如果 request 第一条 position 就是显式 `preBeginDate`
  分母要减 1
- 如果 `preBeginDate` 没有真实落进 position 序列
  分母就直接等于 `positions.len()`

这能同时解释：

- case1：分母 = `13 - 1 = 12`
- case2：分母 = `254`

### 修复方式

在 `CompiledBrinsonRequest` 增加：

- `pre_begin_date`
- `annualization_observation_count()`

由 request 编译层统一给出 annualization denominator，stage 只消费这个结果，不再在算法内部临时猜分母。

### 经验

如果出现：

- deannual 全对
- annual 统一按一个固定比例偏大/偏小

优先检查 annualization denominator，而不是重新怀疑整条归因公式。

## 15. 问题：Style Stage 从空实现变成真实计算后，结果仍与 brain 明显偏差

### 现象

在 Rust 新增 `RiskModelStyleAttributionStage` 后：

- `style_factor_attr`
- `portfolio_style_factor_attr`
- `style_stability_df`
- `portfolio_style_stability_df`
- `accumulate_results` 中的 style return / risk 字段

已经不再是全 0，而是会产出真实值。

但是与 brain 对账时，仍出现明显偏差，尤其集中在：

- `sf_country_return`
- `sf_factor_return`
- `sf_country_risk`
- `sf_factor_risk`
- `style_preference`
- `style_goodat`

同时：

- `manage_risk`
- `timing_risk`

仍是 0，因为行业 risk stage 还没实现。

### 已确认根因

不是 Rust style 公式完全写错，而是当前 snapshot 对 style/risk 来说仍不完整。

关键事实：

1. `benchmarkWeights` 已经包含 benchmark-only 成分
2. `securityReturns / securityIndustries` 也已经补到了 benchmark-only 的 `security_id`
3. 但是 `factorExposures / specificRisks` 仍然只支持 `security_index`
4. `security_index` 只覆盖 request 持仓 universe
5. 因此 benchmark-only 成分没有办法进入 Rust 当前的 style/risk 风险模型矩阵

这意味着：

- 行业 Brinson 可以靠 `security_id` 补齐 benchmark-only
- 但 style/risk 仍然只能在“持仓 universe ∩ 有 exposure/risk 的证券”上计算

### 量化证据

对 snapshot 做统计后发现：

- case1：平均只有 `1.07%` 的 benchmark 权重带有 `security_index`
- case2：平均只有 `22.27%` 的 benchmark 权重带有 `security_index`

换句话说：

- case1 里 style/risk 几乎是在“只看 benchmark 很小一块重叠成分”上做
- case2 虽然比 case1 好，但仍缺失约 `77%` 的 benchmark 权重暴露

### 当前结论

现在的 `RiskModelStyleAttributionStage` 有两个价值：

1. 已经把 `mars.EquityStyleFactorAttribution` 的核心 period / linking / accumulate 骨架迁到了 Rust
2. 证明 style/risk 继续对齐的真正卡点已经从“公式未实现”收敛到“reference data 不完整”

### 后续修复方向

要让 Rust style/risk 与 brain 真正对齐，至少需要补齐下面一项：

1. exporter 为 benchmark-only 成分导出 `factorExposures` 和 `specificRisks`
2. 或者扩展 snapshot schema，让 `factorExposures / specificRisks` 也支持 `security_id`

如果这一步不完成，那么 Rust 侧最多只能做到：

- 持仓 overlap 范围内的 style/risk 真实计算
- 但无法与 brain 的全量 benchmark 风险模型口径完全一致

### 经验

当一个模块从“空实现”切到“真实实现”后，如果偏差量级仍然很大，不要立刻只盯公式。

应该优先问三个问题：

1. 这条链路依赖的数据是否和前一个模块一样完整
2. 标识方式是否一致
3. benchmark-only / universe 外成分是否真的能进入矩阵计算

## 16. 问题：Exporter 虽然开始支持 `target_security_ids`，但仍然把 benchmark-only 风险模型数据丢掉

### 现象

在把 exporter 改成：

- `factor_exposures` 使用 `target_security_ids`
- `specific_risks` 使用 `target_security_ids`

之后，case1 的导出统计一开始仍然是：

- `factor_exposures = 9984`
- `specific_risks = 208`

这两个数字正好只覆盖：

- `16` 个 overlap equity

而不是：

- `314` 个目标 security id

### 根因

真正的遗漏点不在 `reindex(target_security_ids)`，而在后面的旧过滤逻辑：

```python
security_index = security_id_to_index.get(int(security_id))
if security_index is None:
    continue
```

这段代码会把所有：

- benchmark-only
- 没有 request `security_index`

但本来已经成功从风险模型里拉到的证券，再次全部丢掉。

`specific_risks` 里也有同样问题：

- `if security_index is None or pd.isna(value): continue`

### 修复方式

改成：

1. 始终输出 `securityId`
2. `securityIndex` 允许为 `None`
3. 不再因为 `securityIndex is None` 而 `continue`

修复后，case1 的统计立即变成：

- `factor_exposures = 195936`
- `specific_risks = 4082`

并且：

- `factorExposures` 中 `securityIndex is None` 的记录数 = `185952`
- `specificRisks` 中 `securityIndex is None` 的记录数 = `3874`
- 对应 `298` 个 benchmark-only security id

### 经验

这类 bug 很隐蔽，因为它会产生一种非常迷惑的假象：

- 代码看起来已经“支持 target universe”
- 日志里也能看到 `target_security_ids` 数量变大
- 但最终结果还是只覆盖 overlap universe

所以在修数据覆盖问题时，不能只看“入口过滤条件”；
必须沿着整条导出链检查：

1. 输入 universe 是否扩大
2. 中间 reindex 是否扩大
3. 最终 append 前是否又被老逻辑裁回去

## 17. 问题：`preBeginDate` 在 advanced holding attribution 当前源码里并没有真正进入计算主链

### 现象

case2 request 明确携带：

- `preBeginDate = 20231231`

但：

- request 的 `position` 首日仍是 `20240102`
- brain QA 返回结果的行业主链 summary 已经能和当前 Rust / 离线 Python 主链逐项对齐
- 只有 deviation 仍有口径差异

这说明之前把剩余问题继续归因到“首期样本缺失”的方向，并不稳。

### 根因

沿源码追踪后发现：

- `BaseHoldingAttribution._verify_parameter()` 会读取并记录 `preBeginDate`
- 但 `AdvancedEquityAttribution._load_input()` / `NormalizedAdvancedEquityAttribution._load_input()`
  传给 `EquityHoldingAttributionInputsLoader.load_complete_attr_inputs()` 的仍然只是：
  - `beginDate`
  - `endDate`
  - `position`
- `equity_advanced_holding_attr_loader.py` 里也没有把 `preBeginDate` 再拼回 `trading_day_list`

换句话说，当前本地源码的 advanced holding attribution 主链里：

- `preBeginDate` 并不会自动变成额外的 Brinson period

### 经验

以后看到 request 里带了 `preBeginDate`，不要先假设它一定参与了 holding attribution。

必须先确认：

1. 参数有没有从 service 层一路传到 loader
2. loader 有没有把它并回 `trading_day_list`
3. 最终 period 窗口是否真的多出一段

## 18. 问题：离线回放 `EquityBrinsonAttribution` 时，当前仓库内的累计分支结构不一致，不能直接拿来做诊断

### 现象

直接离线调用：

- `EquityBrinsonAttribution(...).get_attribution_result()`

在当前本地仓库里会撞到：

- `_accumulate_attribution()` 期望 `active_return['annualized_realized_period_timing_series']`
- 但前面的 `get_attribution_result()` 在当前类实现中并没有把 period list 整理成这套结构

会出现类似：

- `KeyError: 'annualized_realized_period_timing_series'`

### 处理方式

本轮没有继续修 Python 老代码本身，而是为了诊断稳定性，单独落了一个离线工具：

- `tools/replay_python_brinson_periods.py`

它的策略是：

1. 只跑 `get_attribution_result(is_accumulated=False)`
2. 直接读取每期 `unannualized_realized_management_df`
3. 再按 `q=250` 还原成 annualized period sums

这样可以稳定拿到：

- `sector_allocation`
- `equity_selection`
- `interaction`
- `manage_return`

的逐期样本，足够用于 deviation 诊断。

### 经验

在这个系统里，做“源码级口径追踪”时不要默认旧 Python 类本身是完全自洽的。

很多历史类：

- 可以支撑线上调用
- 但未必能脱离外层装配代码，直接作为离线诊断入口

所以诊断工具本身也要版本化保存，而不是只依赖一次性的 REPL 试验。

## 19. 问题：case2 剩余 deviation 已确认不是 Rust 行业公式问题，而是 service 侧 deviation 统计口径问题

### 现象

新增两个诊断入口后：

- `tools/replay_python_brinson_periods.py`
- `brinson-core/examples/diagnose_periods.rs`

对 case2 导出的结论是：

1. Rust 的 period sums 与离线 Python 的 period sums 逐期对齐到浮点误差级别
2. 两边 period count 都是 `253`
3. `m_sector_allocation` / `m_security_selection` / `m_interaction` / `manage_return`
   也与 brain QA 最终 summary 对齐到浮点误差级别

case2 剩下的三项偏差只表现在 deviation：

- `m_sector_allocation_deviation`
- `m_security_selection_deviation`
- `m_interaction_deviation`

并且它们：

- 与 Rust / 离线 Python 的 `sample std (ddof=1)` 明显不同
- 与 `population std (ddof=0)` 非常接近，只剩极小残差

### 新结论

这意味着当前剩余问题不再属于：

- Brinson 行业 period 公式
- 行业累计 linking
- style 主链迁移

而属于：

- brain QA 运行环境里 deviation 的最终统计口径

更直接地说：

- “当前 Rust 核心算法”已经和“离线 Python 主链”收口
- “QA 服务最终 deviation 数值”表现得像另一条更接近 `ddof=0` 的兼容口径

### 经验

后续如果再出现“summary 全对，只剩 deviation 不对”，优先检查：

1. 统计量是否是 `sample std` 还是 `population std`
2. 输出是不是来自另一条并行/兼容路径
3. 本地源码和 QA 部署版本是否已经分叉

## 20. 处理：在 Rust 中把 deviation 统计口径显式做成可配置项，而不是继续污染主公式

### 背景

既然已经确认：

1. 主链 period 值本身是对的
2. QA service 的 deviation 更像另一条兼容口径

那最稳妥的做法就不是继续改：

- 行业单期归因公式
- 累计 linking
- summary 主字段

而是把 deviation 统计本身抽象成显式配置。

### 本轮实现

在 `brinson-core` 中新增了：

- `CompatibilityProfile`
  - `CoreExact`
  - `BrainQaCompatible`
- `DeviationMode`
  - `Sample`
  - `Population`
- `PackAssemblyConfig`
- `ConfiguredPackAssemblerStage`
- `pack_accumulate_results_with_config(...)`
- `assemble_report_from_pack_inputs_with_config(...)`

默认行为仍然是：

- `CompatibilityProfile::CoreExact`
  - 对应 `DeviationMode::Sample`

因此不会影响当前已经对齐主链的默认输出。

### 验证结果

使用新增的 `population` 模式回放 case2 后：

- `m_sector_allocation_deviation`
  - QA: `0.6622129168915696`
  - Rust population mode: `0.6622059873151005`
  - delta: `-6.93e-06`
- `m_security_selection_deviation`
  - QA: `0.5039514660383145`
  - Rust population mode: `0.5039481728182121`
  - delta: `-3.29e-06`
- `m_interaction_deviation`
  - QA: `0.732410553446515`
  - Rust population mode: `0.7323687275381491`
  - delta: `-4.18e-05`

同时：

- `m_sector_allocation`
- `m_security_selection`
- `m_interaction`

仍保持与 QA 浮点误差级别一致。

### 经验

这一步非常值得保留，因为它为后续系统重构提供了一个很清晰的分层：

1. 核心算法层
   - 负责 period 值和累计主链正确
2. 兼容装配层
   - 负责不同部署环境/历史服务的统计口径差异

## 21. 处理：增加高层 `BrinsonRuntime` facade，避免外层重复组装 provider/profile/engine

### 背景

前面虽然已经把：

- `CompatibilityProfile`
- `PackAssemblyConfig`
- `ConfiguredPackAssemblerStage`

都放进了库里，但如果外层每次都自己写：

1. 创建 `FileSnapshotReferenceDataProvider`
2. 选择 `CompatibilityProfile`
3. 组装 `OptimizedBrinsonEngine`
4. 再套一层 `BrinsonService`

使用成本仍然偏高，也容易在后续统一代码包里出现重复胶水代码。

### 本轮实现

新增：

- `application/runtime.rs`
- `BrinsonRuntime`
- `BrinsonRuntimeConfig`

当前它负责直接封装：

- snapshot provider
- compatibility profile
- optimized engine
- service 入口

调用方现在可以直接：

- `BrinsonRuntime::from_snapshot_path(...)`
- `compute(...)`
- `compute_report(...)`

### 经验

这种 facade 很重要，因为它把“算法模块能跑”和“算法模块容易被后续系统整合”区分开了。

重构真正落地时，后者往往比前者更影响推进速度。

## 22. 处理：新增自动化 parity 报告脚本，固化 case1/case2 在不同 profile 下的偏差状态

### 本轮实现

新增脚本：

- `tools/generate_brinson_parity_report.py`

它会自动：

1. 运行 `compute_snapshot` example
2. 生成 case1/case2 在不同 compatibility profile 下的输出
3. 与 brain QA baseline 比较
4. 产出：
   - `brain-brinson-test/output/brinson-parity-report.json`
   - `brain-brinson-test/output/brinson-parity-report.md`

### 当前报告结论

- case1 的 best profile：
  - `core-exact`
- case2 的 best profile：
  - `brain-qa-compatible`

### 经验

这类报告文件非常适合作为后续重构阶段的“状态快照”：

1. 改完代码后重新生成
2. 直接看 best profile 有没有漂移
3. 直接看关键字段 delta 是扩大还是缩小

相比手工口头总结，这种固化产物更适合长期演进。

后面如果 mom-robo 或别的 report 也出现“主链一致但统计摘要口径不同”，就可以复用这套模式，而不用再次污染底层算法。

## 23. 处理：`style_factor_return_ts` 首日 48 条缺口已定位并修复，原因是 QA 对正式起始日补零截面

### 现象

在 case2 的完整 report compare 中，除了 3 个 deviation 字段外，还长期存在：

- `style_factor_return_ts`
  - baseline 长度：`12192`
  - Rust runtime 长度：`12144`

差了整整 `48` 条。

进一步拆开后发现：

- 缺失行全部在 `20240102`
- 正好是 `10` 个 style 因子 + `38` 个行业因子
- 行结构只有：
  - `as_of_date`
  - `name`
  - `value`
- 且这些 `value` 全是 `0.0 / -0.0`

### 关键判断

这不是 style 主链算法错误。

因为继续 keyed compare 后可以确认：

- `style_factor_return_ts` 的交集部分已经全部一致
- 其余模块：
  - `brinson_industry_attr`
  - `accum_brinson_industry_attr`
  - `style_factor_attr`
  - `portfolio_style_factor_attr`
  - `style_stability_df`
  - `portfolio_style_stability_df`

也都已经对齐。

真正的问题是 QA 输出在 `style_factor_return_ts` 上还有一个 packing 语义：

1. 如果首个持仓日已经落入正式报表区间
2. 但它前面没有能形成收益 period 的前置持仓
3. QA 仍会为该首日保留一整张零值 style/industry 因子截面

### 为什么 case1 没有这个问题

case1 的请求里首个 position 日期是：

- `20241231`

而报表正式 begin date 是：

- `20250101`

因此 `20241231` 属于 pre-begin 持仓，QA 不会在 `style_factor_return_ts` 里给它补零截面。

case2 则不同：

- 首个 position 日期是 `20240102`
- begin date 是 `20240101`

所以 `20240102` 已经处在正式报表区间里，QA 会保留这 48 条零值行。

### 正确修复

不要去改 `accumulate_style_return` 的核心公式。

正确修复应落在 Rust 的 packing 语义上：

1. 如果 `style_factor_return_ts` 缺少首个持仓日
2. 且 `first_position_date >= report_begin_date`
3. 则补一整张 style + industry 因子的零值截面
4. 如果 `first_position_date < report_begin_date`，说明它是 pre-begin 持仓，不补

### 修复结果

修复后重新 compare：

- case1：完整 JSON `COMPARE_OK`
- case2：
  - `style_factor_return_ts` 已完全对齐
  - 仅剩 3 个 deviation 字段存在极小残差

### 经验

这一步非常值得保留，因为它再次说明：

- 首日缺行不一定是 period math 错
- 也可能是服务端输出层对“无收益但需要展示的时点”做了显式补位
- 这种行为应该放在 compatibility / packing 层，不要污染核心算法层
