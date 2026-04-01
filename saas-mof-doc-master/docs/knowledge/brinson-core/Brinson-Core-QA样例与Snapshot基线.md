# Brinson-Core QA 样例与 Snapshot 基线

## 1. 目的

## 1.1 2026-03-29 最新基线结论

截至这一轮，两个 QA case 的对账结论已经可以分成两层：

第一层，已经完全收口到浮点误差级别：

- `brinson_industry_attr`
- `accum_brinson_industry_attr`
- `style_factor_attr`
- `portfolio_style_factor_attr`
- `style_stability_df`
- `portfolio_style_stability_df`
- `manage_risk`
- `manage_risk_deannual`
- `timing_risk`
- `timing_risk_deannual`

第二层，当前只剩 case2 的 3 个 deviation：

- `m_sector_allocation_deviation`
- `m_security_selection_deviation`
- `m_interaction_deviation`

这三个值目前仍然可以视为“case2 snapshot 边界问题”的观测哨兵。

这个文档把当前已经沉淀下来的 Brinson QA 素材整理成固定基线，方便后续做三类工作：

- Rust 重构回归
- 中间结果对账
- 数据问题排查

## 2. 样例文件位置

### Case 1

- 请求：`brain-brinson-test/a-brinson-request.json`
- Brain 结果：`brain-brinson-test/output/case1-result.json`
- 真实 reference snapshot：`brain-brinson-test/output/case1-snapshot.json`
- 最新完整 snapshot：`brain-brinson-test/output/case1-snapshot-latest.json`

### Case 2

- 请求：`brain-brinson-test/a-brinson-request2.json`
- Brain 结果：`brain-brinson-test/output/case2-result.json`
- 真实 reference snapshot：`brain-brinson-test/output/case2-snapshot.json`
- 最新完整 snapshot：`brain-brinson-test/output/case2-snapshot-latest2.json`

## 3. Snapshot 统计

### Case 1

- 旧 snapshot 交易日数：12
- 持仓 universe：18
- 其中权益 security id：16
- 旧 `securityReturns`：72
- 旧 `securityIndustries`：192
- 旧 `benchmarkWeights`：24
- 旧 `benchmarkReturns`：12
- `factorReturns`：576
- `factorExposures`：9216
- `riskCovariance`：24192
- `specificRisks`：192
- snapshot 文件大小：约 4.4 MB

补导出后的最新 case1 snapshot：

- 交易日数：13
- 起止日期：`20241231 ~ 20250117`
- `securityReturns`：3952
- `securityIndustries`：4082
- `benchmarkWeights`：3900
- `benchmarkReturns`：13

这是当前应该作为 Brinson 行业 parity 基线使用的版本。

### Case 2

- 交易日数：254
- 持仓 universe：126
- 其中权益 security id：117
- `securityReturns`：23622
- `securityIndustries`：29718
- `benchmarkWeights`：9363
- `benchmarkReturns`：254
- `factorReturns`：12192
- `factorExposures`：1426464
- `riskCovariance`：512064
- `specificRisks`：29718
- snapshot 文件大小：约 242 MB

补导出后的最新 case2 snapshot：

- 交易日数：254
- 起止日期：`20240102 ~ 20250117`
- 文件大小：约 270 MB

说明：

- request 虽然带了 `preBeginDate=20231231`
- 但这一天本身不是 position 中的观察点
- brain 的 annualization 仍然会把 observation count 视作 `254`

## 4. 一个必须特别注意的指标

### Benchmark overlap 与 pre-begin

旧 snapshot 的两个核心问题是：

1. `benchmarkWeights` 只能保存“基准成分里同时出现在请求持仓 universe 中的证券”
2. case1 / case2 都缺少了 `preBeginDate`

实测：

- Case 1 旧 overlap securities：2
- Case 2 overlap securities：41

补导出后的 case1 已经修复这两个问题：

- benchmark 全成分可表达
- `preBeginDate=20241231` 已进入 snapshot

这说明当前基线应区分“旧基线”和“完整基线”：

- 旧基线：适合验证导出链路是否能跑通
- 完整基线：适合做 Brinson 行业 parity 校验

补充一个新的重要事实：

- case2 request 带了 `preBeginDate=20231231`
- 但当前 snapshot 仍然只有 `20240102 ~ 20250117`

原因不是 request 没有 pre-begin，而是当前 snapshot 过滤逻辑按：

- `request.position_index_by_date(date).is_some()`

只保留显式 position 日期。

这意味着：

- case2 如果 Python 在 deviation 统计里实际吃到了 pre-begin observation
- 当前 snapshot 基线天生就缺那层 reference data

后续如果要把 case2 的 3 个 deviation 彻底收口，需要优先考虑补一版：

- 含 pre-begin reference data 的 case2 snapshot

但这一轮实验又把这个结论进一步细化了：

- 仅仅补 snapshot 里的 `20231231` 没有任何效果
- 因为 request 本身没有 `20231231` 这期持仓快照
- Rust 主链仍只会按显式 `position` 生成 period

也就是说，case2 的剩余 deviation 不是“少一个 tradingDay”这么简单，而更像是：

- brain 的 deviation 统计路径，可能吃到了某条额外首期 observation
- 但 summary 平均值路径并没有一起吃进去

## 5. 如何使用这些基线

推荐用法：

1. 请求 JSON 作为输入契约基线
2. Brain 结果 JSON 作为最终输出基线
3. 最新完整 Snapshot JSON 作为 reference data 基线

这样可以把问题切成三层：

- 输入规范化是否一致
- reference data 是否读取一致
- 归因计算是否一致

## 6. 当前离线运行入口

已新增 Rust example：

- `brinson-core/examples/compute_snapshot.rs`

用法示例：

```bash
cd /Users/jiangtao.sheng/Documents/demo/codex-mof/brinson-core
cargo run --example compute_snapshot -- \
  --request /Users/jiangtao.sheng/Documents/demo/codex-mof/brain-brinson-test/a-brinson-request.json \
  --snapshot /Users/jiangtao.sheng/Documents/demo/codex-mof/brain-brinson-test/output/case1-snapshot.json \
  --output /Users/jiangtao.sheng/Documents/demo/codex-mof/brain-brinson-test/output/case1-rust-stage1.json
```

这个入口的意义是：

- 不依赖 `brain` HTTP 服务
- 可以直接拿固定 snapshot 跑 Rust
- 方便对账每次底层重构后的输出变化

## 7. 当前结论

## 8. 当前回归结论

### Case 1

在使用：

- `case1-result.json`
- `case1-snapshot-latest.json`

做对账时，Rust 当前已经达到：

- Brinson 行业 summary 与 brain 一致（浮点误差级别）
- `industry_preference / industry_goodat` 一致
- `accum_brinson_industry_attr` 按 `sector` 作为 key 对齐后一致

需要注意：

- 完整 report 仍不能全量 compare pass
- 原因不是 Brinson 行业错误，而是 style/risk 仍是空实现

### Case 2

在使用：

- `case2-result.json`
- `case2-snapshot-latest2.json`

做对账时，Rust 当前已经达到：

- Brinson summary 七个核心指标全部与 brain 对齐
  - `m_sector_allocation`
  - `m_security_selection`
  - `m_interaction`
  - `manage_return`
  - `manage_return_deannual`
  - `timing_return`
  - `timing_return_deannual`
- `industry_top3_preference` 一致
- `industry_top3_goodat` 一致

需要注意：

- 和 case1 一样，完整 report 仍不会全量 compare pass
- 原因依旧是 style/risk 尚未实现

## 9. 当前结论

这两组样例已经足够支撑下一阶段工作：

- exporter 路径已经跑通
- case1 的完整 reference data 已经被固化
- case2 的完整 snapshot 已落盘，并已用于 Brinson summary 校验
- 后续可以在不依赖线上 `brain` HTTP 调用的情况下，重复做 Rust 行业 Brinson 计算和对账

## 10. 新一轮 Rust 对账结果

本轮新增真实 style stage 后，新的离线输出文件为：

- `brain-brinson-test/output/case1-rust-style-stage.json`
- `brain-brinson-test/output/case2-rust-style-stage.json`

## 11. 当前对账分层结论

### 11.1 继续保持一致的部分

两组 case 的 Brinson 行业 summary 核心指标仍然一致：

- `m_sector_allocation`
- `m_security_selection`
- `m_interaction`
- `manage_return`
- `manage_return_deannual`
- `timing_return`
- `timing_return_deannual`

### 11.2 已经从“空实现”升级成“真实实现”的部分

Rust 现在已经能真实输出：

- `style_factor_attr`
- `portfolio_style_factor_attr`
- `style_stability_df`
- `portfolio_style_stability_df`

也就是说，style/risk 已经不是占位 0。

### 11.3 仍然存在明显偏差的部分

这部分需要更新：

- 上面这些 style / risk 偏差已经在后续轮次中陆续收口
- 当前不再把它们视为 blocker

当前真正剩下的偏差只集中在 case2：

- `m_sector_allocation_deviation`
- `m_security_selection_deviation`
- `m_interaction_deviation`

## 12. 偏差量化

### Case 1

当前已无值得单独列出的结构性偏差：

- 所有主要表和摘要指标都已到浮点误差级别

### Case 2

当前剩余偏差为：

- `m_sector_allocation_deviation`: `0.001305670298887951`
- `m_security_selection_deviation`: `0.0009956139500209016`
- `m_interaction_deviation`: `0.0014098479195613356`

补充判断：

- 这 3 个值不是行业 Brinson 主公式错的信号
- 更像是 Python `std()` 输入样本集合和 summary 使用的 period 集合之间仍差一个 observation

这一轮 synthetic 实验的结果尤其重要：

- 如果同时给 request + snapshot 都补一段 synthetic `20231231` 首期样本
- `m_sector_allocation_deviation` 会几乎完全收口
- 但 `m_sector_allocation / m_security_selection / m_interaction / manage_return / timing_return`
  会被带偏

这说明：

- deviation 的根因很可能确实与“额外首期样本”有关
- 但这段样本不属于当前已对齐的 summary 主链

## 13. 当前推荐使用的基线文件

随着 style/risk 数据补齐，当前更推荐直接使用下面这组文件作为固定回归素材：

### Case 1

- 请求：`brain-brinson-test/a-brinson-request.json`
- Brain 结果：`brain-brinson-test/output/case1-result.json`
- 最新 style 完整 snapshot：`brain-brinson-test/output/case1-snapshot-with-style-ids.json`
- 当前 Rust 输出：`brain-brinson-test/output/case1-rust-style-stage-with-style-ids.json`

### Case 2

- 请求：`brain-brinson-test/a-brinson-request2.json`
- Brain 结果：`brain-brinson-test/output/case2-result.json`
- 最新 style 完整 snapshot：`brain-brinson-test/output/case2-snapshot-with-style-ids-v2.json`
- 当前 Rust 输出：`brain-brinson-test/output/case2-rust-style-stage-with-style-ids.json`

## 14. 当前回归结论已经更新

前面文档里关于“style/risk 仍有明显偏差”的表述，已经不是最新状态。

基于最新 snapshot 和当前 Rust 实现，最新结论是：

### 14.1 Case 1

已与 brain 对齐到浮点误差级别：

- Brinson 行业 summary 主链路
- style return 四项
- style risk 四项
- `style_preference`
- `style_goodat`
- `accum_brinson_industry_attr`

仍未对齐：

- `manage_risk`
- `timing_risk`
- `brinson_industry_attr` 中 active-risk 行

### 14.2 Case 2

已与 brain 对齐到浮点误差级别：

- Brinson 行业 summary 七个核心 return 指标
- style return 四项
- style risk 四项
- `style_preference`
- `style_goodat`
- `accum_brinson_industry_attr`

仍未对齐：

- `manage_risk`
- `timing_risk`
- `m_sector_allocation_deviation`
- `m_security_selection_deviation`
- `m_interaction_deviation`
- `brinson_industry_attr` 中 active-risk 行

## 15. 当前偏差量化

### Case 1

截至本轮回归，case1 的剩余偏差已经非常集中：

- `manage_risk`: `0.00638117358741161`
- `manage_risk_deannual`: `0.0004035808536225644`
- `timing_risk`: `0.2508706516066694`
- `timing_risk_deannual`: `0.015866453143353103`

其余 style summary 与累计行业表格字段，已经在浮点误差级别内。

### Case 2

截至本轮回归，case2 的剩余摘要偏差为：

- `m_sector_allocation_deviation`: `0.001305670298888173`
- `m_security_selection_deviation`: `0.0009956139500209016`
- `m_interaction_deviation`: `0.0014098479195613356`

需要特别说明：

- `manage_risk / timing_risk` 这一层已经在本轮收口到浮点误差级别
- 当前剩余残差主要只剩：
  - 三个 deviation
  - style stability 专属路径

## 16. 使用这些样例时的两个注意事项

### 16.1 表格字段不要只按数组下标 compare

例如：

- `accum_brinson_industry_attr` 应按 `sector`
- `style_preference` / `style_goodat` 应按 `style_name`

按 key 对齐后，当前这些字段实际上已经与 brain 对齐到浮点误差级别。

### 16.2 observation count 和 period count 不是一回事

在这两组 QA case 里，累计均值字段的分母应按：

- `annualization_observation_count()`

而不是简单按：

- `periods.len()`

这条结论对后续继续迁移：

- 行业 risk
- 稳定性指标
- 其他累计均值类字段

都非常关键。

## 17. 本轮更新后的更精确状态

### 17.1 已完全收口的模块

截至当前版本，下面这些部分已经可以把 case1 / case2 作为稳定 QA 基线使用：

- Brinson 行业 return summary
- Brinson 行业 risk summary
- `brinson_industry_attr`
  按 `(sector, attribution_type)` 对齐
- `accum_brinson_industry_attr`
  按 `sector` 对齐
- style summary
- `style_factor_attr`
- `portfolio_style_factor_attr`

### 17.2 当前剩余残差

#### Case 1

当前剩余主要是 stability 专属路径：

- `portfolio_style_stability_df`
  - `active_risk` 最大绝对偏差：`0.00023868253918633148`
  - `active_weight` 最大绝对偏差：`0.0038616840161300806`

#### Case 2

当前剩余分成两类：

1. Brinson deviation
   - `m_sector_allocation_deviation`: `0.001305670298887951`
   - `m_security_selection_deviation`: `0.0009956139500209016`
   - `m_interaction_deviation`: `0.0014098479195613356`
2. stability 专属路径
   - `portfolio_style_stability_df`
     - `active_risk` 最大绝对偏差：`0.00023868253918633148`
     - `active_weight` 最大绝对偏差：`0.0038616840161300806`

### 17.3 需要怎么使用这些基线

如果后续继续推进 parity，推荐优先顺序是：

1. 先保持 summary 与行业表格继续不回退
2. 再单独追：
   - case2 deviation
   - style stability 的 advanced 专属路径
3. 对表格始终做 keyed compare，而不是按数组下标 compare

核心摘要中的绝对偏差示例：

- `sf_country_return`: `0.063802769097`
- `sf_factor_return`: `0.029909960616`
- `sf_country_risk`: `0.041242996688`
- `sf_factor_risk`: `0.034850220407`
- `sf_specific_return`: `0.041525062238`
- `sf_specific_risk`: `0.005556649615`
- `manage_risk`: `0.052650681218`
- `timing_risk`: `0.103886910118`

## 13. 为什么 style/risk 仍然不可能完全对齐

对 snapshot 统计后，benchmark 可进入 style 风险模型的权重覆盖率为：

- case1：平均 `1.07%`
- case2：平均 `22.27%`

原因是：

- `benchmarkWeights` 可以表达 benchmark-only 成分
- 但 `factorExposures / specificRisks` 还只能靠 `security_index`
- 而 `security_index` 只覆盖 request 持仓 universe

因此当前 snapshot 仍然只能支持：

- 行业 Brinson 的全 benchmark 归因

还不能支持：

- style/risk 的全 benchmark 风险模型归因

## 14. 这两组 case 当前最适合承担的职责

现在这两组 case 可以同时承担两类护栏：

1. 行业 Brinson parity case
2. style/risk 数据完整性校验 case

也就是说，后续如果 style/risk 又出现大偏差，不要先默认是公式错了。
应先检查 snapshot 是否已经把 benchmark-only exposure / specific risk 一并导出了。

## 15. 新进展：case1 在补齐 benchmark-only 风险模型数据后，style summary 已完成 parity

在修完 exporter 的两个关键点后：

1. `factorExposures / specificRisks` 支持 `securityId`
2. 不再因为 `securityIndex is None` 而丢弃 benchmark-only 记录

重新导出的：

- `case1-snapshot-with-style-ids.json`

已经包含：

- `298` 个 benchmark-only security id 的 exposure / specific risk

对应统计：

- `factorExposures = 195936`
- `specificRisks = 4082`

基于这个 snapshot 重新计算后，case1 的下列 style summary 字段已经与 brain 对齐到浮点误差级别：

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

这说明：

- Rust style stage 的主公式没有本质问题
- 之前的大偏差核心是 reference data coverage 不完整

### 当前 case1 剩余偏差

仍未完成的主要是行业 risk：

- `manage_risk`
- `manage_risk_deannual`
- `timing_risk`
- `timing_risk_deannual`

以及所有依赖这些字段的 industry active-risk table 行。

## 16. 新增 period 级诊断基线文件

为了把“主公式偏差”和“统计口径偏差”拆开，本轮新增了两套可重复诊断文件：

- Python 离线回放输出
  - `brain-brinson-test/output/case1-python-period-sums.json`
  - `brain-brinson-test/output/case2-python-period-sums.json`
- Rust 当前实现输出
  - `brain-brinson-test/output/case1-rust-period-sums.json`
  - `brain-brinson-test/output/case2-rust-period-sums.json`

对应工具分别是：

- `tools/replay_python_brinson_periods.py`
- `brinson-core/examples/diagnose_periods.rs`

这两套文件的职责不是替代最终 golden report，而是提供：

1. 每期 `sector_allocation / equity_selection / interaction / manage_return`
2. `sample std`
3. `population std`
4. period count

方便后续在重构时直接定位：

- 是 period 值本身变了
- 还是只有 deviation 汇总口径变了

## 17. case2 已确认：Rust 与离线 Python 的 period sums 完全收口

case2 使用：

- request: `a-brinson-request2.json`
- snapshot: `case2-snapshot-with-style-ids-v2.json`

回放后的结论是：

1. Rust period count = `253`
2. Python 离线 period count = `253`
3. 两边逐期 `sector_allocation / equity_selection / interaction / manage_return`
   最大绝对误差都只在浮点误差级别

这说明：

- case2 当前剩余问题已经不是 Brinson 行业主链公式问题

## 18. case1 与 case2 的 QA deviation 口径不一致

### case1

QA 输出与：

- `sample std (ddof=1)`

完全一致。

### case2

QA 输出与：

- `sample std (ddof=1)` 不一致
- `population std (ddof=0)` 非常接近

具体对比如下：

- `sector_allocation`
  - sample: `0.6635185871904575`
  - population: `0.6622059873151004`
  - QA brain: `0.6622129168915696`
- `equity_selection`
  - sample: `0.5049470799883354`
  - population: `0.5039481728182121`
  - QA brain: `0.5039514660383145`
- `interaction`
  - sample: `0.7338204013660761`
  - population: `0.7323687275381489`
  - QA brain: `0.732410553446515`

### 当前判断

更合理的解释是：

1. 当前本地源码的 Brinson 主链已经收口
2. QA 服务在 case2 这条更长样本链路上，最终 deviation 出参更接近另一条 `ddof=0` 兼容口径
3. 仍有极小残差，说明 QA 服务和本地 snapshot / 部署版本之间可能还存在很小的运行时差异

所以后续做兼容设计时，不应该为了 case2 的 deviation 去硬改主 Brinson 公式。

## 19. 已新增可切换的 deviation 兼容模式

在 `brinson-core` 中已经新增：

- `DeviationMode::Sample`
- `DeviationMode::Population`

默认仍然是：

- `Sample`

但现在可以在装配层显式切换到：

- `Population`

用于逼近 QA case2 的兼容口径。

### case2 population mode 结果

使用：

- `cargo run --example diagnose_periods ... --deviation-mode population`

得到：

- `m_sector_allocation_deviation = 0.6622059873151005`
- `m_security_selection_deviation = 0.5039481728182121`
- `m_interaction_deviation = 0.7323687275381491`

与 QA 的差值只剩：

- `-6.93e-06`
- `-3.29e-06`
- `-4.18e-05`

说明这套兼容层已经足够接近 QA case2 的实际表现，可以作为后续对接层的基础。

## 20. 已新增自动化 parity 报告

当前已经有脚本：

- `tools/generate_brinson_parity_report.py`

可直接刷新生成：

- `brain-brinson-test/output/brinson-parity-report.json`
- `brain-brinson-test/output/brinson-parity-report.md`

报告会同时比较：

1. `core-exact`
2. `brain-qa-compatible`

在 case1/case2 上的偏差表现，并自动标记每个 case 的 best profile。

当前最新报告结论：

- case1 best profile = `core-exact`
- case2 best profile = `brain-qa-compatible`

## 21. 当前完整 compare 状态

以完整 JSON 深度 compare 为准，当前状态已经更新为：

### case1

- baseline: `case1-result.json`
- runtime: `case1-compute-snapshot-core-exact.json`
- 结果：`COMPARE_OK`

也就是：

- 不仅最上层 summary 对齐
- `8` 个 top-level 模块都已经对齐

### case2

- baseline: `case2-result.json`
- runtime: `case2-compute-snapshot-brain-qa-compatible.json`

当前剩余差异只剩：

- `accumulate_results.m_sector_allocation_deviation`
- `accumulate_results.m_security_selection_deviation`
- `accumulate_results.m_interaction_deviation`

除此之外，其余 top-level 模块都已经对齐，包括：

- `brinson_industry_attr`
- `accum_brinson_industry_attr`
- `style_factor_attr`
- `portfolio_style_factor_attr`
- `style_stability_df`
- `portfolio_style_stability_df`
- `style_factor_return_ts`

## 22. case2 的 `style_factor_return_ts` 首日 48 条零值行已对齐

此前 case2 还存在：

- baseline：`12192`
- runtime：`12144`

的长度差。

现在已经确认并修复：

- QA 会在正式报表起始区间内的首个持仓日补一整张零值 style/industry 因子截面
- 但不会给 pre-begin 持仓补这层零值截面

Rust 侧已经按这个规则兼容，因此 `style_factor_return_ts` 已完全对齐。
