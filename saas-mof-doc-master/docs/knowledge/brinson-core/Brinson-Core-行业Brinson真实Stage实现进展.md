# Brinson-Core 行业 Brinson 真实 Stage 实现进展

## 1. 这次推进解决了什么

## 0. 2026-03-29 最新状态

当前真实结论需要更新为：

- 行业 return 主链路：case1 / case2 已对齐
- 行业 risk 主链路：case1 / case2 已对齐
- style factor attr 主链路：case1 / case2 已对齐
- advanced style stability：case1 / case2 已对齐

现在真正剩下的核心偏差，已经收缩到 case2 的 3 个 deviation：

- `m_sector_allocation_deviation`
- `m_security_selection_deviation`
- `m_interaction_deviation`

这意味着工程状态已经不再是“style/risk 还在迁移中”，而是：

- style / risk / stability 主功能已经迁移完成
- 剩下的是长样本 case2 的统计口径尾差

此前 `brinson-core` 的主能力主要集中在：

- 输入契约兼容
- golden fixture 回放
- 结果装配层 Rust 化

这次新增的重点是：

- 开始让 Rust 对真实 reference data 做行业 Brinson 计算

也就是说，工程状态已经从“只会回放 QA 结果”推进到“已经有第一版真实行业 stage 可以工作”。

## 2. 新增的真实计算组件

新增组件位于：

- `src/engine/stages.rs`

当前包括：

- `ArithmeticIndustryBrinsonStage`
- `EmptyStyleAttributionStage`

### 2.1 `ArithmeticIndustryBrinsonStage`

职责：

- 按日期读取组合持仓、benchmark 成分、证券收益、行业映射
- 逐行业聚合组合权重、基准权重、组合收益、基准收益
- 计算 Brinson 的：
  - allocation
  - selection
  - interaction
- 生成 `IndustryPackInput`

当前实现已经不再是“简化版经典 Brinson”，而是按 `mars` 真实口径推进到以下状态：

- 持仓日权重 / 行业，配下一交易日收益
- benchmark full constituents 可通过 `security_id` 表达
- 单期行业归因按 `sector share * abs_sum_p_weight` 口径缩放
- timing / management 采用 `mars.attribution.holding.attribution` 的累计公式
- `deannual_rp/rb/ra` 对应累计 unannualized sector return
- `rp/rb/ra` 对应最后一期 period 的 sector return

### 2.2 `EmptyStyleAttributionStage`

职责：

- 在风格 stage 还未完整移植前，生成结构合法的空 style 输出

这样可以保证：

- `PackAssemblerStage` 仍然可以产出完整 `BrinsonReport`
- 整条 Rust 流水线已经可以执行到底

## 3. 这意味着什么

这次之后，`brinson-core` 已经同时具备两种能力：

### 3.1 强一致回归护栏

- 对已 capture 的 QA case，仍然通过 golden fixtures 做严格一致性校验

### 3.2 第一版真实算法落点

- 对行业 Brinson，已经开始真正使用 reference data 计算

这两者结合起来非常重要，因为它避免了两种常见风险：

- 只有护栏，没有真实迁移
- 只有迁移，没有一致性保护

## 4. 当前还没有完成的部分

这次新增的 stage 仍然属于“第一版真实计算”，还不是最终 parity 版本。

当前已知还缺：

- 风格归因 stage 的真实迁移
- 风险稳定性计算迁移
- case2 这种长样本的完整回归固化
- style/risk 与 Brinson 行业部分一起做完整 report parity

## 5. 当前验证方式

新增测试包括：

- `tests/industry_stage.rs`

覆盖两类验证：

- 行业 stage 本身的算子输出是否符合预期
- `OptimizedBrinsonEngine + FileSnapshotReferenceDataProvider + PackAssemblerStage`
  是否已经能跑完整条流水线

## 6. 对下一阶段的意义

这一步之后，后续最自然的推进顺序是：

1. 用旧环境把真实 request 导出成 snapshot
2. 用 Rust 的 `FileSnapshotReferenceDataProvider` 吃 snapshot
3. 对行业 stage 的中间结果做 Python / Rust 对账
4. 再继续迁移 style stage

这样做的好处是：

- 能把“数据接入问题”和“算法公式问题”分离
- 能让每一阶段都有可测试产物
- 能持续维持已 capture QA case 的结果护栏

## 7. 用真实 snapshot 跑出的第一轮结论

已经可以通过：

- `examples/compute_snapshot.rs`

直接消费真实导出的 snapshot，离线跑出 Rust 结果。

对于 case1，当前最新结论已经从“能跑”推进到“Brinson 行业部分 parity”：

- 使用完整 pre-begin snapshot 后
- Rust 的 `m_sector_allocation / m_security_selection / m_interaction / manage_return / timing_return`
  已和 brain 对齐到浮点误差级别
- `industry_preference / industry_goodat / top3 preference / top3 goodat`
  也已对齐
- `accum_brinson_industry_attr`
  按 `sector` 作为 key 对齐后已一致

剩余未完成的不是 Brinson 行业本身，而是：

- style factor return / risk
- active risk / timing risk
- 以及最终 report 的列表顺序归一化问题

这意味着当前工程状态可以更准确地表述为：

- Rust 已完成 Brinson 行业主链路真实迁移
- case1 已达到“行业部分可作为重构校验样例”的程度
- 下一阶段重点应转向 style / risk 和完整回归工具链

## 8. 补充：case2 也已完成 Brinson summary parity

在补导出完整 case2 snapshot 后，Rust 对：

- `m_sector_allocation`
- `m_security_selection`
- `m_interaction`
- `manage_return`
- `manage_return_deannual`
- `timing_return`
- `timing_return_deannual`

这七个 Brinson summary 核心指标，也已经和 brain 对齐到浮点误差级别。

这件事的意义在于：

- parity 不是只在短样本 case1 上成立
- 对于 254 个观察点的一年期长样本，当前实现同样稳定

因此现在可以把结论升级为：

- Rust Brinson 行业主链路已经在短样本、长样本两个 QA case 上完成 summary parity
- 后续工作重心可以更明确地转到 style/risk 与完整 report 对齐

## 9. 新进展：Style Stage 已从空实现升级为真实计算

在这一轮里，Rust 侧新增了：

- `RiskModelStyleAttributionStage`

它不再只是输出空表，而是已经按照 `mars.EquityStyleFactorAttribution` 的主结构实现了：

1. 单期 factor exposure / factor return / specific return 计算
2. 单期 factor risk / specific risk 计算
3. style return 的 linking accumulate
4. style exposure / risk 的累计均值
5. `StylePackInput` 所需的 period rows 和 accumulated rows 输出

同时新增了：

- `tests/style_stage.rs`

用于验证一个最小因子模型样例下：

- active factor return
- active factor risk
- active style exposure

都能按预期算出。

## 10. 当前真实样例对账结论

用：

- `case1-snapshot-latest.json`
- `case2-snapshot-latest2.json`

重新跑 Rust 后，结论分成两层：

### 10.1 已达到的效果

- style/risk 不再是空实现
- `style_factor_attr` 等表开始输出真实值
- Brinson 行业 summary 核心指标继续保持 parity，没有回退

### 10.2 仍然不能与 brain 全量对齐的部分

主要偏差集中在：

- `sf_country_return`
- `sf_factor_return`
- `sf_country_risk`
- `sf_factor_risk`
- `style_preference`
- `style_goodat`
- 以及行业 risk summary：
  - `manage_risk`
  - `timing_risk`

其中：

- `manage_risk / timing_risk = 0`
  是因为行业 risk stage 仍未迁移
- style return / risk 偏差大
  则主要是 snapshot 数据不完整造成的

## 11. 当前 blocker 已经非常明确

## 12. 补充更新：Style stability 已正式收口

这一轮里，`RiskModelStyleAttributionStage` 又补了一层 very important 的口径修正：

- 主归因累计仍按 `windows(2)` 的 period 走
- 但 `advanced` 的 stability risk / weight 必须按完整 holding-day list 走

这条结论来自直接对照：

- `brain/lib/portfolio_management/algorithm_unit/holding_attr/equity_advanced/equity_attribution_advanced.py`
  中的 `calc_style_stability`

它并不是复用 `EquityStyleFactorAttribution` 的 period 输出，而是单独遍历：

- `trading_day_list`

所以：

- 终点持仓日必须进入 stability 统计
- 但不能反过来污染累计 exposure / risk 的 period 均值

Rust 修正后，case1 / case2 的：

- `style_factor_attr`
- `portfolio_style_factor_attr`
- `style_stability_df`
- `portfolio_style_stability_df`

都已经回到浮点误差级别。

## 13. 当前唯一主要未收口项

case2 仍剩：

- `m_sector_allocation_deviation` diff `0.001305670298887951`
- `m_security_selection_deviation` diff `0.0009956139500209016`
- `m_interaction_deviation` diff `0.0014098479195613356`

当前更可信的判断是：

- Brinson 行业公式本身不是主因
- 更像是 case2 在 `preBeginDate=20231231` 上存在额外 observation / period 样本
- 而现有 snapshot 导出只保留了 request position 中显式出现的日期

也就是说，当前 snapshot 边界本身就可能把 Python 真正参与 `std()` 的那一层样本截掉了。

style/risk 对齐的真正 blocker 不是“Rust 还没写公式”，而是：

- benchmark-only 成分缺少 `factorExposures`
- benchmark-only 成分缺少 `specificRisks`

按真实 snapshot 统计：

- case1 平均只有 `1.07%` benchmark 权重有 `security_index`
- case2 平均只有 `22.27%` benchmark 权重有 `security_index`

这意味着当前 style/risk 实际只是在“持仓 overlap 范围”里做真实计算。

因此下一阶段的最短路径已经很清楚：

1. 先补 exporter / snapshot schema，使 benchmark-only 也能带 exposure/risk
2. 再继续收敛 style/risk parity
3. 最后补行业 risk stage，完成完整 report 的 summary parity

## 12. 新结论修正：benchmark-only style/risk 数据并不是 Redis 没有，而是 exporter 丢了

在继续向前排查后，结论比前一版更准确：

- Redis 风险模型底层本身支持按 `sec_id_ints` 取 exposure / specific risk
- benchmark-only 成分不是“天然取不到”
- 真正的丢失点在 exporter

具体来说，虽然 exporter 已经把查询 universe 扩成了：

- `target_security_ids = 持仓 equity ids ∪ benchmark 全成分 ids`

但在写 snapshot 时仍保留了旧逻辑：

- `security_index is None -> continue`

这会把 benchmark-only 的风险模型数据再次裁掉。

## 13. 修复后的效果

修复 exporter 后，case1 的 style summary 已经完成 parity：

- style return
- style risk
- `style_preference`
- `style_goodat`

全部与 brain 对齐到浮点误差级别。

这说明当前整体状态可以重新表述为：

1. Rust Brinson 行业主链路已完成 parity
2. Rust style 主链路在 reference data 补齐后也已证明可完成 parity
3. 当前剩余真正未完成的核心模块，已经进一步收敛到：
   - 行业 risk
   - `manage_risk / timing_risk`
   - 对应 active-risk table

## 14. 新进展：累计均值口径已统一到 observation-count

这轮又补了一层很关键但很容易忽略的口径统一。

此前 case2 还残留一个典型信号：

- style risk / exposure
- 行业累计 `wp/wb/wa`
- 行业累计 `deannual_rp/rb/ra`

会出现接近统一比例的偏差。

继续向下排查后，结论明确为：

- 这些字段不是单个公式错
- 而是累计均值的分母没有统一到 `annualization_observation_count()`

现在 Rust 已把以下逻辑统一修正：

1. style risk 累计均值
2. style exposure 累计均值
3. specific risk 均值
4. 行业累计权重均值
5. 行业累计 return 均值

修完之后，case2 的结论进一步收敛为：

- style summary 全部与 brain 对齐到浮点误差级别
- `accum_brinson_industry_attr`
  按 `sector` 对齐后也已一致到浮点误差级别

## 15. 当前真实样例的最新状态

### 15.1 Case 1

使用：

- `case1-snapshot-with-style-ids.json`
- `case1-rust-style-stage-with-style-ids.json`

当前已对齐到浮点误差级别的部分包括：

- Brinson 行业 summary 主链路
- style return 四项
- style risk 四项
- `style_preference`
- `style_goodat`
- `accum_brinson_industry_attr`

当前仍未完成的主要部分：

- `manage_risk`
- `timing_risk`
- `brinson_industry_attr` 中 active-risk 行

### 15.2 Case 2

使用：

- `case2-snapshot-with-style-ids-v2.json`
- `case2-rust-style-stage-with-style-ids.json`

当前已对齐到浮点误差级别的部分包括：

- Brinson 行业 summary 七个核心 return 指标
- style return 四项
- style risk 四项
- `style_preference`
- `style_goodat`
- `accum_brinson_industry_attr`

当前仍未完成的主要部分也已经很集中：

- `manage_risk`
- `timing_risk`
- `m_sector_allocation_deviation`
- `m_security_selection_deviation`
- `m_interaction_deviation`
- `brinson_industry_attr` 中 active-risk 行

这些未完成项本质上都指向同一个缺口：

- 行业 risk stage 还没有迁移

## 16. 对当前工程状态的更准确描述

截至这一轮，`brinson-core` 的状态可以更准确地表述为：

1. Rust 已完成 Brinson 行业 return 主链路迁移
2. Rust 已完成 style return / style risk 主链路迁移
3. 两个 QA case 都已经可作为真实 parity 回归样例
4. 当前剩余未完成的核心算法模块，主要就是行业 risk 及其报表装配

这比更早阶段“行业完成，style 还是空实现”的状态前进了非常多。

后续如果继续推进，最短路径已经很明确：

1. 迁移行业 risk stage
2. 产出 active-risk period rows / accumulated rows
3. 收口：
   - `manage_risk`
   - `timing_risk`
   - 三个 `*_deviation`
4. 最后再做完整 report compare 的排序标准化

## 17. 新进展：行业 risk 主链路已经正式接入 Rust

这一轮新增的关键变化，不再只是“知道问题在哪”，而是把行业 risk 的真实计算链路也接进了 `ArithmeticIndustryBrinsonStage`。

当前 Rust 单期行业 stage 已经同时计算：

1. 时机收益 / 管理收益
2. 时机风险 / 管理风险
3. 行业 allocation / selection / interaction 的 return
4. 行业 allocation / selection / interaction 的 risk
5. 行业权重与行业收益表

对应的风险计算，不再是占位 0，而是按 `mars` 的多因子风险模型主结构迁移：

- `exp_fc_wa_exp`
- `sv_wa`
- `total_active_risk`
- `allocation_rho`
- `selection_rho`

## 18. 这一轮真实样例的新结论

### 18.1 Case 1

当前已对齐到浮点误差级别：

- Brinson 行业 summary 全量核心字段
- 行业 risk summary
  - `manage_risk`
  - `manage_risk_deannual`
  - `timing_risk`
  - `timing_risk_deannual`
- 三个 deviation
  - `m_sector_allocation_deviation`
  - `m_security_selection_deviation`
  - `m_interaction_deviation`
- `brinson_industry_attr`
  按 `(sector, attribution_type)` 对齐后一致
- `accum_brinson_industry_attr`
  按 `sector` 对齐后一致

### 18.2 Case 2

当前已对齐到浮点误差级别：

- Brinson 行业 return summary
- 行业 risk summary
  - `manage_risk`
  - `manage_risk_deannual`
  - `timing_risk`
  - `timing_risk_deannual`
- `brinson_industry_attr`
  按 `(sector, attribution_type)` 对齐后一致
- `accum_brinson_industry_attr`
  按 `sector` 对齐后一致

当前仍剩下的 Brinson 相关残差，已经进一步缩到只剩：

- `m_sector_allocation_deviation`
- `m_security_selection_deviation`
- `m_interaction_deviation`

## 19. 新发现：剩余 deviation 更像“period 统计口径”问题，不再是 Brinson 行业公式问题

现在 case2 剩下的三个 deviation：

- `0.001305670298888...`
- `0.000995613950020...`
- `0.001409847919561...`

呈现出非常稳定的一致比例特征。

这说明：

- 行业 return/risk 主公式已经对
- 行业表格装配已经对
- 剩下的问题更像是 `mng_ability_per.std()` 对应的 period 统计口径差异

也就是说，当前下一步不应该再去改：

- 行业风险分解公式
- 行业权重/收益主逻辑

而应该只盯：

- deviation 的取样集合
- period 个数
- 是否存在额外 observation/对齐处理

## 20. 另一条独立残差：style stability 仍有一条 advanced 专属分支未单独移植

这一轮也确认了：

- `portfolio_style_factor_attr`
  已通过“portfolio accumulate 用 benchmark=0”这一口径修正完成 parity

但仍残留：

- `style_stability_df`
- `portfolio_style_stability_df`

里与：

- `active_risk`
- `active_weight`

相关的少量月份值偏差。

这不是行业 Brinson 问题，而是 advanced 输出里还有一条：

- `calc_style_stability(data_param)`

的专门路径没有单独迁移。

因此当前工程状态可以进一步细化成：

1. Brinson 行业 return/risk 主链路已经基本收口
2. style 主 summary 与 portfolio attr 已基本收口
3. 剩余工作主要集中在：
   - case2 的三项 deviation
   - style stability 的专门 period 路径

## 21. 新进展：case2 的行业 period 样本已经被 Rust 与离线 Python 双重锁定

本轮新增了两个诊断入口：

- Python：`tools/replay_python_brinson_periods.py`
- Rust：`brinson-core/examples/diagnose_periods.rs`

针对 case2：

- request：`a-brinson-request2.json`
- snapshot：`case2-snapshot-with-style-ids-v2.json`

得到的结论是：

1. Rust period count = `253`
2. 离线 Python period count = `253`
3. 每期：
   - `sector_allocation`
   - `equity_selection`
   - `interaction`
   - `manage_return`
   都已经对齐到浮点误差级别

这一步非常关键，因为它把“是否还有行业主公式偏差”这个问题彻底排除了。

## 22. 新结论：case2 剩余 deviation 更像 service 兼容口径，而不是当前本地源码口径

在 case2 上：

- Rust 当前输出：
  - `m_sector_allocation_deviation = 0.6635185871904575`
  - `m_security_selection_deviation = 0.5049470799883354`
  - `m_interaction_deviation = 0.7338204013660763`
- 离线 Python period replay：
  - 与 Rust 完全一致
- QA brain：
  - `0.6622129168915696`
  - `0.5039514660383145`
  - `0.732410553446515`

对比后可以确认：

1. QA case2 明显不是当前本地源码对应的 `sample std (ddof=1)`
2. 它更接近：
   - `population std (ddof=0)`
3. 仍有极小残差，说明 QA 服务侧还有轻微运行时差异

因此当前工程判断要更新为：

1. Brinson 行业主链已经完成 parity
2. 剩余 case2 deviation 是“service 兼容口径问题”
3. 这个问题不应该通过修改行业 period 公式来修

## 23. 额外校验：`preBeginDate` 不是当前 advanced holding attribution 的有效主链输入

本轮重新追源码后确认：

- `BaseHoldingAttribution._verify_parameter()` 会记录 `preBeginDate`
- 但 `AdvancedEquityAttribution` 当前 loader 链路并没有把它重新并回 `trading_day_list`

这意味着：

- 之前针对 case2 做 synthetic `preBeginDate` / synthetic 首期持仓 的试验，
  更适合作为“兼容性探索”
- 不适合作为当前本地源码真实主链的直接修复方向

这个结论也进一步支持：

- 现在不该继续改 Rust 的行业主公式
- 后续要把注意力放在 deviation 的兼容策略上

## 24. 已落地：deviation 兼容策略已经进入 `brinson-core` 代码结构

为了把“主算法口径”和“服务兼容口径”分层，这一轮已经在 Rust 中落地：

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

默认仍然保持：

- `CoreExact`
  - 对应 `Sample`

因此：

- 当前 golden case
- 当前主链 parity

都不会被破坏。

## 25. 兼容层实际效果

case2 使用 `population` 模式后：

- `m_sector_allocation_deviation` 只差 `6.93e-06`
- `m_security_selection_deviation` 只差 `3.29e-06`
- `m_interaction_deviation` 只差 `4.18e-05`

同时：

- `m_sector_allocation`
- `m_security_selection`
- `m_interaction`

仍保持浮点误差级别一致。

这说明：

1. 把兼容能力放在 pack/assembler 层是合理的
2. 不需要再去碰行业 period 公式
3. 后续如果要对接 QA 兼容结果，优先在 assembler 配置层切换，而不是在 stage 层做条件分支

## 26. 兼容 profile 已接入真正入口

现在这套 profile 不再只是：

- pack 层工具函数
- diagnose example

而是已经接到更上层入口：

1. `OptimizedBrinsonEngine::with_compatibility_profile(...)`
2. `examples/compute_snapshot.rs`
   - 支持 `--compat-profile core-exact`
   - 支持 `--compat-profile brain-qa-compatible`

这意味着后续外层业务代码如果要接入：

- mom
- mom-robo
- 统一重构后的代码包

都可以直接按 profile 选择兼容口径，而不用了解：

- `sample std`
- `population std`

这样的底层实现细节。
