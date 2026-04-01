---
tags:
  - pms
  - portfolio
  - api
  - refactor
status: draft
updated: 2026-03-27
---

# PMS_ELITE Portfolio 模块专题

## 1. 模块定位

`portfolio` 模块是 `PMS_ELITE` 的组合主数据入口，但它不只是做 CRUD。

它还承担：

- 组合详情查询
- 组合列表批量查询
- 组合状态查询
- 组合任务查询
- 基于持仓和交易反查组合
- 聚合持仓搜索
- 指标查询子入口

相关总览：

- [PMS_ELITE 接口总览与模块边界](./PMS_ELITE-接口总览与模块边界.md)

## 2. 路由与接口清单

路由定义：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/api/portfolio/urls.py`

视图实现：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/api/portfolio/views.py`
- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/api/portfolio/indicator/views.py`

服务实现：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/portfolio_service.py`
- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/indicator_service.py`

## 3. 接口逐项说明

### 3.1 `GET /portfolio/`

视图：

- `PortfolioView.get`

服务：

- `PortfolioService.get_portfolio_detail`

功能：

- 查询单个组合详情
- 可选附带组合指标摘要

如果 `with_indicator=true`，会额外：

- 调 `get_portfolio_indicators(...)`
- 计算 `total_portfolio_profit`
- 计算 `total_portfolio_profit_rate_nav`
- 读取当日现金划转交易以修正利润

这意味着：

- 这个接口不是单纯查组合主表
- 它会动态拼装组合详情和近期绩效指标

### 3.2 `POST /portfolio/`

视图：

- `PortfolioView.post`

服务：

- `PortfolioService.create_portfolio`
- `DeliveryService.portfolio_init_evaluate`

功能：

- 创建组合
- 创建后如果满足条件，自动触发初始化估值任务

这是一个非常重要的行为：

- 创建组合不只是落库，还会触发后续任务链

### 3.3 `PUT /portfolio/`

视图：

- `PortfolioView.put`

服务：

- `PortfolioService.modify_portfolio`

功能：

- 修改组合主数据

### 3.4 `DELETE /portfolio/`

视图：

- `PortfolioView.delete`

服务：

- `PortfolioService.delete_portfolio`

功能：

- 软删除组合

删除前会检查：

- 组合是否存在
- 是否已删除
- 是否仍被其他组合持有

所以它不是无条件删除。

### 3.5 `POST /portfolio/portfolio_list`

视图：

- `PortfolioListView.post`

服务：

- `PortfolioService.get_portfolio`

功能：

- 批量查询组合基本信息

### 3.6 `POST /portfolio/mom_list`

视图：

- `MomListView.post`

服务：

- `PortfolioService.get_portfolio`
- `TransactionService.mom_record`

功能：

- 返回组合基本信息
- 同时返回组合之间的持有关系记录

这个接口说明 `portfolio` 模块和 `transaction`、`mom_data` 存在交叉语义。

### 3.7 `POST /portfolio/search_position`

视图：

- `SearchPositionView.post`

服务：

- `PortfolioService.search_position`

底层 DAO：

- `search_portfolio_from_position(...)`

功能：

- 根据证券、日期、组合范围、模糊关键词等条件，反查有哪些组合持有该证券

### 3.8 `POST /portfolio/search_transaction`

视图：

- `SearchTransactionView.post`

服务：

- `PortfolioService.search_transaction`

底层 DAO：

- `search_portfolio_from_transaction(...)`

功能：

- 根据证券和日期等条件，反查哪些组合存在相关交易

### 3.9 `POST /portfolio/aggregate_position`

视图：

- `AggregatePositionView.post`

服务：

- `PortfolioService.aggregate_position`

底层 DAO：

- `aggregate_portfolio_from_position(...)`

功能：

- 聚合查询持仓
- 支持分页、排序、字段选择、模糊检索、日期过滤

特点：

- `v1` 与 `v2` 参数模型不同
- `v2` 更偏页面化查询

### 3.10 `GET /portfolio/indicator`

视图：

- `IndicatorView.get`

服务：

- `IndicatorService.calculate_indicator`

功能：

- 查询单组合一段时间内的指标

### 3.11 `POST /portfolio/indicator`

视图：

- `IndicatorView.post`

服务：

- `IndicatorService.calculate_indicator`

功能：

- 批量查询多个组合的指标

### 3.12 `POST /portfolio/status`

视图：

- `PortfolioStatusView.post`

服务：

- `PortfolioService.get_portfolio_status`

功能：

- 汇总组合相关任务状态

### 3.13 `POST /portfolio/task`

视图：

- `PortfolioTaskView.post`

服务：

- `PortfolioService.get_portfolio_task`

功能：

- 查询组合关联任务列表

## 4. 模块的实现重心

### 4.1 组合主数据

核心函数：

- `check_portfolio_data`
- `create_portfolio`
- `modify_portfolio`
- `get_portfolio`
- `get_portfolio_detail`
- `delete_portfolio`

这些函数围绕 `SchemaType.PORTFOLIO` 组织。

### 4.2 组合级查询

核心函数：

- `search_position`
- `search_transaction`
- `aggregate_position`

这些函数本质上是“组合反查与聚合检索层”。

### 4.3 组合级状态与任务

核心函数：

- `get_portfolio_status`
- `get_portfolio_task`

这些函数和任务系统紧密耦合。

## 5. Indicator 子模块的真实意义

虽然 URL 挂在 `portfolio` 下，但 `indicator` 其实是一个独立能力。

服务层：

- `IndicatorService.calculate_indicator`

底层核心：

- `get_portfolio_indicators(...)`

它不是简单查表，而是：

1. 先查 Mongo 的指标文档
2. 再结合 `get_portfolio_summary_values(...)` 补算

这也是为什么它应该在未来重构中被独立为 `Indicator Engine`。

## 6. 重构建议

### 6.1 建议保留在同一服务内的能力

- 组合主数据 CRUD
- 组合详情查询

### 6.2 建议拆分出去的能力

- `indicator`
- `aggregate_position`
- `search_position`
- `search_transaction`
- 任务状态聚合

原因：

- 它们都不是纯主数据能力
- 更像组合分析和检索能力

## 7. 一句话结论

`portfolio` 模块表面上是组合入口，实际上已经演化成“组合主数据 + 检索聚合 + 指标拼装 + 任务状态查询”的复合模块。
