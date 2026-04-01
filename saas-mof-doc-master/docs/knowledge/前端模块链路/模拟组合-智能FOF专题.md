---
tags:
  - simulate
  - smart-fof
  - recommendation
  - polling
status: active
updated: 2026-03-31
---

# 模拟组合智能 FOF 专题

## 1. 这个专题关注什么

这篇文档只看智能 FOF 这条链。

它覆盖：

- 问卷与推荐入口
- 参数调整与宏观框架
- 预设方案、精选推荐、回测、保存修改、正式建组合
- `rof_api` 与 `mof_api` 的双后端边界

## 2. 前端页面入口

关键路由：

- `/app/aifof/create/:type?/:id?`
- `/app/aifof/detail/:id`
- `/app/aifof/recommend`
- `/app/aifof/recommend/plans`
- `/app/aifof/recommend/:type/:id`
- `/app/aifof/edit/:type/:id`
- `/virtualFof/report/:id`

主要目录：

- `mof-web-fe/js/pages/aiFof/IntelligentFof`
- `mof-web-fe/js/pages/aiFof/Recommend`

## 3. 前端 API 入口

### 3.1 问卷与推荐导览

接口：

- `GET ${rof_api}/api/user/smartFof/questionnaire`
- `GET ${rof_api}/api/smartFof/industryCategory`
- `GET ${rof_api}/api/smartFof/smartFof/recommand`
- `POST ${rof_api}/api/smartFof/recommend/list`
- `GET ${rof_api}/api/smartFof/simulation/bestScenario/{id}`

这组接口说明：

- 问卷和精选推荐并不走 `mof_api`
- 前台推荐域和落地执行域已经分开

### 3.2 参数调整与宏观框架

关键文件：

- `mof-web-fe/js/pages/aiFof/IntelligentFof/components/Params/services.ts`
- `mof-web-fe/js/pages/aiFof/IntelligentFof/service.ts`
- `mof-web-fe/js/pages/aiFof/IntelligentFof/components/SaveParamsBtn/services.ts`

已确认接口：

- `POST ${mof_api}/api/smartFof/parameter/submit`
- `POST ${mof_api}/api/smartFof/indexMacroParam`
- `GET ${mof_api}/api/smartFof/modelDetails`
- `GET ${mof_api}/api/smartFof/param/modify/param_and_allocation/{id}`
- `POST ${mof_api}/api/smartFof/param/modify/param_and_allocation`
- `GET ${mof_api}/api/polling/{id}`

### 3.3 回测与建组合

关键文件：

- `mof-web-fe/js/pages/aiFof/IntelligentFof/components/Analysis/services.ts`
- `mof-web-fe/js/pages/aiFof/IntelligentFof/components/CreatPortfolioModal/services.ts`

已确认接口：

- `POST ${mof_api}/api/smartFof/simulation`
- `POST ${mof_api}/api/smartFof/creation`
- `POST ${mof_api}/api/assetAllocation/calcRebalancePeriods/v2`
- `GET ${mof_api}/api/allocation/mutual/{date}/{keyword}`
- `GET ${mof_api}/api/polling/{id}`

## 4. `mom` 后端入口

### 4.1 管理与落地组合

主 controller：

- `mom/mom-web/src/main/java/com/datayes/web/mom/assetallocation/smartfof/controller/SmartFofManagementController.java`

已确认接口：

- `POST /api/smartFof/creation`
- `DELETE /api/smartFof/delete`
- `GET /api/smartFof/editQuery`
- `POST /api/smartFof/edit/{reCal}`
- `POST /api/smartFof/subAssetAllocation/v2`
- `GET /api/smartFof/modelDetails`
- `POST /api/smartFof/indexMacroParam`

### 4.2 推荐池、预设方案与回测

主 controller：

- `mom/mom-web/src/main/java/com/datayes/web/mom/assetallocation/smartfof/controller/SmartFofScenarioController.java`

已确认接口：

- `POST /api/smartFof/parameter/submit`
- `POST /api/smartFof/questionnaire/cache`
- `POST /api/smartFof/refresh`
- `POST /api/smartFof/cache/evict`
- `GET /api/smartFof/cache/all`
- `GET /api/smartFof/bestScenario/all`
- `GET /api/smartFof/smartFof/recommand`
- `POST /api/smartFof/recommend/list`
- `GET /api/smartFof/simulation/{scenarioId}`
- `GET /api/smartFof/simulation/bestScenario/{scenarioId}`
- `POST /api/smartFof/simulation`
- `GET /api/smartFof/industryCategory`

### 4.3 参数修改专题

主 controller：

- `mom/mom-web/src/main/java/com/datayes/web/mom/assetallocation/smartfof/controller/SmartFofParamModificationController.java`

已确认接口：

- `GET /api/smartFof/param/modify/param_and_allocation/{accountId}`
- `POST /api/smartFof/param/modify/param_and_allocation`

## 5. 实现语义

### 5.1 智能 FOF 是一整套平台，不是单个推荐接口

当前源码已经显示出完整子系统：

- 问卷
- 行业分类
- 推荐池缓存
- 精选方案导览
- 自定义调参
- 宏观框架
- 回测
- 组合创建

### 5.2 参数调整是异步推荐链

`parameter/submit` 会：

- 补齐 `tenant` / `userId`
- 调用 `SmartFofRecommender.customRecommend`
- 通过 `@AsyncPolling("smartFof")` 返回异步结果

也就是说，用户“改参数”并不是简单本地重算，而是进入推荐引擎。

### 5.3 回测会补净值归因

`POST /api/smartFof/simulation` 不只返回回测净值：

- 若有 `scenarioId`，直接拿预设方案回测结果
- 若是自定义持仓，则构造 `SimulationPost`
- 随后调用 `SmartFofSimulationService.testReturn`
- 再通过 `NavAttributionManager` 补 `navAttribution`

这说明智能 FOF 回测结果天然包含：

- performance
- attribution

### 5.4 创建组合仍返回 `PmsDataAccountMapping`

`/api/smartFof/creation` 与资产配置落地逻辑一致，也进入了：

- `mom account`
- `pms portfolio`

的双标识体系。

## 6. 数据来源与外部依赖

### 6.1 当前可确认依赖

- `SmartFofRecommender`
  - 自定义推荐
- `SmartFofScenarioService`
  - 预设池、推荐列表、方案详情、缓存刷新
- `SmartFofScenarioStorage`
  - 推荐池缓存、迁移、S3 恢复
- `SmartFofSimulationService`
  - 回测
- `IndexMacroService`
  - 宏观指标参数
- `TradeDateCache`
  - 回测 quick view 时间补齐
- `NavAttributionManager`
  - 净值归因

### 6.2 当前可确认的数据边界

- `rof_api` 更偏问卷、推荐导览、精选列表
- `mof_api` 更偏参数修改、回测、创建组合、编辑组合

## 7. 公式与口径

智能 FOF 的公式风险点主要集中在三层：

- 推荐引擎口径
- 回测口径
- 净值归因口径

当前已确认的稳定约定：

- `macroIndexMethod` 会区分 `CLK` 与 `HISTORY`
- 宏观框架关闭时，前端会回退到历史数据口径
- 均值方差类模型需要同时传 `annualReturn` 和 `annualVolatility`
- 回测结果最终还会补 `navAttribution`

## 8. 重构时必须保留的契约

- 不要把 `rof_api` 与 `mof_api` 的职责边界抹平，它们现在承担不同业务阶段。
- `parameter/submit`、`simulation`、`creation` 三个动作必须继续解耦。
- `polling` 协议要保留，因为前端参数调整、回测、建组合都依赖它。
- 推荐池缓存、行业分类、问卷结果不能简单视为静态配置。

## 9. 待继续补充

- `SmartFofRecommender` 和 `SmartFofSimulationService` 再往下的算法依赖。
- `rof_api` 对应服务仓库中的 controller / service 锚点。
- 精选方案与自定义方案在结果结构上的差异字段。
