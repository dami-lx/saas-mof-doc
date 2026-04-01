---
tags:
  - frontend
  - invested
  - ams
  - pms
  - chain
status: active
updated: 2026-03-31
---

# 投后与 AMS Pro 模块链路

## 0. 子专题导航

- [投后与 AMS Pro 组合总览专题](./投后与AMS-Pro-组合总览专题.md)
- [投后与 AMS Pro 数据导入专题](./投后与AMS-Pro-数据导入专题.md)
- [投后与 AMS Pro 监控专题](./投后与AMS-Pro-监控专题.md)
- [投后与 AMS Pro 业绩分析与报告专题](./投后与AMS-Pro-业绩分析与报告专题.md)
- [投后与 AMS Pro 页面动作与请求模型对照表](./投后与AMS-Pro-页面动作与请求模型对照表.md)

## 1. 模块定位

这是当前系统里最复杂、最值得优先重构建模的模块。

原因是它天然包含两条主链：

- 组合 / 持仓 / 导入 / 调仓 / 估值主数据链
  - 以 `pmsLite` 为核心
- 业绩分析 / 归因 / 报告导出链
  - 以 `mom` 卡片平台 + `brain` 为核心

如果未来要做统一后端代码包，这个模块很适合成为“应用编排层 + 计算层 + 数据层”分层重构的样板。

当前也已经开始把它拆成“动作级知识”而不是只写专题说明：

- [投后与 AMS Pro 页面动作与请求模型对照表](./投后与AMS-Pro-页面动作与请求模型对照表.md)

## 2. 前端页面入口

### 2.1 老投后入口

路由定义：

- `mof-web-fe/js/pages/investedManage/router.ts`

关键入口：

- `/app/investedmanage`
- `/app/riskControl`
- `/app/uploadHistory`

### 2.2 新投后管理入口

路由定义：

- `mof-web-fe/js/pages/production/router.ts`

关键入口：

- `/production2/overview/:type(invested|virtualmom)?`
  - 产品管理
- `/production2/upload/:tabName?/:accountId?`
  - 产品数据导入
- `/production2/monitor/*`
  - 产品监控
- `/production2/analysis/:id?`
  - 产品报告
- `/production2/analysis-report/:id?`
  - 业绩分析
- `/production2/intelligent-report/*`
  - 智能报告

### 2.3 AMS Pro / Portfolio V2

路由定义：

- `mof-web-fe/js/v2/routes.ts`
- `mof-web-fe/js/v2/pages/Portfolio/upload2/router.tsx`

关键入口：

- `/portfolio/overview`
- `/portfolio/analysis/:id?/:type?`
- `/portfolio/simple/:id?/:type?`
- `/portfolio/optimization/:id?`
- `/portfolio/risk/:id?/:type?`
- `/portfolio/manage/*`

## 3. 前端 API 入口

### 3.1 投后产品列表与筛选

关键文件：

- `mof-web-fe/js/pages/product/filter/inner/actions.tsx`

已确认接口：

- `POST ${mof_api}/api/accounts`
  - 投后产品列表
- `POST ${mof_api}/api/accounts/field`
  - 字段筛选
- `POST ${mof_api}/api/accounts/industries`
- `POST ${mof_api}/api/accounts/styles`
- `GET ${mof_api}/api/filters/v2`
- `GET ${mof_api}/api/navFrequency/list`
- `POST ${mof_api}/api/accounts/field/seriesAndStrategy`
- `GET ${mof_api}/api/attribution/latestAttrDate/{accountId}`
- `POST ${mof_api}/api/accountUpload/createAccount`

这条链更多属于投后产品域和账户筛选域，不等同于 `pmsLite` 组合域。

### 3.2 Portfolio / AMS Pro 组合主数据

关键文件：

- `mof-web-fe/js/v2/pages/Portfolio/overview/portfolio/add-portfolio/service.ts`
- `mof-web-fe/js/v2/pages/Portfolio/overview/portfolio/editPortfolio/service.ts`
- `mof-web-fe/js/v2/pages/Portfolio/historyposition/services.ts`
- `mof-web-fe/js/v2/pages/Portfolio/optimize/service.ts`

已确认接口：

- `POST ${mof_api}/api/netValue/creation`
- `PUT ${mof_api}/pmsLite/portfolio/{id}`
- `GET ${mof_api}/pmsLite/portfolio/base/{id}`
- `GET ${mof_api}/pmsLite/portfolio/all`
- `GET ${mof_api}/pmsLite/portfolio/allReadable`
- `GET ${mof_api}/pmsLite/portfolio/position/composition/{id}`
- `GET ${mof_api}/pmsLite/portfolio/position/composition/{id}/direct`
- `GET ${mof_api}/pmsLite/portfolio/position/composition/{id}/trend`
- `POST ${mof_api}/pmsLite/portfolio/position/upload/v2`

更完整的动作映射与请求模型，见：

- [投后与 AMS Pro 页面动作与请求模型对照表](./投后与AMS-Pro-页面动作与请求模型对照表.md)

### 3.3 报告与归因

关键文件：

- `mof-web-fe/js/pages/production/report/actions.tsx`
- `mof-web-fe/js/pages/production/report-export/actions.tsx`

已确认接口：

- `GET ${mof_api}/api/attribution/{accountId}`
- `GET ${mof_api}/api/attribution/custom/{customId}`
- `POST ${mof_api}/api/attribution/custom/attribution`
- `POST ${mof_api}/api/attribution/reCreateReport/{accountId}`
- `POST ${mof_api}/api/mom/product/fund/attribution/{productId}`
- `GET ${mof_api}/api/task/{taskId}`

这说明“投后报告”虽然从投后页面进入，但实际执行时会重新回到统一卡片 / 任务平台。

## 4. `mom` 后端入口

### 4.1 投后产品筛选

主 controller：

- `mom/mom-web/src/main/java/com/datayes/web/mom/account/internal/controller/InternalAccountSearchController.java`
- `mom/mom-web/src/main/java/com/datayes/web/mom/account/internal/controller/ProductionAccountController.java`

已确认接口：

- `POST /api/account/internal/ordinarySearch`
- `DELETE /api/account/production/{accountId}`
- `DELETE /api/account/production`

这说明投后产品筛选和产品删除仍在 `mom` 业务层内维护。

### 4.2 Portfolio / AMS Pro 主数据

主 controller：

- `mom/mom-web/src/main/java/com/datayes/web/ams/controller/PortfolioController.java`

基础路径：

- `/pmsLite`

已确认能力：

- `/portfolio/pms`
  - 创建全资产组合
- `/portfolio/list`
  - 组合总览名称与 id
- `/portfolio/summary`
  - 组合总览补充信息
- `/portfolio/base/{id}`
  - 组合基础信息
- `/portfolio/{id}`
  - 组合详情
- `/portfolio/all`
- `/portfolio/allReadable`
- `/portfolio/position/composition/{id}`
- `/portfolio/position/composition/{id}/direct`
- `/portfolio/position/composition/{id}/trend`

从控制器实现已确认两点：

- `PortfolioController` 是 `mof-web-fe` 里 `/portfolio/*` 页面最核心的后端入口。
- 它内部同时复用了 `Mof2AmsDataService`、`ManualAccountService`、`IPortfolioService`，说明 `AMS Pro` 不是独立于 `mom` 的另一套系统，而是被嵌进了当前聚合服务中。

### 4.3 卡片与报告

主 controller：

- `mom/mom-web/src/main/java/com/datayes/web/mom/card/CardDataController.java`
- `mom/mom-web/src/main/java/com/datayes/web/mom/card/CardViewController.java`

报告页和业绩分析页最终仍会回到统一卡片平台，再下钻到 `brain`。

## 5. 数据来源与外部依赖

### 5.1 `pmsLite`

这是投后 / AMS Pro 的主数据底座，负责：

- 组合主数据
- 持仓组合
- 调仓与交付记录
- 导入状态
- 净值与估值相关基础能力

### 5.2 `mom` 账户与产品域

这层负责：

- 投后产品列表与权限
- 组合与产品之间的业务关联
- 卡片报告上下文

### 5.3 `mom-legacy` 风控规则域

这层负责：

- 风控规则 CRUD
- 规则与账户绑定
- 触发历史与扫描历史

### 5.4 `brain`

这层主要服务：

- 净值表现
- 风险收益
- Brinson / 风格 / 行业归因
- 压力测试等分析型能力

## 6. 公式与计算口径

投后 / AMS Pro 里最需要区分的不是单个公式，而是三类能力：

### 6.1 主数据型

典型接口：

- `/pmsLite/portfolio/*`

特点：

- 更重数据组织与状态管理
- 不是数值公式主入口

### 6.2 组合计算型

典型接口：

- `/api/netValue/*`
- `/api/assetallocation/*`

特点：

- 负责组合创建、编辑、再计算
- 会决定组合结构和后续报告口径

### 6.3 报告分析型

典型接口：

- `/api/card/*`
- `/api/attribution/*`
- `brain` 的 nav perf / attr / risk / stress 接口

特点：

- 真正的绩效与归因公式在这一层
- 例如 Brinson、净值表现、收益贡献等

推荐阅读：

- [stockBrinson 全链路拆解](../stockBrinsonAttr-全链路拆解.md)
- [PMS_ELITE 穿透持仓与指标口径专题](../PMS_ELITE-穿透持仓与指标口径专题.md)
- [Brain 数据加载层与外部依赖](../brain/Brain-数据加载层与外部依赖.md)

## 7. 重构时必须保留的契约

- `投后产品` 与 `AMS 组合` 虽然页面上接近，但后端标识体系是双轨的：
  - `accountId`
  - `portfolioId`
- `/portfolio/*` 主数据接口与 `/api/card/*` 报告接口不要混成同一层。
- “看持仓 / 看组合详情”和“看报告 / 看归因”应视为两条主链。
- `taskId` 轮询协议要保留，因为导入、报告重算、归因等功能都依赖异步任务模型。

## 8. 待继续补充

- `production2/monitor` 监控页的 API 与指标口径。
- `portfolio/manage/*` 每个导入子页面对应的后端接口清单。
- `production/report` 与卡片模板 / `brain` 端点的逐卡映射。

## 9. 当前拆解建议

如果按可执行重构单元来分，这个模块推荐优先拆成四条子线：

1. 组合总览与主数据
2. 数据导入与导入历史
3. 监控与风控
4. 业绩分析与报告

原因是这四条线虽然在产品上连续，但底层依赖已经明显不同：

- 主数据和导入更偏 `pmsLite`
- 监控横跨 `pmsLite` 和 `mom-legacy`
- 业绩分析与报告强依赖卡片平台和 `brain`
