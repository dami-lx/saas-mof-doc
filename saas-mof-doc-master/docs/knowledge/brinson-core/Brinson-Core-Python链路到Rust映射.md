# Brinson-Core Python 链路到 Rust 映射

## 1. Python 当前主入口

原始实现核心入口位于：

- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/portfolio_management/algorithm_unit/holding_attr/equity_advanced/equity_attribution_advanced.py`

关键类：

- `AdvancedEquityAttribution`
- `NormalizedAdvancedEquityAttribution`

关键执行函数：

- `AdvancedEquityAttribution._load_input`
- `AdvancedEquityAttribution._execute`
- `calc_style_stability`
- `pack_accum_annualized_unannualized_industry_attr`
- `pack_accum_annualized_unannualized_style_factor_attr`
- `pack_accumulate_results`

## 2. Python `_execute` 的核心链路

`AdvancedEquityAttribution._execute` 做的事情可以拆成 6 步：

1. 组织 `model_param`
2. 组织 `data_param`
3. 调用 `EquityBrinsonAttribution` 计算行业 Brinson
4. 调用 `EquityStyleFactorAttribution` 计算风格因子归因
5. 调用 `calc_style_stability` 计算稳定性
6. 调用三个 `pack_*` 函数拼装最终返回 JSON

也就是说，Python 当前的职责实际上混在一起了：

- 输入准备
- 外部数据注入
- 归因计算
- 输出装配

## 3. Python 依赖的数据对象

从 `_load_input` 和 `_execute` 可以看出，真实计算需要的核心 reference data 至少包括：

- `trading_day_list`
- `portfolio_weight_series_dict`
- `benchmark_weight_series_dict`
- `security_return_series_dict`
- `factor_return_series_dict`
- `risk_model_dict`
- `security_sector_series_dict`

这说明 Brinson 计算本质上不是单一公式问题，而是“算法 + 参考数据口径”联合问题。

## 4. Rust 当前映射关系

### Python 请求参数 -> Rust `compatibility`

Rust 文件：

- `/Users/jiangtao.sheng/Documents/demo/codex-mof/brinson-core/src/compatibility/brain.rs`

当前作用：

- 吸收真实 `brain` 请求 JSON
- 保留现网字段命名和兼容性

### Python 输入预处理 -> Rust `domain::normalize_request`

Rust 文件：

- `/Users/jiangtao.sheng/Documents/demo/codex-mof/brinson-core/src/domain/normalized.rs`

当前作用：

- 排序
- 去重
- 规范行业口径
- 生成稳定请求哈希
- 预编译 `SecurityUniverse`
- 生成 `indexed_positions`

它对应的是 Python 中“进入真正计算前的参数整理和 canonicalization”。

### Python 最终执行入口 -> Rust `BrinsonService`

Rust 文件：

- `/Users/jiangtao.sheng/Documents/demo/codex-mof/brinson-core/src/application/service.rs`

当前作用：

- 对外暴露统一 `compute`
- 先 normalize，再调用 engine

它是未来统一重构后的主入口雏形。

### Python `_load_input + _execute` 混合逻辑 -> Rust `compile + provider + stages`

Rust 当前已经不准备照搬 Python 的类职责，而是拆成：

- `compile_request`
- `BrinsonReferenceDataProvider`
- `IndustryAttributionStage`
- `StyleAttributionStage`
- `AccumulationAssemblerStage`

这样对应关系更像是“职责拆解”，而不是“类名映射”。

### Python 真实计算结果 -> Rust `GoldenCaseOracle`

Rust 文件：

- `/Users/jiangtao.sheng/Documents/demo/codex-mof/brinson-core/src/application/oracle.rs`

当前作用：

- 不是计算
- 而是根据规范化请求哈希，回放 QA golden output

这个阶段的价值在于“锁结果”，不是“算结果”。

### Python 回归结果对账 -> Rust `verification`

Rust 文件：

- `/Users/jiangtao.sheng/Documents/demo/codex-mof/brinson-core/src/verification/compare.rs`
- `/Users/jiangtao.sheng/Documents/demo/codex-mof/brinson-core/src/application/fixtures.rs`

当前作用：

- 加载 captured QA 用例
- 校验样例元数据哈希
- 区分“原始请求文件 hash”和“规范化请求 hash”
- 深度比较 JSON 结果

## 5. 下一步最适合先迁哪些函数

优先级建议如下：

### 第一优先级：`pack_*` 输出装配函数

建议先迁：

- `pack_accumulate_results`
- `pack_accum_annualized_unannualized_industry_attr`
- `pack_accum_annualized_unannualized_style_factor_attr`

原因：

- 输入和输出边界最清楚
- 产物直接影响最终 JSON 契约
- 适合作为 Rust 数据结构设计的锚点

当前状态更新：

- 这三类装配逻辑已经开始落到 Rust `src/engine/packing.rs`
- Rust 侧已经有对应的强类型输入模型：
  - `IndustryPackInput`
  - `StylePackInput`
- 也已经有对应 stage：
  - `PackAssemblerStage`

### 第二优先级：`calc_style_stability`

原因：

- 它虽然逻辑不短，但已经相对独立
- 主要是时间序列聚合和口径转换问题
- 可以拆成较纯的数值处理函数

### 第三优先级：底层归因引擎

包括：

- `EquityBrinsonAttribution`
- `EquityStyleFactorAttribution`

这一层最重，因为既有矩阵运算，也深度绑定风险模型数据口径，适合在 provider 抽象定好后再进场。

## 6. 推荐的 Rust 分层草案

建议最终演进成下面的结构：

### `compatibility`

负责：

- 吃现网 DTO
- 未来可继续兼容 `mom-robo` 调用参数

### `domain/request`

负责：

- 请求规范化
- 参数校验
- canonical key 生成

### `domain/reference_data`

负责：

- provider trait 定义
- benchmark / return / industry / risk model 数据抽象

### `domain/engine`

负责：

- 单期行业 Brinson
- 单期风格归因
- 多期 linking / accumulate

### `domain/assembler`

负责：

- 对齐 Python `pack_*` 逻辑
- 输出最终 JSON 契约或强类型结果对象

### `verification`

负责：

- regression fixtures
- parity compare
- tolerance compare

## 7. 当前阶段的正确预期

当前 `brinson-core` 还没有真正替代 Python 算法，但已经完成了两个非常关键的基础建设：

- 把现网输出样例固化成了系统级 baseline
- 把未来迁移的目标边界拆解清楚了

因此后续每一轮迁移都可以围绕一句话来推进：

“把某一段 Python 逻辑迁进 Rust，同时继续通过同一组 golden case。”
