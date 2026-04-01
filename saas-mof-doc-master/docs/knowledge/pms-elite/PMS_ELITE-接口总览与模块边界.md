---
tags:
  - pms
  - api
  - architecture
  - refactor
status: draft
updated: 2026-03-27
---

# PMS_ELITE 接口总览与模块边界

## 1. 入口路由结构

总路由定义位于：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/api/urls.py`

服务采用版本前缀模式：

- `/v1/...`
- `/v2/...`

顶层模块包括：

- `help`
- `monitor`
- `portfolio`
- `position`
- `transaction`
- `delivery`
- `refresh`
- `task`

## 2. 总体分层

从源码结构看，`PMS_ELITE` 的接口分层比较稳定：

1. `lib/api/*/views.py`
   - 对外 HTTP 入口
   - 参数解析
   - 版本分发
2. `lib/controller/*_service.py`
   - 模块 service
   - 业务编排
3. `lib/controller/position/*`
   - 持仓与 MOM/FOF 复杂逻辑
4. `lib/controller/transaction/*`
   - 交易记录组装与翻译
5. `lib/business/*`
   - 更底层业务逻辑
6. `lib/dao/*`
   - Mongo / Redis / data_sdk 访问

重构时建议把它理解为：

- `API Shell`
- `Application Service`
- `Domain Core`
- `Data Access`

## 3. 全量接口清单

### 3.1 `help`

基础路径：

- `/v1/help/*`
- `/v2/help/*`

接口：

- `GET /help/test`
- `GET /help/celery_test`
- `GET /help/exception`
- `DELETE /help/delete_portfolio`
- `POST /help/mongodb`
- `PUT /help/mongodb`
- `PATCH /help/mongodb`
- `DELETE /help/mongodb`

特点：

- 主要是测试、排障、数据修复、运维工具接口
- 高风险，不应被当成业务正式接口

### 3.2 `monitor`

基础路径：

- `/v1/monitor/*`
- `/v2/monitor/*`

接口：

- `GET /monitor/heartbeat`

特点：

- 中间件和底层依赖健康检查接口

### 3.3 `portfolio`

基础路径：

- `/v1/portfolio/*`
- `/v2/portfolio/*`

接口：

- `GET /portfolio/`
- `POST /portfolio/`
- `PUT /portfolio/`
- `DELETE /portfolio/`
- `POST /portfolio/portfolio_list`
- `POST /portfolio/mom_list`
- `POST /portfolio/search_position`
- `POST /portfolio/search_transaction`
- `POST /portfolio/aggregate_position`
- `GET /portfolio/indicator`
- `POST /portfolio/indicator`
- `POST /portfolio/status`
- `POST /portfolio/task`

特点：

- 组合主数据入口
- 查询能力较多
- 同时混入了指标查询、任务查询、组合聚合检索

### 3.4 `position`

基础路径：

- `/v1/position/*`
- `/v2/position/*`

接口：

- `GET /position/position_composition`
- `GET /position/position_calendar`
- `GET /position/mom_calendar`
- `GET /position/position_trend`

特点：

- 持仓查询模块
- 是整个服务最重的业务核心
- 内含穿透、层级、虚母虚子、FOF 透视、实时估值

### 3.5 `transaction`

基础路径：

- `/v1/transaction/*`
- `/v2/transaction/*`

接口：

- `GET /transaction/record`

特点：

- 交易记录查询入口
- 看起来简单，但内部也包含组合交易记录组装逻辑

### 3.6 `delivery`

基础路径：

- `/v1/delivery/*`
- `/v2/delivery/*`

接口：

- `POST /delivery/`
- `DELETE /delivery/`
- `POST /delivery/task`
- `POST /delivery/revoke`
- `POST /delivery/evaluate`
- `POST /delivery/transaction`
- `POST /delivery/group`
- `DELETE /delivery/group`

特点：

- 数据导入与估值触发入口
- 任务驱动
- 会修改业务数据

### 3.7 `refresh`

基础路径：

- `/v1/refresh/*`
- `/v2/refresh/*`

接口：

- `POST /refresh/`

特点：

- 面向缓存和派生数据刷新
- 本质是任务触发接口

### 3.8 `task`

基础路径：

- `/v1/task/*`
- `/v2/task/*`

接口：

- `POST /task/`
- `GET /task/`

特点：

- 通用任务查询接口

## 4. 模块职责划分

### 4.1 业务核心模块

- `portfolio`
- `position`
- `transaction`

这些模块直接服务于组合管理、持仓分析和交易查询。

### 4.2 作业与任务模块

- `delivery`
- `refresh`
- `task`

这些模块负责：

- 导入标准化数据
- 触发估值/刷新
- 查询和撤销任务

### 4.3 运维与工具模块

- `monitor`
- `help`

这些模块主要面向：

- 健康检查
- 调试
- 数据修复
- 硬删除和 Mongo 运维

## 5. 接口到 Service 的映射

`lib/api/base.py` 中定义了资源类和 service 的绑定关系：

- `PortfolioResource -> PortfolioService`
- `PositionResource -> PositionService`
- `TransactionResource -> TransactionService`
- `DeliveryResource -> DeliveryService`
- `IndicatorResource -> IndicatorService`
- `RefreshResource -> RefreshService`
- `TaskResource -> TaskService`
- `MonitorResource -> MonitorService`
- `HelpResource -> HelpService`

这说明：

- `views` 层比较薄
- 真实的模块语义集中在 `*_service.py`

## 6. 当前最关键的业务模块

### 6.1 `position`

最重要原因：

- 它不只是持仓查询
- 它承载了复杂的组合透视能力

核心实现包括：

- `PortfolioPositionComposition`
- `MomData`
- `FoFPerspective`
- `PositionTrend`
- `PositionCompositionTranslator`

### 6.2 `portfolio`

重要原因：

- 这里承担组合主数据管理
- 同时承载组合级搜索、聚合和指标明细拼装

### 6.3 `delivery`

重要原因：

- 这是写入链和异步任务链的入口
- 后续如果拆服务，通常会最先被分出去

## 7. 重构时建议优先拆分的边界

### 7.1 `Portfolio Master`

包含：

- 组合创建
- 组合修改
- 组合删除
- 组合详情

### 7.2 `Position Query Engine`

包含：

- 持仓组合
- 穿透视角
- 位置日历
- 持仓趋势

### 7.3 `Indicator Engine`

包含：

- 组合指标查询
- 指标补算
- 净值/份额/净资产摘要值

### 7.4 `Task Orchestration`

包含：

- delivery
- refresh
- task query
- revoke

### 7.5 `Ops Tooling`

包含：

- help
- monitor

这些应和正式业务接口隔离，避免未来继续耦合。

## 8. 一句话结论

`PMS_ELITE` 并不是单纯的“组合系统 API”，而是一个把组合主数据、持仓透视、指标补算、导入任务和运维工具混合在一起的综合服务。

未来重构时，第一步不应是直接换语言，而应先把这些职责边界拆清楚。
