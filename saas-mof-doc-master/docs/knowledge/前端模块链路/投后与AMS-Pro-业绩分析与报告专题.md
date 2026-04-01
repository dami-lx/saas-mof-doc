---
tags:
  - invested
  - ams
  - report
  - attribution
  - brain
status: active
updated: 2026-03-31
---

# 投后与 AMS Pro 业绩分析与报告专题

## 1. 这个专题关注什么

这篇文档只看“分析与报告”链路，不讨论组合主数据和导入。

它覆盖：

- 产品报告
- 业绩分析
- 报告导出
- 自定义归因与报告重算

## 2. 前端页面入口

关键路由：

- `/production2/analysis/:id?`
- `/production2/analysis-report/:id?`
- `/production2/analysis-export/:id?`
- `/portfolio/analysis/:id?/:type?`
- `/portfolio/simple/:id?/:type?`

主要目录：

- `mof-web-fe/js/pages/production/report`
- `mof-web-fe/js/pages/production/report-export`
- `mof-web-fe/js/pages/production/analysis`
- `mof-web-fe/js/v2/pages/Portfolio/analysis`
- `mof-web-fe/js/v2/pages/IndependentReport`

## 3. 前端 API 入口

### 3.1 报告数据与页面配置

关键文件：

- `mof-web-fe/js/pages/production/report/actions.tsx`
- `mof-web-fe/js/pages/production/report-export/actions.tsx`

已确认接口：

- `GET ${mof_api}/api/accounts/id?dyId={tickerSymbol}`
- `GET ${mof_api}/api/attribution/{accountId}?include={keys}`
- `GET ${mof_api}/api/attribution/custom/{customId}`
- `POST ${mof_api}/api/attribution/custom/attribution`
- `POST ${mof_api}/api/attribution/reCreateReport/{accountId}`
- `GET ${mof_api}/api/task/{taskId}`
- `POST ${mof_api}/api/mom/product/fund/attribution/{productId}`

### 3.2 页面运行时

从前端代码可确认，报告页不是普通 REST 列表页，而是“卡片布局 + 页面配置 + 异步数据”的组合：

- `savePage`
- `saveCard`
- `deletePage`
- `getTemplate`
- `getCacheAccountInfo`

这说明报告重构时必须保留页面配置与卡片配置层，而不是只保留最终数据结果。

## 4. 后端入口

### 4.1 卡片与报告平台

主 controller：

- `mom/mom-web/src/main/java/com/datayes/web/mom/card/CardDataController.java`
- `mom/mom-web/src/main/java/com/datayes/web/mom/card/CardViewController.java`

这一层负责：

- `ReportParam` 补默认值
- 根据模板 / cardKey 构造调用参数
- 调算法并序列化成前端可消费结构

### 4.2 归因与报告重算

主 controller：

- `mom/mom-legacy/src/main/java/com/datayes/web/mom/controller/AttributionController.java`

已确认关键接口：

- `GET /api/attribution/{accountId}`
- `POST /api/attribution/reCreateReport/{accountId}`
- `GET /api/attribution/latestAttrDate/{accountId}`
- `GET /api/attribution/custom/{tempAccountID}`
- `POST /api/attribution/custom/attribution`
- `POST /api/attribution/custom/attribution/holdingAttr`
- `GET /api/attribution/custom/template/{accountId}`
- `POST /api/attribution/custom/template`

这说明投后报告分析虽然页面很新，但后端相当一部分还依赖 `mom-legacy`。

## 5. 下游依赖与数据来源

### 5.1 `brain`

这是业绩分析与归因的主要计算层，负责：

- 净值表现
- 收益风险
- 行业 / 风格 / Brinson 归因
- 压力测试等分析能力

### 5.2 `pmsLite`

这是底层数据源层，负责提供：

- 持仓
- 组合结构
- 净值、订单、交易等主数据

### 5.3 `mom`

这是编排层，负责：

- 账户与模板上下文
- 卡片参数构造
- 结果缓存与报告重建

## 6. 公式与口径

这一层是真正的“公式高风险区”。

当前已确认的结构性结论：

- 公式不在前端
- 公式也不完全在 `mom`
- `mom` 更像卡片编排与兼容层
- 真正的绩效、归因、风险公式主要在 `brain`

对未来重构最重要的公式入口，应继续下钻到：

- `brain` 端点分类
- 卡片模板到 `brain` 端点的映射
- `ReportParam -> Brain post` 的构造逻辑

推荐阅读：

- [stockBrinson 全链路拆解](../stockBrinsonAttr-全链路拆解.md)
- [Brain API 层与端点分类](../brain/Brain-API层与端点分类.md)
- [Brain 任务编排与执行链](../brain/Brain-任务编排与执行链.md)

## 7. 重构时必须保留的契约

- 报告页要保留“页面配置 + 卡片配置 + 数据结果”三层，而不是只保留最终 JSON。
- `reCreateReport` 与 `custom/attribution` 这类接口不能当成边角功能，它们是投后分析闭环的一部分。
- 新页面调用老 controller 是当前真实现状，迁移时必须先建立兼容矩阵。

## 8. 后续建议

- 单独建立“投后报告卡片 -> cardKey -> brain 端点 -> 公式专题”的索引页。
- 进一步把 `Portfolio analysis` 和 `production report` 拆成共享卡片与差异卡片两部分。

## 9. 客户口径说明文档

- [A股风格归因卡片客户业务说明](./A股风格归因卡片-客户业务说明.md)
- [A股风格归因卡片项目实现与排查说明](./A股风格归因卡片-项目实现与排查说明.md)
- [A股风格归因卡片字段字典](./A股风格归因卡片-字段字典.md)
- [A股风格归因卡片 FAQ 与常见误解](./A股风格归因卡片-FAQ与常见误解.md)
- [A股风格归因卡片 Case 排查模板](./A股风格归因卡片-Case排查模板.md)
- [A股行业归因卡片客户业务说明](./A股行业归因卡片-客户业务说明.md)
- [A股行业归因卡片项目实现与排查说明](./A股行业归因卡片-项目实现与排查说明.md)
- [A股行业归因卡片字段字典](./A股行业归因卡片-字段字典.md)
- [A股行业归因卡片 FAQ 与常见误解](./A股行业归因卡片-FAQ与常见误解.md)
- [A股行业归因卡片 Case 排查模板](./A股行业归因卡片-Case排查模板.md)
- [业绩总览卡片客户业务说明](./业绩总览卡片-客户业务说明.md)
- [业绩总览卡片项目实现与排查说明](./业绩总览卡片-项目实现与排查说明.md)
- [业绩总览卡片字段字典](./业绩总览卡片-字段字典.md)
- [业绩总览卡片 FAQ 与常见误解](./业绩总览卡片-FAQ与常见误解.md)
- [业绩总览卡片 Case 排查模板](./业绩总览卡片-Case排查模板.md)
