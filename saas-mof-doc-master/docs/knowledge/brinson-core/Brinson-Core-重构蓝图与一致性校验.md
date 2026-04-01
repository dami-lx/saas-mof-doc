# Brinson-Core 重构蓝图与一致性校验

## 1. 当前工程目标

当前 `brinson-core` 不是一个 HTTP 服务，而是未来统一量化分析代码包中的领域核心模块。

这样设计的原因是：

- 你后面还要把 `mom-robo` 中的逻辑一并合入
- 现在过早做 HTTP API，会把精力花在接口封装而不是计算内核
- 真实难点在于算法正确性、数据依赖抽象、结果一致性，而不是 Web 框架

## 2. 当前代码结构

### `compatibility`

职责：

- 兼容 `brain` 当前 `advanced_attribution` 请求结构
- 让 Rust 侧先吃下真实输入，不打断上游使用习惯

当前重点字段：

- `beginDate`
- `endDate`
- `frequency`
- `position`
- `benchmark`
- `industryType`
- `industryCategory`
- `industryLevel`

特别说明：

- 现网样例里已经出现 `industryCategory + industryLevel`，不再只有旧字段 `industryType`
- Rust 侧已把规范行业口径统一映射为 `SW21_1` 这类 canonical key

### `domain`

职责：

- 输入规范化
- 请求哈希稳定化
- 后续真实计算引擎的主要归属层

当前已实现：

- 日期合法性校验
- benchmark 权重和为 1 校验
- position 日期去重与排序
- holding 排序
- 规范化后的请求哈希生成
- 证券 universe 预编译
- 按整数 `security_index` 引用的 `indexed_positions`
- `CompiledBrinsonRequest`
  - 紧凑日期 `u32`
  - 枚举化频率 `TradingFrequency`
  - 面向计算的 benchmark / snapshot 编译结果

### `application`

职责：

- 组装“输入规范化 + 计算引擎”
- 提供外层统一调用入口

当前包含两个重要对象：

- `BrinsonService`
  - 统一入口，负责 normalize + compute
- `GoldenCaseOracle`
  - 当前的临时计算引擎，直接按请求哈希回放 QA 结果

以及一个新的关键边界：

- `assembler`
  - 把内部 `BrinsonReport` 结果对象稳定输出成现网兼容 JSON

### `engine`

这是这轮新增的“未来真实引擎着陆层”：

- `BrinsonReferenceDataProvider`
  - 统一定义外部参考数据输入边界
- `IndustryAttributionStage`
- `StyleAttributionStage`
- `AccumulationAssemblerStage`
- `OptimizedBrinsonEngine`
  - 以 `compile -> provider -> industry -> style -> assemble` 的流水线组织计算
- `PackAssemblerStage`
  - 已开始承接 Python `pack_*` 结果装配函数的 Rust 化实现

这个分层不是照搬 Python，而是为了把 IO、reference data、公式计算、结果装配彻底拆开。

## 2.6 已经开始替代 Python 的部分

当前不只是骨架，已经有第一批实际迁移完成的结果装配逻辑：

- `pack_accumulate_results`
- `pack_accum_annualized_unannualized_industry_attr`
- `pack_accum_annualized_unannualized_style_factor_attr`

这些逻辑已经落在 Rust 的 `src/engine/packing.rs` 中，并通过合成测试验证：

- 行业表输出
- 风格表输出
- 稳定性时间序列输出
- 汇总结果块输出

这意味着后续只要行业 stage 和风格 stage 产出对应中间结果，最终现网 JSON 已经可以由 Rust 自己组装。

### `verification`

职责：

- 承接未来的 parity test / regression test
- 保证真实引擎替换后仍能和现网输出逐字段对齐

当前已实现：

- `GoldenCaseFixtureSet`
  - 从 `brain-brinson-test` 加载请求、结果、metadata
  - 验证 `input_sha256`
  - 验证 `result_sha256`
- `compare_json`
  - 深度递归比较 JSON
  - 支持浮点容差
  - 可直接用于后续真实 Rust 引擎输出对账

## 2.5 当前已经落地的性能导向结构

虽然真正的计算内核还没迁完，但内部数据形态已经开始为性能优化服务：

- 规范化请求会生成 `SecurityUniverse`
  - 把 `(cons_position_id, exchange_cd, cons_category)` 编译成稳定索引空间
- 每个持仓截面会额外生成 `IndexedPositionSnapshot`
  - 持仓记录不再只依赖字符串主键，也能直接按 `security_index` 访问

这一步的意义是：

- 以后真实算法不需要每轮计算都做字符串查找
- 更适合用连续内存、数组和向量做批量计算
- 为并行和缓存都预留了更好的基础

## 3. 为什么先做 golden oracle

这是一个典型的“先锁结果，再替换内核”的迁移策略。

如果一开始直接在 Rust 中硬搬完整算法，会同时面对三类不确定性：

- Python 原实现链路长，依赖 `mars / solar / saturn / brain` 多层对象
- 外部 reference data 来源多，且口径复杂
- 输出结构很大，光 `style_stability_df` 就可能上千行

所以当前阶段先把真实 QA 输出沉淀成 fixture，再把测试护栏立住，有三个好处：

- 未来每做一步迁移都能即时知道有没有偏
- 可以逐模块替换，不需要一次性端到端重写
- 能避免“以为迁完了，其实细节口径已经漂了”的风险

## 4. 结果一致性目前如何保证

当前一致性校验分三层：

### 第一层：请求规范化一致

当前有两套 hash，各自负责不同事情：

- `input_sha256`
  - 来自原始请求文件内容
  - 用来保证 captured request 文件没有被改动
- `normalized request sha256`
  - 来自 Rust 规范化后的请求对象
  - 用来作为内部 canonical key，驱动 fixture 匹配和后续真实引擎缓存/复算

这保证了：

- 输入文件完整性可校验
- Rust 侧 canonicalization 也有独立稳定标识

### 第二层：输出文件完整性一致

fixture loader 会校验：

- `case1-result.json`
- `case2-result.json`

文件内容的 `sha256` 是否等于 metadata 中记录的 `result_sha256`。

这保证了 golden baseline 本身没有被误改。

### 第三层：结果内容深度一致

测试里使用 `compare_json` 对结果做深度递归比较，覆盖：

- 字段是否缺失
- 列表长度是否一致
- 数值是否在容差范围内一致
- 任意嵌套层级的对象结构是否一致

## 5. 当前两个真实 QA 回归样例

样例目录：

- `/Users/jiangtao.sheng/Documents/demo/codex-mof/brain-brinson-test/a-brinson-request.json`
- `/Users/jiangtao.sheng/Documents/demo/codex-mof/brain-brinson-test/a-brinson-request2.json`

对应结果：

- `/Users/jiangtao.sheng/Documents/demo/codex-mof/brain-brinson-test/output/case1-result.json`
- `/Users/jiangtao.sheng/Documents/demo/codex-mof/brain-brinson-test/output/case2-result.json`

当前这两个样例已经成为未来重构的第一批 test case。

建议后续持续增加：

- 行业口径变化样例
- benchmark 多成分样例
- 空仓/极端仓位样例
- 高频与低频样例
- normalized 与非 normalized 样例

## 6. 下一阶段建议的真正落地方向

### 阶段 A：先移植结果装配层

优先把 Python 中这些“结果拼装函数”迁到 Rust：

- `pack_accumulate_results`
- `pack_accum_annualized_unannualized_industry_attr`
- `pack_accum_annualized_unannualized_style_factor_attr`

原因：

- 这部分逻辑输入清晰、输出直接、最适合先模块化
- 即使底层计算暂时还来自别处，也能先把最终输出 schema 在 Rust 里固化

### 阶段 B：再移植单期 Brinson 和风格归因核心

把真实计算拆成几个明确能力：

- 单期行业 Brinson
- 多期累计与年化/非年化转换
- 风格因子暴露与收益归因
- 风格稳定性聚合

### 阶段 C：把外部数据读取抽象成 provider

建议最少抽象出这几类 provider trait：

- benchmark 权重与收益
- security return
- security -> industry mapping
- risk model exposure / covariance / specific risk
- factor return

这样算法核心就不会绑定在现在的 Python 数据装载实现上。

## 7. 结论

当前 `brinson-core` 已经不是一个“空壳仓库”，而是具备以下能力的迁移基座：

- 真实请求契约兼容
- 规范化输入层
- 基于 QA 输出的结果基线
- 可复用的一致性校验能力
- 面向真实 Rust 引擎替换的工程边界

它现在最重要的价值，不是已经算出了所有结果，而是已经把“如何安全地一步步替换旧系统”这件事变成了一个可执行工程过程。
