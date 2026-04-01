---
tags:
  - invested
  - ams
  - portfolio
  - overview
  - knowledge-base
status: active
updated: 2026-03-31
---

# 投后与 AMS Pro 组合总览专题

## 1. 这个专题关注什么

这篇文档只讨论“组合总览 / 组合主数据”这一层，不展开数据导入、监控和报告分析。

它主要回答：

- 前端 `/portfolio/overview`、`/production2/overview/*` 到底在查什么
- 哪些接口是“组合主数据接口”
- `accountId` 和 `portfolioId` 如何共存
- 组合总览页真正依赖的是 `mom` 还是 `pmsLite`

## 2. 前端页面入口

### 2.1 AMS Pro 组合总览

关键路由：

- `/portfolio/overview`

主要目录：

- `mof-web-fe/js/v2/pages/Portfolio/overview`

### 2.2 投后产品总览

关键路由：

- `/production2/overview/:type(invested|virtualmom)?`
- `/app/fund/product/filter/inner`

主要目录：

- `mof-web-fe/js/pages/production/overview`
- `mof-web-fe/js/pages/product/filter/inner`

## 3. 前端 API 入口

### 3.1 组合总览主数据

当前已确认的关键请求：

- `GET ${mof_api}/pmsLite/portfolio/list`
- `GET ${mof_api}/pmsLite/portfolio/summary`
- `GET ${mof_api}/pmsLite/portfolio/base/{id}`
- `GET ${mof_api}/pmsLite/portfolio/{id}`
- `GET ${mof_api}/pmsLite/portfolio/all`
- `GET ${mof_api}/pmsLite/portfolio/allReadable`
- `GET ${mof_api}/pmsLite/portfolio/types/{id}`

前端相关文件：

- `mof-web-fe/js/v2/pages/Portfolio/overview/portfolio/add-portfolio/service.ts`
- `mof-web-fe/js/v2/pages/Portfolio/overview/portfolio/editPortfolio/service.ts`
- `mof-web-fe/js/pages/production/components/edit-portfolio/use-options.ts`

### 3.2 投后产品列表

投后产品列表并不直接等于 `pmsLite` 组合列表，还会经过 `mom` 产品域：

- `POST ${mof_api}/api/accounts`
- `POST ${mof_api}/api/accounts/field`
- `POST ${mof_api}/api/accounts/field/seriesAndStrategy`

前端相关文件：

- `mof-web-fe/js/pages/product/filter/inner/actions.tsx`

## 4. `mom` / `pmsLite` 后端入口

### 4.1 `pmsLite` 组合主数据入口

主 controller：

- `mom/mom-web/src/main/java/com/datayes/web/ams/controller/PortfolioController.java`

当前确认的总览类接口：

- `GET /pmsLite/portfolio/list`
- `GET /pmsLite/portfolio/summary`
- `GET /pmsLite/portfolio/base/{id}`
- `GET /pmsLite/portfolio/{id}`
- `GET /pmsLite/portfolio/brief/{id}`
- `GET /pmsLite/portfolio/all`
- `GET /pmsLite/portfolio/allReadable`
- `GET /pmsLite/portfolio/types/{id}`
- `GET /pmsLite/portfolio/portfolioCountInfo`

### 4.2 `mom` 投后产品域入口

主 controller：

- `mom/mom-web/src/main/java/com/datayes/web/mom/account/internal/controller/InternalAccountSearchController.java`
- `mom/mom-web/src/main/java/com/datayes/web/mom/account/internal/controller/ProductionAccountController.java`

当前已确认：

- `POST /api/account/internal/ordinarySearch`
- `DELETE /api/account/production/{accountId}`
- `DELETE /api/account/production`

## 5. 这条链路的关键语义

### 5.1 `portfolioId` 是组合主数据标识

组合总览、组合详情、支持资产类型、组合持仓等能力，主键基本都是 `portfolioId`。

### 5.2 `accountId` 是业务产品标识

投后产品列表、投后权限、报告上下文、归因缓存等能力，仍然大量使用 `accountId`。

### 5.3 两套标识并存是系统事实

从 `PortfolioController` 与投后产品接口并存可确认：

- `pmsLite` 维护组合主数据
- `mom` 维护业务产品 / 账户语义
- 很多页面实际上需要两者映射

这也是未来重构时最不能偷懒的部分之一。

## 6. 数据来源

### 6.1 直接来源

- `IPortfolioService`
  - 组合主数据服务
- `Mof2AmsDataService`
  - 把 `mof` 信息补充进 `AMS` 组合总览
- `AccountCache`
  - 查 `mof account` 等补充信息

### 6.2 衍生来源

- 权限缓存
- 组合类型、产品来源、触发源等枚举字段

## 7. 公式与口径

这一层基本不是算法公式层，而是主数据口径层。

更应该沉淀的口径有：

- 组合类型 `portfolioProperty`
- 触发源 `triggerSource`
- 产品来源 `productSource`
- `portfolioId` 与 `mofId/accountId` 的映射关系

## 8. 重构时必须保留的契约

- 组合总览不能只保留 `portfolioId`，还要保留与 `mof` 产品域的映射能力。
- “所有可读组合”和“所有组合”要区分。
- `PortfolioController` 这层不只是数据透传，它会补权限与 `mof` 信息。

## 9. 后续建议

- 再细化一张“组合类型 / triggerSource / 页面模型”的对照表。
- 单独补“新增组合 / 编辑组合”的创建与编辑流程图。
