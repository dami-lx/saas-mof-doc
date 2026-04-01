---
tags:
  - brain
  - architecture
  - refactor
status: draft
updated: 2026-03-27
---

# Brain 模块总览与边界

## 1. brain 是什么

`brain` 是整个系统中的计算中枢。

它对外表现为一个 HTTP API 服务，但内部实际由 4 层能力组合而成：

1. `web_service`
   - HTTP API 入口
2. `parallel_compute`
   - Celery 任务编排
3. `portfolio_management`
   - 业务计算单元
4. `data_loader`
   - 底层数据加载

因此，`brain` 不是“算法包”，也不是“单一微服务逻辑”，而是一个完整的计算服务。

## 2. 目录级模块结构

`lib/` 目录下最重要的模块包括：

- `web_service`
- `parallel_compute`
- `portfolio_management`
- `data_loader`
- `analysis`
- `controller`
- `dao`
- `tools_api`
- `utils`

### 2.1 `web_service`

作用：

- 对外暴露 Flask-RESTful Resource
- 承担 API 注册和请求入口

### 2.2 `parallel_compute`

作用：

- Celery 配置
- 任务入口函数
- 并行/串行调度

### 2.3 `portfolio_management`

作用：

- 业务算法单元
- 输入装配
- 计算模型
- 并行算法实现

### 2.4 `data_loader`

作用：

- 统一封装 Redis、MySQL、Oracle、Mongo 等底层数据访问

### 2.5 `analysis / controller / tools_api`

作用：

- 一些分析型辅助能力
- 控制层逻辑
- 监控与性能统计工具

## 3. brain 的总体工作方式

大多数业务接口的典型流程是：

1. HTTP 请求进入 `Resource.post()` 或 `Resource.get()`
2. `Resource` 读取请求 JSON
3. 构造 Celery task signature
4. 异步提交任务
5. 立即返回 `task_id`
6. 真正计算在 Celery worker 内完成
7. 调用任务状态接口获取结果

这个工作方式意味着：

- `brain` 默认是“异步计算服务”
- API 层更多是任务发起器，而不是业务计算实现本身

## 4. 两条核心任务链

### 4.1 普通任务链

主要入口：

- `parallel_compute/tasks/task_mom.py`
- `parallel_compute/tasks/task_old_mom.py`

特点：

- 大量分析、绩效、风格、压力测试、市场分析类接口都走这条链

### 4.2 并行归因链

主要入口：

- `parallel_compute/tasks/parallel_parent_task.py`

特点：

- 主要承接新版持仓归因类任务
- 对于股票、债券、混合资产归因，负责选择并行或串行实现

## 5. API 不是直接调用算法

从 `main_service.py` 可以看到，绝大多数 `Resource` 的实现模式都非常相似：

1. `recv_data = _get_request_json()`
2. `task_s = 某个任务函数.s(recv_data)`
3. `task = task_s.apply_async(...)`
4. `return {'task_id': task.id}`

说明：

- API 层极薄
- 业务逻辑主要不在 Resource 类里

## 6. 数据不是算法单元自己随便查的

`portfolio_management` 虽然负责计算，但通常不直接到处写数据库访问代码。

它主要通过 `data_loader` 这层统一读取：

- 股票收益
- 行业分类
- 风险模型
- 基准持仓
- 基金、债券、期货、证券主数据等

因此，`data_loader` 应被视为 `brain` 的基础设施层。

## 7. brain 与本地依赖包的关系

`brain` 本身并不实现全部数学核心，它广泛依赖本地源码包：

- `mars`
- `solar`
- `saturn`

更准确地说：

- `brain` 负责 API、调度、数据装配
- `mars` 更偏归因/压力测试等算法实现
- `solar` 更偏数学函数、配置、工具方法
- `saturn` 更偏模拟器等辅助能力

## 8. 当前最重要的边界理解

### 8.1 `brain` 不是纯算法层

它包含：

- HTTP API
- Celery
- MQ/Redis/Backend
- 数据加载
- 算法装配

### 8.2 `brain` 也不是纯服务编排层

它内部仍然保留了大量业务算法单元。

### 8.3 `portfolio_management` 才是核心领域层

如果未来要重构，最有价值的抽象边界通常是：

- `API Shell`
- `Task Orchestrator`
- `Data Loading Layer`
- `Algorithm Domain Layer`

## 9. 一句话结论

`brain` 是一个“异步计算服务平台”，而不只是一个算法 HTTP 网关。
