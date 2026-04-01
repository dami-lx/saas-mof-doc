---
tags:
  - pms
  - api
  - moc
  - refactor
status: active
updated: 2026-03-27
---

# PMS_ELITE 接口知识库 MOC

## 1. 这组文档的用途

这组文档用于把 `mercury-pms-elite` 的接口、实现分层、核心口径和重构边界沉淀成长期知识库。

这套知识库的目标不是替代源码，而是帮助后续重构时快速回答以下问题：

1. `PMS_ELITE` 对外暴露了哪些接口。
2. 每个接口属于“查询、写入、任务触发、管理工具”中的哪一类。
3. 每个接口后面真正调用了哪些 service、controller、business 代码。
4. 哪些模块是业务核心，哪些模块是运维/调试工具。
5. 如果以后拆分服务或异语言重写，哪些契约必须保留。

## 2. 阅读入口

### 2.1 总览

- [PMS_ELITE 接口总览与模块边界](./PMS_ELITE-接口总览与模块边界.md)

### 2.2 模块专题

- [PMS_ELITE Portfolio 模块专题](./PMS_ELITE-Portfolio模块专题.md)
- [PMS_ELITE Position 模块专题](./PMS_ELITE-Position模块专题.md)
- [PMS_ELITE Transaction 模块专题](./PMS_ELITE-Transaction模块专题.md)
- [PMS_ELITE Delivery Refresh Task 模块专题](./PMS_ELITE-DeliveryRefreshTask模块专题.md)
- [PMS_ELITE Help Monitor 模块专题](./PMS_ELITE-HelpMonitor模块专题.md)

## 3. 推荐阅读顺序

### 3.1 如果目标是快速了解系统

1. [PMS_ELITE 接口总览与模块边界](./PMS_ELITE-接口总览与模块边界.md)
2. [PMS_ELITE Position 模块专题](./PMS_ELITE-Position模块专题.md)
3. [PMS_ELITE Portfolio 模块专题](./PMS_ELITE-Portfolio模块专题.md)

### 3.2 如果目标是为重构做边界拆分

1. [PMS_ELITE 接口总览与模块边界](./PMS_ELITE-接口总览与模块边界.md)
2. [PMS_ELITE Position 模块专题](./PMS_ELITE-Position模块专题.md)
3. [PMS_ELITE Delivery Refresh Task 模块专题](./PMS_ELITE-DeliveryRefreshTask模块专题.md)
4. [PMS_ELITE Transaction 模块专题](./PMS_ELITE-Transaction模块专题.md)
5. [PMS_ELITE Portfolio 模块专题](./PMS_ELITE-Portfolio模块专题.md)

## 4. 已确认的核心结论

- `PMS_ELITE` 并不是一个只有“组合 CRUD”的简单服务，它同时承担了组合层业务数据、穿透持仓、指标补算、任务调度和数据导入职责。
- `position` 模块是最重的业务核心，内部同时包含 `MomData`、`MOM`、`FoF` 透视、实时估值和分页展示逻辑。
- `portfolio/indicator` 看似只是指标查询接口，实际上包含 Mongo 查询与摘要指标补算逻辑。
- `delivery / refresh / task` 构成了任务触发和查询体系，是异步处理链的重要外壳。
- `help` 模块包含高风险运维能力，包括 Mongo 数据查询/插入/更新/删除和硬删除组合数据。

## 5. 当前已覆盖的边界

本轮文档已经覆盖：

- 全部 API 路由入口
- 视图类和 service 映射
- 各模块核心功能职责
- 关键实现文件
- 重构时建议的拆分边界

尚未做深挖的方向：

- `workers` 与 Celery 任务内部执行链
- `business/delivery` 的完整导入口径
- `component/calculation` 的指标数学细节
- `dao` 层每个集合和索引的详细数据模型

## 6. 后续扩展建议

如果后续继续扩展这套知识库，建议优先补以下专题：

1. `PMS_ELITE 数据模型专题`
2. `PMS_ELITE Celery 任务执行链专题`
3. `PMS_ELITE Indicator 计算专题`
4. `PMS_ELITE Mongo 集合与缓存键专题`
