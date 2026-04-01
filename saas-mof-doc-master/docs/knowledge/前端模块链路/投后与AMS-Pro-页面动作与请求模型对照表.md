---
tags:
  - invested
  - ams
  - mapping
  - request-model
  - pms-lite
status: active
updated: 2026-03-31
---

# 投后与 AMS Pro 页面动作与请求模型对照表

## 1. 这篇文档解决什么问题

投后 / AMS Pro 是当前系统里最容易混淆的模块，因为一个前端页面往往同时经过：

- `mom` 产品域
- `pmsLite` 组合域
- `mom-legacy` 风控域
- `mom` 卡片 / 报告平台
- `brain` 计算域

这篇文档把页面动作固定映射成：

- 前端入口
- 请求接口
- 请求模型或关键参数
- 当前仓库能确认到的后端落点
- 主要数据来源

适合用作重构时的动作级地图。

## 2. 组合总览与基础信息动作

| 页面动作 | 前端入口 | 请求接口 | 请求模型 / 关键参数 | 后端落点 | 主要依赖 |
| --- | --- | --- | --- | --- | --- |
| 创建净值型组合 | `v2/pages/Portfolio/overview/portfolio/add-portfolio/service.ts` | `POST /api/netValue/creation` | `AssetAllocationCreation` 聚合对象 | `NetValueController.creation` -> `NetValueAccountService.create` | `pmsLite` 创建组合、`mom` 产品映射、`GroupService` |
| 编辑手动组合基础信息 | `editPortfolio/service.ts` | `PUT /pmsLite/portfolio/{id}` | 组合基础编辑对象 | `PortfolioController` 下组合编辑链 | `IPortfolioService`、`pmsLite` |
| 读取组合基础信息 | `editPortfolio/service.ts` | `GET /pmsLite/portfolio/base/{id}` | 路径参数 `id` | `PortfolioController.getPortfolioBaseInfo` | `portfolioService.portfolioBaseInfo`、估值导入信息补充 |
| 读取组合概览名称与 id | Portfolio overview 页面 | `GET /pmsLite/portfolio/list` | `pageNow`、`pageSize`、`productSource` | `PortfolioController.portfolioList` | `portfolioService`、`Mof2AmsDataService.mofData` |
| 读取组合概览补充信息 | Portfolio overview 页面 | `GET /pmsLite/portfolio/summary` | `pageNow`、`pageSize`、`mofFields`、`productSource`、`portfolioIds` | `PortfolioController.portfolioSummary` | `AccountCache.findAccountsByIds` |
| 读取全部组合 | Portfolio 下拉选择 | `GET /pmsLite/portfolio/all` | `withMofId`、`triggerSource`、`productSource`、`portfolioProperty` | `PortfolioController.getAllPortfolio` | `portfolioService.allPortfolio` |
| 读取全部可读组合 | 报告页 / 选择器 | `GET /pmsLite/portfolio/allReadable` | `withMofId`、`triggerSource`、`portfolioProperty` | `PortfolioController.getAllPortfolioReadable` | 组合权限映射、`pmsLite` 组合列表 |

## 3. 持仓穿透与监控动作

| 页面动作 | 前端入口 | 请求接口 | 请求模型 / 关键参数 | 后端落点 | 主要依赖 |
| --- | --- | --- | --- | --- | --- |
| 产品监控页查询持仓结构 | `pages/production/monitor/product-monitor/penetrate/services.ts` | `POST /api/portfolio/position/composition` | `PositionMetricParam` | 当前仓未直接定位到 `/api/portfolio` controller；可对照 `PortfolioController` 的 `GET /pmsLite/portfolio/position/composition/{id}` 与 `/direct` 能力 | 组合持仓、穿透层级、实时行情、场景参数 |
| 查询可用持仓日期 | 同上 | `GET /api/portfolio/position/calendar` | `portfolioId`、`endDate`、`isOriginal` | 当前仓未直接定位到对应 controller | 持仓日历、导入历史 |
| 查询历史持仓量价趋势 | 同上 | `GET /api/portfolio/position/trend` | `portfolioId`、`endDate` | 当前仓未直接定位到 `/api/portfolio/position/trend` controller；`PortfolioController` 中存在等价的 `GET /pmsLite/portfolio/position/composition/{id}/trend` | 历史持仓 + 行情时间序列 |
| 查询组合持仓 composition | `v2/pages/Portfolio/historyposition/services.ts`、`v2/pages/Portfolio/position/api.ts` | `GET /pmsLite/portfolio/position/composition/{id}` | `queryDate` 或 `PositionCompositionDTO` | `PortfolioController.portfolioPositionComposition` | `portfolioService.portfolioPositionComposition` |
| 查询组合穿透结果 | `v2/pages/Portfolio/components/AdjustModal/useGetCashMargin.ts` 等 | `GET /pmsLite/portfolio/position/composition/{id}/direct` | `PositionCompositionDTOV2` | `PortfolioController.portfolioPositionComposition(direct)` | `portfolioService.portfolioPositionCompositionV2` |
| 查询历史持仓趋势 | `penetrate/services.ts` 的业务对照 | `GET /pmsLite/portfolio/position/composition/{id}/trend` | `PositionCompositionDTOV2` | `PortfolioController.portfolioPositionTrend` | `portfolioService.portfolioPositionTrend` |
| 查询持仓导入状态 | `v2/pages/CombiningMonitor/monitor/service.ts` | `GET /pmsLite/portfolio/position/deliveryStatusCheck` | `DeliveryStatusCheckDTO` | `PortfolioController.deliveryStatusCheck` | `portfolioService.deliveryStatusCheck` |
| 查询持仓证券详情 | Portfolio 持仓明细 | `GET /pmsLite/portfolio/position/security/{id}` | `PositionCompositionDTO` | `PortfolioController.portfolioPositionSecurity` | 证券明细 |
| 查询持仓新闻舆情 | 产品监控消息页 | `POST /pmsLite/portfolio/position/news` | `List<String> securityIds` | `PortfolioController.portfolioPositionNews` | 新闻服务聚合 |

### 3.1 `PositionMetricParam` 是监控页的稳定业务契约

前端 `getPositionParams` 会显式组装下面这些参数：

- `penetrateWay`
- `positionMode`
- `withOtcFundPredict`
- `scenarioId`
- `strategyTreeCode`
- `realTimeQuote`
- `level`
- `hideZeroCash`
- `lastUpdateTime`
- `isOriginal`

这些参数不是普通 UI 筛选，而是直接决定持仓监控口径的业务契约。

## 4. 导入与更新动作

| 页面动作 | 前端入口 | 请求接口 | 请求模型 / 关键参数 | 后端落点 | 主要依赖 |
| --- | --- | --- | --- | --- | --- |
| 解析交易文件 | `v2/pages/Portfolio/upload2/containers/trade/service.ts` | `POST /api/transaction/check` | 上传文件、`portfolio_id` | 当前仓未直接定位 controller | 交易文件解析服务 |
| 提交交易导入 | 同上 | `POST /api/transaction/delivery?portfolio_id={id}&upsert=true&deliveryMode=...` | `delivery_files_info` | 当前仓未直接定位 controller | 交易导入任务链 |
| 轮询交易导入状态 | 同上 | `GET /api/transaction/status?task_id=...` | `task_id` | 当前仓未直接定位 controller | 导入任务状态 |
| 解析持仓文件 | `v2/pages/Portfolio/upload2/containers/position-upload/service.ts` | `POST /pmsLite/portfolio/position/check/v2` | `DeliveryPositionCheckDTO` + file | `PortfolioController.checkPositionV2` | `portfolioService.checkPositionV2` |
| 提交持仓导入 | 同上 | `PUT /pmsLite/portfolio/position/upload/v2?portfolioId={id}&deliveryMode=...` | `DeliveryPositionV2DTO`，核心字段 `delivery_positions`、`file_list` | `PortfolioController.uploadPositionV2` | `portfolioService.uploadPositionV2` |
| 轮询持仓导入状态 | upload base service | `GET /pmsLite/portfolio/position/upload/status/v2` | `portfolioId`、`taskId` | `PortfolioController.positionStatusV2` | 导入任务状态 |
| 解析净值文件 | `v2/pages/Portfolio/upload2/containers/net-value/components/single-import/service.ts` | `POST /pmsLite/portfolio/delivery/checkUploadNav` | `UploadNavCheckDTO` + files | `PortfolioController.checkUploadNav` | `portfolioService.checkUploadNav` |
| 提交净值文件导入 | 同上 | `POST /pmsLite/portfolio/delivery/uploadNav?deliveryMode=...` | `UploadNavDTO` + `DeliveryNetValueV2DTO` | `PortfolioController.uploadNav` | `portfolioService.uploadNav` -> `pmsLiteService.uploadNav` |
| 界面录入净值并导入 | `v2/pages/Portfolio/upload2/containers/net-value/components/upload-in-page/service.ts` | `POST /pmsLite/portfolio/delivery/uploadTextNav?deliveryMode=...` | `UploadNavDTO` + `NavTextImportRequest` | `PortfolioController.uploadNavTextParsed` | `portfolioService.uploadNavTextParsed` 把文本解析结果转成标准净值导入对象 |
| 查询导入历史日历 | `pages/production/import/components/history-header/service.ts`、`upload2/history/Base/service.ts` | `GET /pmsLite/portfolio/delivery/history/date` | `portfolioId`、`calendar`、`taskType` | `PortfolioController.historiesDate` | `portfolioService.history` |
| 查询导入历史列表 | `pages/production/import/components/net-value-history/service.ts`、`upload2/history/Base/service.ts` | `GET /pmsLite/portfolio/delivery/history` | `DeliveryHistoryDTO` | `PortfolioController.history` | 导入历史 |
| 查询导入历史详情 | `pages/production/import/components/net-value-history/service.ts`、`upload2/history/components/detail/service.ts` | `GET /pmsLite/portfolio/delivery/history/detail?taskId=...` | `taskId` | `PortfolioController.historyDetail` | 导入历史详情 |

### 4.1 净值界面录入的实现结论

`PortfolioServiceImpl.uploadNavTextParsed` 已明确做了两步转换：

1. 把前端文本录入结果 `parseResults` 组装成标准 `NavImport`
2. 复用统一的 `uploadNav` 导入链

这说明净值文本录入不是独立算法，而是导入链的一个输入适配层。

## 5. 风控规则动作

| 页面动作 | 前端入口 | 请求接口 | 请求模型 / 关键参数 | 后端落点 | 主要依赖 |
| --- | --- | --- | --- | --- | --- |
| 读取全部规则 | `pages/investedManage/riskControl/actions.ts` | `GET /api/riskControl/rule` | 可选 `accountId` | `RiskControlController.getRules` | `RiskControlService` |
| 读取规则详情 | 同上 | `GET /api/riskControl/rule/{id}` | `id` | `RiskControlController.getRule` | `RiskControlService` |
| 读取规则项参数字典 | 同上 | `GET /api/riskControl/rule/entry/parameter` | 无 | `RiskControlController.getRuleEntryParameters` | `RiskControlService` |
| 读取规则格式模板 | 同上 | `GET /api/riskControl/rule/entry/format` | 无 | `RiskControlController.getRuleFormats` | `RiskControlService` |
| 更新规则状态 | 同上 | `PUT /api/riskControl/rule/{id}/status?value=...` | `id`、`value` | `RiskControlController.updateRuleStatus` | `RiskControlService` |
| 创建规则 | 同上 | `POST /api/riskControl/rule` | `Rule` | `RiskControlController.createRule` | `RiskControlService.insertRule` |
| 修改规则 | 同上 | `PUT /api/riskControl/rule/{id}` | `Rule` | `RiskControlController.updateRule` | `RiskControlService.updateRule` |
| 删除规则 | 同上 | `DELETE /api/riskControl/rule/{id}` | `id` | `RiskControlController.deleteRule` | `RiskControlService.deleteRule` |
| 绑定产品与规则 | 同上 | `PUT /api/riskControl/rule/account/{accountId}` | `List<Long> ruleIds` | `RiskControlController.updateAccountRelatedRules` | 账户与规则关联 |
| 查询实时扫描结果 | `v2/cards/+ValuationTable/liveRisk2Monitor/actions.ts` | `GET /api/riskControl/rule/scan/hist` | 无 | `RiskControlController.getTriggerHist(scan)` | `RiskControlMapper.getScanHist` |
| 查询最新触发结果 | 风控提示组件 | `GET /api/riskControl/rule/trigger/latest` | 无 | `RiskControlController.getTriggerLatest` | `RiskControlMapper.getTriggerLatest` |
| 查询触发历史 | `v2/cards/+ValuationTable/riskMonitor2History/actions.ts` | `GET /api/riskControl/rule/trigger/hist` | `startDate`、`endDate`、`showHidden` | `RiskControlController.getTriggerHist` | `RiskControlMapper.getTriggerHist` |
| 隐藏触发记录 | 同上 | `PUT /api/riskControl/rule/trigger/hist/hide` | `accountId`、`ruleId` | `RiskControlController.hideTriggerHist` | `RiskControlMapper.hideTriggerHist` |

## 6. 报告与业绩分析动作

| 页面动作 | 前端入口 | 请求接口 | 请求模型 / 关键参数 | 后端落点 | 主要依赖 |
| --- | --- | --- | --- | --- | --- |
| 打开投后报告页 | `pages/production/report/actions.tsx` | 统一报告加载链 | `accountId`、`portfolioId`、`menuSelect` 等 | `mom` 卡片平台 | `CardViewController`、`CardDataController` |
| 查询归因结果 | `pages/production/report/actions.tsx` | `GET /api/attribution/{accountId}` | `accountId` | `mom` 报告 / 归因链 | `brain`、`pmsLite`、持仓与净值输入 |
| 查询自定义归因结果 | 同上 | `GET /api/attribution/custom/{customId}` | `customId` | `mom` 报告链 | `brain` |
| 触发归因重算 | 同上 | `POST /api/attribution/custom/attribution`、`POST /api/attribution/reCreateReport/{accountId}` | 账户、模板、参数 | `mom` 卡片平台任务链 | `brain` 任务执行 |
| 轮询任务状态 | 同上 | `GET /api/task/{taskId}` | `taskId` | 通用任务状态链 | 异步任务运行时 |

## 7. 关键实现结论

- 投后 / AMS Pro 不是一个单后端域，而是四层同时存在：
  - `mom` 产品与报告编排层
  - `pmsLite` 组合与导入层
  - `mom-legacy` 风控规则层
  - `brain` 计算层
- 前端有一部分接口走 `/api/portfolio/*` wrapper，但当前工作区没有直接定位到对应 controller。
- 同一业务动作常常存在“页面友好接口”和“底层 `pmsLite` 等价接口”两套入口，文档里不能混为一谈。
- `PositionMetricParam`、`DeliveryHistoryDTO`、`UploadNavDTO`、`Rule` 这些模型都应该保留为未来重构中的显式契约。

## 8. 重构时优先保留什么

- 保留导入链的“check -> upload -> status -> history”四段式结构。
- 保留 `pmsLite` 组合标识和 `mom` 账户标识并存的双标识模式。
- 保留风控规则作为独立子域，不要塞进持仓监控 service。
- 保留报告层与计算层解耦，报告负责参数编排，`brain` 负责计算。
- 对当前未直接定位 controller 的 `/api/portfolio/*`、`/api/transaction/*` 接口，建议重构时先做 adapter，再去补真实落点。
