---
tags:
  - mom-robo
  - api
  - moc
  - refactor
status: active
updated: 2026-03-27
---

# Mom-Robo 接口知识库 MOC

## 1. 这组文档的用途

这组文档用于把 `mom-robo` 这个前端直连业务服务的 API 面、模块边界和业务分类沉淀成长期知识库。

这套知识库主要服务于三个目标：

1. 让后续阅读者快速理解 `mom-robo` 到底是“一个应用”还是“多个服务聚合”。
2. 按业务属性把海量接口重新组织，避免未来重构时被 controller 名称和历史包袱带偏。
3. 为未来拆分服务、异语言迁移和 API contract 重建提供结构化底稿。

## 2. 阅读入口

### 2.1 总览

- [Mom-Robo 模块总览与聚合入口](./Mom-Robo-模块总览与聚合入口.md)

### 2.2 专题文档

- [Mom-Robo API 按业务分类](./Mom-Robo-API按业务分类.md)
- [Mom-Robo 控制器与模块清单](./Mom-Robo-控制器与模块清单.md)

## 3. 推荐阅读顺序

### 3.1 如果目标是快速了解系统

1. [Mom-Robo 模块总览与聚合入口](./Mom-Robo-模块总览与聚合入口.md)
2. [Mom-Robo API 按业务分类](./Mom-Robo-API按业务分类.md)

### 3.2 如果目标是做系统重构

1. [Mom-Robo 模块总览与聚合入口](./Mom-Robo-模块总览与聚合入口.md)
2. [Mom-Robo API 按业务分类](./Mom-Robo-API按业务分类.md)
3. [Mom-Robo 控制器与模块清单](./Mom-Robo-控制器与模块清单.md)

## 4. 当前已确认的核心结论

- `mom-robo` 不是一个只有单模块 controller 的简单 web 项目，而是一个由 `mom-application` 聚合启动的 Spring Boot 多模块应用。
- `mom-web` 是最大的 API 暴露层，但不是唯一 API 来源。
- API 面至少分散在以下模块：
  - `mom-web`
  - `mom-legacy`
  - `mom-portfolio-service`
  - `mom-private-asset-service`
  - `mom-user`
  - `mom-lib`
  - `mom-h5`
  - `mom-workflow`
  - `mom-fundpool`
  - `mom-saas`
  - `mom-datayesir`
  - `mom-ai-api`
  - `due-diligence`
- 从业务视角看，`mom-robo` 的接口不是按技术层划分，而是围绕：
  - 基金/产品搜索筛选
  - 报告卡片与评价页
  - 资产配置与模拟组合
  - 投后/PMS_ELITE 管理
  - 私有资产
  - 基准/行业/指标/风控
  - 用户权限/标签/分组/协作
  - 工作流/导入导出/任务与缓存

## 5. 当前已覆盖的边界

本轮文档已经覆盖：

- 聚合启动入口
- 模块级 API 来源分布
- 按业务属性的接口分类
- 主要 controller 所在模块与 base path

尚未深入的部分：

- 每个 controller 下的 endpoint 全量逐条说明
- 各类 DTO / Request / Response 模型的字段口径
- controller 到 service / feign / rpc 的详细下游调用链
- 不同租户、权限、角色体系对接口行为的影响

## 6. 后续建议补充的专题

1. `Mom-Robo 卡片系统专题`
2. `Mom-Robo 账户筛选与搜索专题`
3. `Mom-Robo 投后接口专题`
4. `Mom-Robo 用户权限与标签体系专题`
5. `Mom-Robo 任务、缓存与迁移接口专题`
