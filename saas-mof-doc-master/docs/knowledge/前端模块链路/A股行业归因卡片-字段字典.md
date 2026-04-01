---
tags:
  - invested
  - ams
  - attribution
  - industry
  - dictionary
status: active
updated: 2026-03-31
---

# A股行业归因卡片字段字典

## 1. 文档用途

这份字段字典用于统一 `A股行业归因` 卡片的字段语义和业务概念。

配套文档：

- [A股行业归因卡片客户业务说明](./A股行业归因卡片-客户业务说明.md)
- [A股行业归因卡片项目实现与排查说明](./A股行业归因卡片-项目实现与排查说明.md)

## 2. 页面层字段

| 字段 / 概念 | 含义 | 备注 |
| --- | --- | --- |
| `stockIndustryAttr` | 卡片唯一标识 | 前端 card key / independent key |
| `显示年化值` | 切换年化 / 非年化显示 | 影响收益、风险和权重字段选择 |
| `行业分类` | 行业归因分类体系 | 当前前端常见为 `ZJ_1` / `ZJ_2` |
| `主动收益` | 相对基准的行业收益贡献 | 行业管理收益口径 |
| `主动风险` | 相对基准的行业风险贡献 | 行业管理风险口径 |
| `主动权重` | 相对基准的行业权重偏离 | `组合行业权重 - 基准行业权重` |

## 3. 前端对象字段

| 字段 | 含义 | 备注 |
| --- | --- | --- |
| `industryBenchmark` | 行业归因展示列表 | 名字里虽然有 `Benchmark`，但它表示主动行业结果 |
| `industry` | 前端派生出的兼容结构 | 给部分老结构或导出使用 |
| `custom.industryType` | 当前行业分类 | 如 `ZJ_1`、`ZJ_2` |
| `custom.penetrateType` | 当前穿透方式 | 页面切换会触发 reload |

## 4. `industryBenchmark` 单项字段

| 字段 | 含义 | 备注 |
| --- | --- | --- |
| `name` | 行业名称 | 当前分类体系下的行业名 |
| `return` | 年化主动收益 | 行业管理收益口径 |
| `deannualReturn` | 非年化主动收益 | 行业管理收益口径 |
| `risk` | 年化主动风险 | 行业管理风险口径 |
| `deannualRisk` | 非年化主动风险 | 行业管理风险口径 |
| `weight` | 年化主动权重 | 行业主动权重展示值 |
| `deannualWeight` | 非年化主动权重 | 行业主动权重展示值 |
| `factorType` | 因子类型 | 当前卡片里通常是行业相关展示 |

## 5. 前端字段选择规则

| 页面状态 | 收益字段 | 风险字段 | 权重字段 |
| --- | --- | --- | --- |
| 年化 | `return` | `risk` | `weight` |
| 非年化 | `deannualReturn` | `deannualRisk` | `deannualWeight` |

## 6. `mom` / `brain` 中间字段

| 字段 | 所在层 | 含义 |
| --- | --- | --- |
| `summaryStyles` | `mom` 返回 | 行业归因卡片最终展示列表 |
| `brinson_industry_attr` | `brain` 返回 | 行业卡片直接消费的底表 |
| `accum_brinson_industry_attr` | `brain` 返回 | 更细的累计行业 Brinson 结果，含 allocation / selection / other 等字段 |
| `active_return` | `brain/mars` | 主动收益结果 |
| `active_risk` | `brain/mars` | 主动风险结果 |
| `active_weight` | `brain/mars` | 主动权重结果 |

## 7. Brinson 关键术语

| 术语 | 含义 | 对应中文 |
| --- | --- | --- |
| `sector_allocation` | Allocation | 配置收益 / 配置风险 |
| `equity_selection` | Selection | 选股收益 / 选股风险 |
| `interaction` | Interaction | 交互收益 / 交互风险 |
| `timing_return` | Timing Return | 择时收益 |
| `timing_risk` | Timing Risk | 择时风险 |
| `management` | Management | 行业管理部分，通常指配置 + 选股 + 交互 |

## 8. 行业权重和收益符号

| 符号 | 含义 |
| --- | --- |
| `W_p,i` | 组合在行业 `i` 的权重 |
| `W_b,i` | 基准在行业 `i` 的权重 |
| `W_a,i` | 行业主动权重，`W_p,i - W_b,i` |
| `R_p,i` | 组合在行业 `i` 的收益 |
| `R_b,i` | 基准在行业 `i` 的收益 |

## 9. 展示层重要规则

| 规则 | 含义 |
| --- | --- |
| 主动收益总和 | 当前行业列表收益直接求和 |
| 主动风险总和 | 当前行业列表风险直接求和 |
| 主动权重总和 | 当前行业列表权重直接求和 |
| 行业条目收益 | `allocation + selection + interaction` |
| 行业条目风险 | 管理风险拆分后的行业合计 |
| 行业条目不含 | `timing` 单独分摊值 |

## 10. 最重要的记忆点

- `industryBenchmark` 不是基准自身，而是主动行业归因列表。
- 行业条目展示的是管理贡献，不直接展示 timing。
- 行业分类切换不仅改名字，也会改结果。
- 顶部总和来自前端对当前列表直接求和。
