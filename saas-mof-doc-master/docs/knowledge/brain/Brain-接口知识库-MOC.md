---
tags:
  - brain
  - api
  - moc
  - refactor
status: active
updated: 2026-03-28
---

# Brain 接口知识库 MOC

## 1. 这组文档的用途

这组文档用于把 `mercury-brain` 的 API 层、任务编排层、数据加载层和本地算法依赖边界沉淀成长期知识库。

这套知识库主要服务于两个目标：

1. 让后续阅读者快速理解 `brain` 到底是什么系统。
2. 为未来重构、拆分服务、异语言迁移提供结构化底稿。

## 2. 阅读入口

### 2.1 总览

- [Brain 模块总览与边界](./Brain-模块总览与边界.md)

### 2.2 专题文档

- [Brain API 层与端点分类](./Brain-API层与端点分类.md)
- [Brain 任务编排与执行链](./Brain-任务编排与执行链.md)
- [Brain Celery 队列与任务状态存储专题](./Brain-Celery队列与任务状态存储专题.md)
- [Brain 数据加载层与外部依赖](./Brain-数据加载层与外部依赖.md)
- [Brain 风险模型数据专题](./Brain-风险模型数据专题.md)
- [Brain 真实环境连通与数据源探测（2026-03-28）](./Brain-真实环境连通与数据源探测-2026-03-28.md)
- [Brain 本地依赖包边界：mars solar saturn](./Brain-本地依赖包边界-mars-solar-saturn.md)
- [Brain 核心实现函数清单](./Brain-核心实现函数清单.md)

### 2.3 接口重构专题

- [Brain holding_return_contribution 接口分析](./Brain-holding_return_contribution接口分析.md)
- [Holding Return Contribution 重构分析](./Holding-Return-Contribution-重构分析.md)

### 2.4 典型前端功能案例

- [A股风格归因卡片项目实现与排查说明](../前端模块链路/A股风格归因卡片-项目实现与排查说明.md)
- [A股风格归因卡片字段字典](../前端模块链路/A股风格归因卡片-字段字典.md)
- [A股风格归因卡片 FAQ 与常见误解](../前端模块链路/A股风格归因卡片-FAQ与常见误解.md)
- [A股风格归因卡片 Case 排查模板](../前端模块链路/A股风格归因卡片-Case排查模板.md)
- [A股行业归因卡片项目实现与排查说明](../前端模块链路/A股行业归因卡片-项目实现与排查说明.md)
- [A股行业归因卡片字段字典](../前端模块链路/A股行业归因卡片-字段字典.md)
- [A股行业归因卡片 FAQ 与常见误解](../前端模块链路/A股行业归因卡片-FAQ与常见误解.md)
- [A股行业归因卡片 Case 排查模板](../前端模块链路/A股行业归因卡片-Case排查模板.md)
- [业绩总览卡片项目实现与排查说明](../前端模块链路/业绩总览卡片-项目实现与排查说明.md)
- [业绩总览卡片字段字典](../前端模块链路/业绩总览卡片-字段字典.md)
- [业绩总览卡片 FAQ 与常见误解](../前端模块链路/业绩总览卡片-FAQ与常见误解.md)
- [业绩总览卡片 Case 排查模板](../前端模块链路/业绩总览卡片-Case排查模板.md)

## 3. 推荐阅读顺序

### 3.1 如果目标是快速了解系统

1. [Brain 模块总览与边界](./Brain-模块总览与边界.md)
2. [Brain API 层与端点分类](./Brain-API层与端点分类.md)
3. [Brain 任务编排与执行链](./Brain-任务编排与执行链.md)
4. [Brain Celery 队列与任务状态存储专题](./Brain-Celery队列与任务状态存储专题.md)

### 3.2 如果目标是做系统重构

1. [Brain 模块总览与边界](./Brain-模块总览与边界.md)
2. [Brain 任务编排与执行链](./Brain-任务编排与执行链.md)
3. [Brain Celery 队列与任务状态存储专题](./Brain-Celery队列与任务状态存储专题.md)
4. [Brain 数据加载层与外部依赖](./Brain-数据加载层与外部依赖.md)
5. [Brain 风险模型数据专题](./Brain-风险模型数据专题.md)
6. [Brain 真实环境连通与数据源探测（2026-03-28）](./Brain-真实环境连通与数据源探测-2026-03-28.md)
7. [Brain 本地依赖包边界：mars solar saturn](./Brain-本地依赖包边界-mars-solar-saturn.md)
8. [Brain API 层与端点分类](./Brain-API层与端点分类.md)

## 4. 当前已确认的核心结论

- `brain` 不是单纯的“算法库 HTTP 外壳”，而是一个“API 壳 + Celery 任务编排 + 数据加载 + 算法适配”的综合计算服务。
- 对外 API 几乎都统一汇聚在 `lib/web_service/main_service.py` 与 `lib/web_service/server.py`。
- 绝大多数业务接口都不是同步直接返回结果，而是创建 Celery 任务，再通过任务状态接口取结果。
- `parallel_compute/tasks/task_mom.py` 和 `parallel_compute/tasks/parallel_parent_task.py` 是两条主要任务入口链：
  - 普通任务链
  - 并行归因任务链
- `data_loader` 是 `brain` 的核心基础层，统一封装 Redis、MySQL、Oracle、Mongo 等底层数据访问。
- `brain` 自身并不实现全部数学算法，它大量依赖本地源码包：
  - `mars`
  - `solar`
  - `saturn`

## 5. 当前已覆盖的边界

本轮文档已经覆盖：

- API 注册入口
- Resource 与任务函数映射
- 任务编排主链
- Celery 队列、参数存储与结果状态链
- 数据加载封装结构
- 风险模型缓存与算法输入契约
- 本地依赖包边界

尚未深入的部分：

- 每个 endpoint 的入参 schema 逐项梳理
- `controller` 与 `analysis` 目录的全部功能细节
- `workers` 和队列配置的运维策略
- 每个算法单元内部的数学细节

## 6. 后续建议补充的专题

1. `Brain API 入参模型专题`
2. `Brain 算法单元专题`
3. `Brain endpoint 全量清单专题`
