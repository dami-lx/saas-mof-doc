---
tags:
  - brain
  - api
  - endpoint
  - refactor
status: draft
updated: 2026-03-27
---

# Brain API 层与端点分类

## 1. API 入口文件

`brain` 的 API 注册主要集中在两个文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/web_service/server.py`
- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/web_service/server_v2.py`

Resource 实现主要位于：

- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/web_service/main_service.py`
- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/web_service/tools_service.py`

## 2. API 层的结构特点

### 2.1 注册集中

几乎全部 endpoint 都在 `server.py` 一次性注册。

这意味着：

- 很容易看到“全量接口面”
- 但也意味着 API 面过于集中，不利于按领域拆分

### 2.2 Resource 极薄

大部分 `Resource` 只是：

- 收参数
- 创建 Celery 任务
- 返回 `task_id`

这意味着 API 层主要承担协议适配，不承担核心业务逻辑。

### 2.3 存在两个版本入口

- 主入口仍以 `server.py` 为主
- `server_v2.py` 只承载少量新增接口

说明：

- 当前版本化策略比较轻
- 更像增量追加，而不是系统化的 API versioning

## 3. 端点分类

以下分类是从 `server.py` 注册语义整理出来的“领域视角分类”，不是源码目录分类。

### 3.1 系统与运维类

接口包括：

- `/`
- `/refresh_calendar`
- `/api/perf_stat`
- `/heartbeat`
- `/available_heartbeat`
- `/api/check_redis`
- `/api/check_dydb`
- `/api/update_redis`
- `/api/update_redis/benchmark`
- `/api/encrypt`
- `/api/mq_ready_tasks`
- `/api/clear_mq_tasks`
- `/1.0/collect/brain_error_log`

特点：

- 主要服务于诊断、监控、缓存刷新和工具能力

### 3.2 任务相关接口

接口包括：

- `/api/task/<task_id>`
- `/status/<task_id>`
- `/api/task/cancel/<task_id>`
- `/api/task_args/<task_id>`
- `/api/task_args_mongo/<task_id>`
- `/api/task_test`

特点：

- 支撑异步任务查询、撤销、入参回溯

### 3.3 净值表现与通用绩效类

接口包括：

- `/api/analysis/nav_perf`
- `/api/nav_perf`
- `/api/multi_nav_perf`
- `/api/period_multi_nav_perf`
- `/api/simulate_portfolio/nav_perf`
- `/api/common/nav_performance_overview`
- `/api/common/risk_summary`
- `/api/common/account_brief_summary`
- `/api/common/risk_free_performance`
- `/api/common/rolling_annual_return`
- `/api/common/return_statistic`

特点：

- 主要是净值/收益/风险表现分析

### 3.4 持仓绩效与贡献类

接口包括：

- `/api/analysis/holding_perf`
- `/api/2.0/holding_perf`
- `/api/holding_perf`
- `/api/common/holding_performance`
- `/api/common/holding_return_contribution`
- `/api/holding_industry_contribution`
- `/api/holding_style_contribution`

特点：

- 同时存在旧接口、新接口和列表页专用接口
- 命名较历史化

### 3.5 风格、归因与基金分析类

接口包括：

- `/api/analysis/attr_perf`
- `/2.0/api/analysis/attr_perf`
- `/api/equity/industry_attr_perf`
- `/api/equity/style_factor_attr_perf`
- `/api/common/style_attr`
- `/api/common/style_attr_rolling`
- `/api/fama_french`
- `/api/SelectionTimingAnalysis`
- `/api/SelectionTimingAnalysisTs`
- `/api/self/SelectionTimingAnalysis`
- `/api/self/SelectionTimingAnalysisTs`
- `/api/managerAnalysis`
- `/api/CompanyAnalysis`

特点：

- 既有净值归因，也有持仓归因前置分析、经理分析和公司分析

### 3.6 风险与 VAR 类

接口包括：

- `/api/analysis/holding_value_at_risk`
- `/api/fof_self/holding_value_at_risk`
- `/api/common/holding_value_at_risk`
- `/api/common/holding_value_at_risk_rolling`
- `/api/holding_var`
- `/api/common/value_at_risk_ts`
- `/api/analysis/fof_risk_exposure`
- `/api/fof_self/fof_risk_exposure`

特点：

- 旧接口与新接口并存

### 3.7 压力测试与情景分析类

接口包括：

- `/api/stress_test/history_scenario`
- `/api/stress_test/equity_history_scenario`
- `/api/stress_test/hypothetical_index_scenario`
- `/api/stress_test/hypothetical_factor_scenario`
- `/api/stress_test/bond_infer`
- `/api/stress_test/bond`
- `/api/bond/bp_stress_test`

### 3.8 资产配置与优化类

接口包括：

- `/api/rebalance/simulation`
- `/api/major_asset_allocation/rebalance`
- `/api/sub_asset_class_allocation/rebalance`
- `/api/major_asset_allocation/efficient_frontier`
- `/api/equity_optimizer`
- `/api/equity_efficient_frontier`
- `/api/factor_risk`
- `/2.0/api/factor_risk`
- `/api/analysis/asset_filter`

### 3.9 股票相关分析类

接口包括：

- `/api/equity/invest_style`
- `/api/equity/current_invest_style`
- `/api/equity/trade_info`
- `/api/equity/advanced_attribution`
- `/api/equity/attribution_trend`
- `/api/equity/invest_style_attribution`
- `/api/equity/hk_brinson`
- `/api/equity/hk_contribution`
- `/api/equity/normalized_attribution`
- `/api/industry`

### 3.10 债券相关分析类

接口包括：

- `/api/bond/bond_category_distribution`
- `/api/bond/current_category_distribution`
- `/api/bond/current_rate_category_distribution`
- `/api/bond/current_credit_category_distribution`
- `/api/bond/current_duration_yield`
- `/api/bond/current_category_duration_distribution`
- `/api/bond/future_bond_cashflow`
- `/api/bond/turn_over_ts`
- `/api/bond/bond_perf`
- `/api/bond/get_type`
- `/api/bond/dv01`
- `/api/bond/duration`
- `/api/bond/advanced_brinson`
- `/api/bond/advanced_campisi`
- `/api/bond/trans_attribution`
- `/api/bond/normalized_advanced_brinson`
- `/api/bond/normalized_advanced_campisi`
- `/api/bond/rating_distribution`
- `/api/bond_valuation`
- `/api/multi_bond_valuation`
- `/api/bond_ai`
- `/api/bond/duration_ytm_analysis`

### 3.11 混合与 FOF 相关类

接口包括：

- `/api/fof/sub_fund_attribution`
- `/api/common/asset_level_brinson`
- `/api/fof/strategy_info`
- `/api/fof_self/holding_perf`

### 3.12 市场与工具分析类

接口包括：

- `/api/corr`
- `/2.0/theme/fund/correlation`
- `/api/navFit`
- `/api/index_nav_fit`
- `/api/stock_index_nav_fit`
- `/api/cbond_index_nav_fit`
- `/api/industry_prosperity_to_return`
- `/api/benchmark_rebalance`
- `/api/index_compose`
- `/api/market_analysis`
- `/api/return_concat_by_market`
- `/api/invisible_trade_capability`
- `/api/partition_analysis`
- `/api/id_to_ticker`
- `/api/ticker_to_id`

## 4. API 层的设计特征

### 4.1 历史接口与新版接口并存

例如：

- `holding_perf`
- `holding_perf_v2`
- `attr_perf`
- `attr_perf_v2`

说明：

- 当前 API 面不是一次性重建出来的
- 而是在长期演进中逐步叠加形成的

### 4.2 endpoint 命名带有历史包袱

例如：

- `ReturnBondFundStyleAnalysis`
- `SelectionTimingAnalysis`
- `CompanyAnalysis`

新旧命名风格不统一，反映出系统演化跨度较大。

### 4.3 分类边界并不完全整洁

例如：

- `/api/common/*`
- `/api/analysis/*`
- `/api/equity/*`
- `/api/bond/*`

这些路径有时按资产类别分，有时按分析类型分。

## 5. `server_v2.py` 的意义

`server_v2.py` 目前只补了少量接口：

- `AttributionPerfV2`
- `StyleFactorWithRisk2`
- `CalculateCorrelation`
- `BrainErrorlogs`

这说明它更像：

- 新接口增量注册文件

而不是完整的第二代 API 框架。

## 6. 重构建议

如果未来要重构 API 层，建议按以下方式重分类：

### 6.1 System API

- heartbeat
- task
- mq
- redis tools

### 6.2 Performance API

- nav performance
- holding performance
- return statistics

### 6.3 Attribution API

- equity attribution
- bond attribution
- hybrid attribution
- nav attribution

### 6.4 Risk API

- var
- risk summary
- factor risk
- stress test

### 6.5 Allocation API

- rebalance
- optimizer
- efficient frontier

### 6.6 Market Tooling API

- correlation
- id mapping
- index compose
- market analysis

## 7. 一句话结论

`brain` 的 API 层功能很全，但当前更像“历史演进后的统一出口”，而不是按清晰领域边界设计的一套 API 产品。
