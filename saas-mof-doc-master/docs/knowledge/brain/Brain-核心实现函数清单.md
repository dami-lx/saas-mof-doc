---
tags:
  - brain
  - function-inventory
  - refactor
status: draft
updated: 2026-03-27
---

# Brain 核心实现函数清单

## 1. 这份清单的用途

这份文档用于帮助未来重构时快速定位 `brain` 的关键入口文件和函数。

它不是完整 API 文档，而是“实现地图”。

## 2. API 入口文件

### 2.1 `main_service.py`

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/web_service/main_service.py`

说明：

- 几乎全部 `Resource` 类都定义在这里

代表性 Resource：

- `NavPerformance`
- `HoldingPerf`
- `RiskSummary`
- `AdvancedEquityAttribution`
- `AdvancedBondBrinsonAttribution`
- `TaskStatusGet`
- `HeartBeat`

### 2.2 `server.py`

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/web_service/server.py`

说明：

- 统一注册 API route

### 2.3 `server_v2.py`

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/web_service/server_v2.py`

说明：

- 少量新增接口注册

## 3. 任务入口文件

### 3.1 `task_mom.py`

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/parallel_compute/tasks/task_mom.py`

典型任务：

- `nav_perf`
- `history_scenario`
- `selection_timing`
- `market_analysis`
- `holding_index_calculator`
- `return_statistic`

### 3.2 `task_old_mom.py`

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/parallel_compute/tasks/task_old_mom.py`

说明：

- 旧任务链保留入口

### 3.3 `parallel_parent_task.py`

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/parallel_compute/tasks/parallel_parent_task.py`

关键任务：

- `advanced_bond_brinson`
- `advanced_bond_campisi`
- `advanced_equity_attribution`
- `equity_attribution_trend`
- `equity_invest_style_attribution`
- `hk_return_brinson`
- `asset_level_brinson`
- `normalized_advanced_equity_attribution`
- `holding_contribution`
- `fund_nav_style_analysis_rolling`

## 4. 并行算法关键实现

### 4.1 股票归因并行实现

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/portfolio_management/parallel_algorithm_unit/optimized/equity_parallel.py`

关键类：

- `ParallelEquityAttribution`
- `ParallelEquityAttributionTrend`
- `ParallelEquityHoldingStyleAttribution`

### 4.2 股票归因子任务

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/portfolio_management/parallel_algorithm_unit/parallel_tasks/equity.py`

关键任务：

- `sub_advanced_equity_attribution`
- `sub_equity_invest_style_attribution`
- `accumulate_advanced_equity_attribution`
- `accumulate_equity_attribution_trend`
- `accumulate_equity_invest_style_attribution`

### 4.3 债券/混合并行实现

文件：

- `optimized/bond_parallel.py`
- `parallel_tasks/bond.py`
- `parallel_tasks/hybrid.py`

## 5. 业务算法单元关键实现

主要位于：

- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/portfolio_management/algorithm_unit`

重点子目录：

- `holding_attr`
- `nav_attr`
- `performance`
- `stress_test`
- `rebalance`
- `financial_calculator`

代表性类包括：

- `AdvancedEquityAttribution`
- `NormalizedAdvancedEquityAttribution`
- `AdvancedBondBrinsonAttribution`
- `AdvancedBondCampisiAttribution`
- `AssetLevelBrinsonAttribution`
- `NavPerformanceAnalysis`
- `SimulationBacktestAnalysis`

## 6. 数据加载关键实现

### 6.1 统一外观

- `data_loader/stock.py`
- `data_loader/risk_model.py`
- `data_loader/benchmark.py`

### 6.2 Redis

- `data_loader/brain_redis/stock.py`
- `data_loader/brain_redis/risk_model.py`
- `data_loader/brain_redis/benchmark.py`

### 6.3 MySQL

- `data_loader/dy_mysql/*`

### 6.4 Oracle

- `data_loader/dy_oracle/*`

## 7. 配置与工具入口

### 7.1 配置

- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/utils/cfg.py`

### 7.2 性能与监控工具

- `tools_api/performance_stat.py`
- `tools_api/monitor_tool.py`

## 8. 使用建议

如果是排查某个 endpoint：

1. 先查 `server.py`
2. 再看 `main_service.py` 对应 Resource
3. 再看对应 task
4. 再进入 `portfolio_management`
5. 最后补看 `data_loader`

如果是做系统重构：

1. 先按这份清单识别入口和边界
2. 再按知识库专题理解职责

## 9. 一句话结论

这份清单的核心价值是帮助后续把 `brain` 从“看起来是一堆接口”还原成“分层清晰的计算服务”。
