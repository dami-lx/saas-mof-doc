---
tags:
  - pms
  - api
  - function-inventory
  - refactor
status: draft
updated: 2026-03-27
---

# PMS_ELITE 接口实现函数清单

## 1. 这份清单的用途

这份文档用于列出 `PMS_ELITE` 各 API 模块对应的主要实现函数，帮助后续在重构时快速定位“接口壳”和“真实逻辑”。

相关索引：

- [PMS_ELITE 接口知识库 MOC](./PMS_ELITE-接口知识库-MOC.md)

## 2. API Resource 到 Service 绑定

定义位置：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/api/base.py`

绑定关系：

- `PortfolioResource -> PortfolioService`
- `PositionResource -> PositionService`
- `TransactionResource -> TransactionService`
- `DeliveryResource -> DeliveryService`
- `IndicatorResource -> IndicatorService`
- `MonitorResource -> MonitorService`
- `RefreshResource -> RefreshService`
- `TaskResource -> TaskService`
- `HelpResource -> HelpService`

## 3. Service 层函数清单

### 3.1 `PortfolioService`

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/portfolio_service.py`

主要函数：

- `check_portfolio_data`
- `create_portfolio`
- `modify_portfolio`
- `get_portfolio`
- `get_portfolio_detail`
- `delete_portfolio`
- `search_position`
- `search_transaction`
- `aggregate_position`
- `get_portfolio_status`
- `get_portfolio_task`

### 3.2 `PositionService`

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/position_service.py`

主要函数：

- `position_composition`
- `has_position_cache_data`
- `position_calendar`
- `mom_calendar`
- `position_trend`

### 3.3 `TransactionService`

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/transaction_service.py`

主要函数：

- `get_transaction_record`
- `mom_record`

### 3.4 `DeliveryService`

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/delivery_service.py`

主要函数：

- `get_portfolio_task`
- `get_portfolio_to_evaluate`
- `async_delivery_each_portfolio`
- `sync_delivery_each_portfolio`
- `delivery_each_portfolio`
- `evaluate_portfolio`
- `portfolio_init_evaluate`
- `query_task`
- `check_task_conflict`
- `revoke_task`
- `delivery_group`
- `delete_delivery_group_transaction_data`
- `delete_delivery_data`

### 3.5 `RefreshService`

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/refresh_service.py`

主要函数：

- `get_portfolio_task`
- `get_portfolio_to_refresh`
- `async_refresh_each_portfolio`
- `sync_refresh_each_portfolio`
- `refresh_each_portfolio`
- `refresh_cache_data`

### 3.6 `IndicatorService`

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/indicator_service.py`

主要函数：

- `calculate_indicator`

### 3.7 `TaskService`

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/task_service.py`

主要函数：

- `query_task`

### 3.8 `MonitorService`

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/monitor_service.py`

主要函数：

- `get_heartbeat`

### 3.9 `HelpService`

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/help_service.py`

主要函数：

- `query_deleted_portfolio_list`
- `delete_data_from_mongodb`
- `delete_data_from_redis`
- `delete_portfolio_data`
- `combine_dict_count_data`
- `query_data_from_mongodb`
- `update_data_from_mongodb`
- `insert_data_from_mongodb`

## 4. Position 领域核心函数清单

### 4.1 `PortfolioPositionComposition`

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/position/position_composition.py`

主要函数：

- `position_composition`
- `_prepare_data`
- `_calculate_indicator`
- `_form_required_struct`
- `load_position_from_cache`
- `merge_hke_position`
- `page_position`

### 4.2 `FoFPerspective`

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/position/fof.py`

主要函数：

- `fof`
- `fof_perspective`
- `summary_fof_perspective`
- `mom_perspective`
- `fof_fund`
- `merge_positions`

### 4.3 `FoFLoader`

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/position/fof.py`

主要函数：

- `batch_load_data`
- `load_fund_report_data`
- `load_perspective_symbol_price_info`
- `load_perspective_symbol_asset_info`
- `load_fund_report_date_list`
- `load_trading_days`
- `load_private_asset_report_data`
- `get_price_and_daily_profit_rate`
- `get_asset_info`
- `get_fund_report`
- `get_private_asset_report`

### 4.4 `PositionTrend`

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/position/position_trend.py`

主要函数：

- `position_trend`
- `get_position_trend`
- `get_sample_date_list`
- `fill_amount_and_price`
- `fill_mom_price`

### 4.5 `PositionCompositionTranslator`

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/position/translators.py`

主要函数：

- `translate`
- `cash_translate`
- `merge_hke`
- `form_fund_holding_position`
- `form_fund_complementary_position`
- `merge_fof`
- `get_security_type`
- `translate_private_asset_position`
- `translate_private_asset_cash`

## 5. Transaction 领域核心函数清单

### 5.1 `PortfolioTransactionComposition`

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/transaction/transaction_composition.py`

主要函数：

- `transaction_composition`
- `page_transaction`
- `_prepare_data`
- `_calculate_indicator`
- `_form_required_struct`

### 5.2 `TransactionRecordTranslator`

文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/transaction/translators.py`

主要函数：

- `translate`

## 6. 使用建议

如果只是想理解接口用法，优先看各模块专题。

如果要做重构、拆服务或异语言迁移，优先拿这份函数清单反查核心实现。
