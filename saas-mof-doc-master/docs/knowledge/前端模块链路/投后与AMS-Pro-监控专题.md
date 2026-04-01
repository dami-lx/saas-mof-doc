---
tags:
  - invested
  - ams
  - monitor
  - risk-control
status: active
updated: 2026-03-31
---

# 投后与 AMS Pro 监控专题

## 1. 这个专题关注什么

这篇文档关注：

- 产品监控页
- 持仓穿透与持仓趋势
- 风控设置
- 自定义监控 dashboard 入口

## 2. 前端页面入口

### 2.1 产品监控

路由定义：

- `mof-web-fe/js/pages/production/router.ts`

关键路由：

- `/production2/monitor/holdings/:id?/:type?`
- `/production2/monitor/(realtime)?`

主要目录：

- `mof-web-fe/js/pages/production/monitor`
- `mof-web-fe/js/pages/production/monitor/product-monitor`

### 2.2 风控设置

路由定义：

- `mof-web-fe/js/pages/investedManage/router.ts`

关键路由：

- `/app/riskControl`

主要目录：

- `mof-web-fe/js/pages/investedManage/riskControl`

### 2.3 自定义监控

入口：

- `/running/customize/default`

这是统一 dashboard / running 平台入口，不是一个普通列表页。

## 3. 前端 API 入口

### 3.1 持仓穿透与趋势

关键文件：

- `mof-web-fe/js/pages/production/monitor/product-monitor/penetrate/services.ts`

已确认接口：

- `POST api/mof::postApiPortfolioPositionComposition(...)`
  - 组合持仓结构
- `GET ${mof_api}/api/portfolio/position/trend?portfolioId={id}&endDate={date}`
  - 历史持仓量价趋势
- `GET api/mof::getApiPortfolioPositionCalendar`
  - 可用日期日历

从 `getPositionParams` 可见，这些请求还携带了重要监控参数：

- `penetrateWay`
- `positionMode`
- `withOtcFundPredict`
- `scenarioId`
- `strategyTreeCode`
- `realTimeQuote`

### 3.2 风控设置

关键文件：

- `mof-web-fe/js/pages/investedManage/riskControl/actions.ts`

已确认接口：

- `GET ${mof_api}/api/riskControl/rule`
- `GET ${mof_api}/api/riskControl/rule/entry/format`
- `GET ${mof_api}/api/riskControl/rule/entry/parameter`
- `PUT ${mof_api}/api/riskControl/rule/{id}/status`
- `POST/PUT ${mof_api}/api/riskControl/rule`
- `DELETE ${mof_api}/api/riskControl/rule/{id}`
- `PUT ${mof_api}/api/riskControl/rule/account/{accountId}`

## 4. 后端入口

### 4.1 持仓监控相关

主数据和穿透能力主要仍然落到：

- `mom/mom-web/src/main/java/com/datayes/web/ams/controller/PortfolioController.java`

已确认接口：

- `GET /pmsLite/portfolio/position/composition/{id}`
- `GET /pmsLite/portfolio/position/composition/{id}/direct`
- `GET /pmsLite/portfolio/position/composition/{id}/trend`
- `GET /pmsLite/portfolio/position/deliveryStatusCheck`
- `GET /pmsLite/portfolio/position/security/{id}`
- `GET /pmsLite/portfolio/ticker/{id}`

### 4.2 风控设置相关

风控接口属于历史接口域：

- `mom/mom-legacy/src/main/java/com/datayes/web/mom/controller/RiskControlController.java`

这说明监控模块本身也分两层：

- 组合 / 持仓监控走 `pmsLite`
- 风控规则配置仍保留在 `mom-legacy`

## 5. 数据来源与外部依赖

### 5.1 持仓监控

主要依赖：

- `pmsLite` 实时或准实时持仓
- 穿透后的层级结果
- 组合支持资产类型与行情字段

### 5.2 风控设置

主要依赖：

- 历史风控规则模型
- 账户与规则绑定关系
- 可能的通知、触发、扫描任务

## 6. 公式与口径

这条链路更重“监控口径”而不是传统绩效公式：

- 是否穿透
- 穿透到哪一层
- 分组方式 `groupType / positionMode`
- 是否使用实时行情 `realTimeQuote`
- 是否使用场景预测值 `withOtcFundPredict`

这些参数直接影响监控表格看到的数据，因此必须视为稳定业务口径，而不是 UI 参数。

## 7. 重构时必须保留的契约

- `不穿透 / 穿透` 不能只做成前端筛选项，必须保留后端语义映射。
- 风控规则配置和持仓监控虽然都叫“监控”，但不是同一个后端域。
- `/running/customize/default` 应单独归到 dashboard 平台，不应混进单一监控页面逻辑里。

## 8. 后续建议

- 单独补一张“监控页 tab -> API -> 结果数据结构”的对照表。
- 继续追 `postApiPortfolioPositionComposition` 对应的服务实现和数据口径。
