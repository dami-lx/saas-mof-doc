---
tags:
  - pms
  - delivery
  - refresh
  - task
  - celery
  - refactor
status: draft
updated: 2026-03-27
---

# PMS_ELITE Delivery Refresh Task 模块专题

## 1. 模块定位

这三个模块共同构成了 `PMS_ELITE` 的任务编排层：

- `delivery`
- `refresh`
- `task`

其中：

- `delivery` 偏写入和估值触发
- `refresh` 偏缓存/派生结果刷新
- `task` 偏任务状态查询

## 2. Delivery 模块

### 2.1 接口清单

路由：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/api/delivery/urls.py`

视图：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/api/delivery/views.py`

服务：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/delivery_service.py`

接口：

- `POST /delivery/`
- `DELETE /delivery/`
- `POST /delivery/task`
- `POST /delivery/revoke`
- `POST /delivery/evaluate`
- `POST /delivery/transaction`
- `POST /delivery/group`
- `DELETE /delivery/group`

### 2.2 `POST /delivery/`

功能：

- 标准化数据导入 PMS 的主入口

特点：

- 要求 `delivery_data` 或 `batch_ids` 至少传一个
- 会先检查任务冲突
- 默认走异步任务

### 2.3 `DELETE /delivery/`

功能：

- 删除指定组合、时间区间、集合类型的导入数据

### 2.4 `POST /delivery/task`

功能：

- 批量查询导入任务状态

### 2.5 `POST /delivery/revoke`

功能：

- 撤销未完成任务

### 2.6 `POST /delivery/evaluate`

功能：

- 批量触发组合估值/推导流程

### 2.7 `POST /delivery/transaction`

功能：

- 同步导入单组合交易数据

特点：

- 这里显式设置了 `async_task=False`

### 2.8 `POST /delivery/group`

功能：

- 导入 group 组合层的权重/交易型数据

特点：

- 会校验父组合必须是 `GROUP`
- 会构造交易映射并生成任务

### 2.9 `DELETE /delivery/group`

功能：

- 删除 group 组合导入的交易数据

## 3. DeliveryService 的核心职责

### 3.1 任务创建与分发

核心函数：

- `async_delivery_each_portfolio`
- `sync_delivery_each_portfolio`
- `delivery_each_portfolio`

它们负责：

- 创建 `TaskSchema`
- 分发 Celery 任务
- 处理同步/异步两种模式

### 3.2 任务冲突控制

核心函数：

- `check_task_conflict`
- `revoke_task`

特点：

- 基于 Redis 锁与任务状态控制并发
- 支持超时撤销

### 3.3 初始化估值

核心函数：

- `portfolio_init_evaluate`
- `evaluate_portfolio`

含义：

- 新建组合后会自动触发估值任务
- 说明导入与估值不是割裂的两条链

## 4. Refresh 模块

### 4.1 接口

路由：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/api/refresh/urls.py`

接口：

- `POST /refresh/`

服务：

- `RefreshService.refresh_cache_data`

### 4.2 功能定位

它不是普通查询接口，而是：

- 针对 `GROUP` / `SUB_ACCOUNT`
- 触发缓存和派生数据刷新任务

### 4.3 核心职责

- 筛出允许刷新的组合
- 创建刷新任务
- 走异步或同步刷新执行链

## 5. Task 模块

### 5.1 接口

路由：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/api/task/urls.py`

接口：

- `POST /task/`
- `GET /task/`

服务：

- `TaskService.query_task`

功能：

- 通用任务查询

这是最薄的一层，但它在整个异步体系里是统一出口。

## 6. 重构建议

建议未来把这三个模块统一抽象为：

### 6.1 Job API

- 创建任务
- 查询任务
- 撤销任务

### 6.2 Domain Job Types

- delivery job
- evaluate job
- refresh job

### 6.3 Conflict Control

- 锁
- 并发策略
- 超时撤销

这样会比目前按 URL 模块切更清晰。

## 7. 一句话结论

`delivery / refresh / task` 三个模块共同构成了 `PMS_ELITE` 的任务编排系统，是重构时最适合单独抽象出来的一层。
