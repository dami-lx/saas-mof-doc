---
tags:
  - mom-robo
  - api
  - business-domain
  - refactor
status: active
updated: 2026-03-27
---

# Mom-Robo API 按业务分类

## 1. 分类原则

这篇文档不是按源码目录分类，而是按“前端真正感知到的业务域”分类。

原因是：

- `mom-robo` 的 controller 分散在多个模块
- 同一业务域的接口往往横跨多个包
- 如果只按模块看，很难直接支持未来 API 重构

因此这里采用的分类原则是：

1. 用户在产品里看到的业务对象是什么。
2. 这组接口围绕什么业务动作展开。
3. 未来是否可能拆成独立服务域。

## 2. 分类总览

当前我建议把 `mom-robo` 的 API 面划成 10 个业务域：

1. 账户/基金/产品搜索与筛选
2. 报告卡片与评价页
3. 资产配置、模拟组合与情景分析
4. 投后/PMS_ELITE 产品管理
5. 私有资产
6. 基金经理、基金公司、证券、基准与行业模型
7. 用户、权限、标签、分组与协作
8. 风控、事件监控与指标
9. 工作流、导入导出、任务、缓存、迁移、运维
10. 外部库、H5、SaaS、AI 与其他外围接口

## 3. 账户/基金/产品搜索与筛选

这是 `mom-robo` 最典型的前台业务域之一，主要解决“找基金、找产品、保存筛选方案、导出列表”的问题。

### 3.1 公募基金筛选

代表 controller：

- `MutualSearchController`
- `DynamicFilterFieldController`
- `MutualFundAssociateSearchController`
- `QueryPlanController`
- `ExportMutualListController`

代表 base path：

- `/api/account/mutual`
- `/api/account/mutual/plans`
- `/api/mutual/export`

能力特征：

- 普通筛选
- 高级筛选
- 动态筛选
- 联想搜索
- 方案保存
- 列表导出

### 3.2 私募基金筛选

代表 controller：

- `PrivateFundSearchController`
- `PrivateFundDynamicFilterController`
- `PrivateFundAssociateSearchController`
- `PrivateFundQueryPlanController`
- `ExportPrivateListController`

代表 base path：

- `/api/account/pfund`
- `/api/account/pfund/plans`
- `/api/private/export`

### 3.3 投后/内部产品筛选

代表 controller：

- `InternalAccountSearchController`
- `ProductionAccountController`
- `AccountSearchController`
- `AccountSearchExportController`
- `ExportAccountListController`

代表 base path：

- `/api/account/internal`
- `/api/account/production`
- `/api/accounts`
- `/api/accounts/export`
- `/api/hybrid/export`

### 3.4 实时计算筛选

代表 controller：

- `RealComputeController`
- `RealComputeQueryPlanController`

代表 base path：

- `/api/compute`
- `/api/compute/account/plans`

### 3.5 关注池/精选池/推荐池

代表 controller：

- `FundPoolSearchController`
- `SelectedPoolController`
- `SelectedPoolExportController`
- `AiFundPoolController`

代表 base path：

- `/api/pool`
- `/api/account/selectedPool`
- `/api/ai/recommend`

## 4. 报告卡片与评价页

这是 `mom-robo` 最值得单独建模的核心域之一，因为它直接连接前端展示和 `brain`/`pms` 等下游计算链路。

### 4.1 卡片计算与报告生成

代表 controller：

- `CardViewController`
- `CardDataController`
- `CardController`
- `CardViewDataController`

代表 base path：

- `/api/card`

业务特征：

- 自定义评价报告
- 卡片计算
- 结果视图
- 卡片辅助数据

### 4.2 模板管理

代表 controller：

- `ReportCardTemplateController`
- `ReportTemplateController`
- `WealthReportTemplateController`

代表 base path：

- `/api/report/card/template`
- `/api/report/template`

业务特征：

- 模板增删改查
- 模板分享
- 模板与产品绑定
- 财富版模板

### 4.3 卡片缓存

代表 controller：

- `CardViewCacheController`
- `CardViewCacheEvictController`
- `AccountReportCacheController`
- `AttributionReportCacheController`

代表 base path：

- `/api/card/cache`
- `/api/report/cache`
- `/api/attribution/cache`

### 4.4 细分卡片专题接口

代表 controller：

- `NetAnalysisController`
- `EquityHoldingAnalysisController`
- `BondHoldingAnalysisController`
- `BottomHoldingAnalysisController`
- `RelatedAccountController`
- `BondStressTestController`
- `FundNavEstimationController`
- `AnnouncementController`

这些接口说明卡片系统并不是一组模板管理接口，而是已经沉淀成一个完整的“报告装配平台”。

## 5. 资产配置、模拟组合与情景分析

这一类接口主要围绕“构建组合方案、调参、回测、编辑、查看模型结果”。

### 5.1 自上而下资产配置

代表 controller：

- `UpBottomAssetAllocationController`

代表 base path：

- `/api/assetallocation`

核心能力：

- 标的范围
- 基准查询
- 组合创建/编辑/删除
- 子类资产算法
- 模型详情

### 5.2 净值型组合

代表 controller：

- `NetValueController`

代表 base path：

- `/api/netValue`

### 5.3 通用方案查询

代表 controller：

- `AllocationSearchController`
- `AllocationStepTimeController`

代表 base path：

- `/api/allocation`

### 5.4 智能 FOF

代表 controller：

- `SmartFofManagementController`
- `SmartFofScenarioController`
- `SmartFofBrainController`
- `SmartFofParamModificationController`

代表 base path：

- `/api/smartFof`
- `/api/smartFof/brain`
- `/api/smartFof/param/modify`

### 5.5 模拟与 PK / 场景

代表 controller：

- `SimulationAccountController`
- `ScenarioController`
- `PKController`
- `ComparePlanController`

这类接口本质上都属于“方案比较与场景分析”。

## 6. 投后 / PMS_ELITE 产品管理

这是另一组边界清晰、非常适合独立服务化的域。

主要来源模块：

- `mom-portfolio-service`
- 部分 `mom-web` / `web.ams`

### 6.1 投后产品管理

代表 controller：

- `PortfolioEliteController`
- `PortfolioAccountSearchController`
- `PortfolioEliteTransactionController`
- `PortfolioEliteIndicatorController`
- `PortfolioDividendController`
- `PortfolioTenantConfigController`
- `PortfolioTryCalcController`
- `PortfolioEliteTransferController`

代表 base path：

- `/api/portfolio`
- `/api/portfolio/dividend`
- `/api/portfolio/tenant/config`
- `/api/portfolio/tryCalc`

核心能力：

- 产品创建、批量创建、编辑、删除
- 组合详情
- 持仓和净值查询
- 交易录入
- 实时指标
- 分红配置
- 试算报告
- 迁移与回滚

### 6.2 投后辅助/兼容接口

代表 controller：

- `PortfolioController`
- `PortfolioAuthController`
- `AmsTaskController`
- `TableFieldController`

代表 base path：

- `/pmsLite`
- `/ams/task`
- `/ams/table`

这说明系统里同时存在：

- 新投后域接口
- 兼容历史 AMS / PMSLite 形式的接口

## 7. 私有资产

主要来源模块：

- `mom-private-asset-service`

代表 controller：

- `PrivateAssetController`
- `PrivateAssetExternalController`
- `PrivateAssetExportController`
- `PrivateAssetDividendController`
- `PrivateAssetLogCenterController`
- `PrivateAssetTestController`

代表 base path：

- `/api/account/passet`
- `/api/account/passet/external`
- `/api/account/passet/list`
- `/api/v1/asset/dividend`
- `/api/private/asset/`

业务特征：

- 私有资产列表和详情
- 外部客户接口
- 导出
- 分红
- 导入日志
- 测试导入

## 8. 基金经理、基金公司、证券、基准与行业模型

这组接口都属于“研究对象页 / 基础市场对象查询”。

### 8.1 基金经理

代表 controller：

- `FundManagerController`
- `ManagerListController`
- `ManagerDynamicFilterFieldController`
- `ManagerAssociateSearchController`
- `MutualManagerQueryPlanController`
- `ManagerReportController`
- `ManagerFitNetValueController`
- `FundManagerTagController`

代表 base path：

- `/api/fundManager`
- `/api/manager/mutual`
- `/api/manager/report`
- `/api/manager/fitnv`
- `/api/fundManager/tag`

### 8.2 基金公司

代表 controller：

- `FundCompanyController`

代表 base path：

- `/api/fundCompany`

### 8.3 证券

代表 controller：

- `SecurityController`
- `AmsSecurityController`
- `SecuritySearchController`

代表 base path：

- `/api/security`
- `/ams`

### 8.4 基准与行业模型

代表 controller：

- `BenchmarkCommonController`
- `BenchmarkIndexController`
- `BenchmarkCustomManageController`
- `BenchmarkPerfController`
- `BenchmarkIndexReportController`
- `BenchmarkDrawdownController`
- `BenchmarkHYHZController`
- `IndustryAllocationController`
- `IndustryCacheManagerController`

代表 base path：

- `/api/benchmark`
- `/api/v1/benchmark/index`
- `/api/benchmark/management`
- `/api/benchmarkPerf`
- `/api/industryAllocation`
- `/api/industryCacheManager`

### 8.5 指标与分析小专题

代表 controller：

- `IndicatorController`
- `FamaFrenchController`
- `FeatureSearchController`
- `MarketAnslysisCardController`

## 9. 用户、权限、标签、分组与协作

这组接口解决的是“谁能看、怎么分组、怎么打标签、怎么协作”。

### 9.1 权限与租户

主要来源模块：

- `mom-user`
- 部分 `mom-web`

代表 controller：

- `PrivilegeController`
- `RoleController`
- `UserPrivilegeController`
- `GlobalPrivilegeController`
- `DataAuthController`
- `OldPrivilegeController`

代表 base path：

- `/api/privilege`
- `/api/privilege/role`
- `/api/dataAuth`

### 9.2 用户配置与分组

代表 controller：

- `UserController`
- `UserConfigController`
- `GroupController`
- `SharedGroupController`
- `GroupPermissionController`
- `LayerGroupController`

### 9.3 标签体系

代表 controller：

- `UserTagManagerController`
- `UserAccountTagController`
- `UserTagLevelController`
- `TagImportController`
- `UserTagMigrateController`
- `FundManagerTagController`

### 9.4 其他协作类接口

代表 controller：

- `UserNoteController`
- `QuestionnaireController`
- `MarkingController`
- `MarkingTemplateController`

## 10. 风控、事件监控与指标

这类接口主要集中在 `mom-web` 和 `mom-legacy`。

代表 controller：

- `RcPlanController`
- `RcReportController`
- `RcIndexController`
- `RcTemplateController`
- `RcAssetTypeController`
- `RcMutualEventController`
- `EventMetricController`
- `RiskControlController`（legacy）
- `RiskTaskController`（legacy）

代表 base path：

- `/api/rc/plan`
- `/api/rc/report`
- `/api/rc/index`
- `/api/rc/template`
- `/api/rc/mutual/event`
- `/api/v1/event/metric`
- `/api/riskControl`

## 11. 工作流、导入导出、任务、缓存、迁移、运维

这是很容易在重构时被忽略，但实际上非常关键的一类横切域。

### 11.1 工作流

代表 controller：

- `WorkflowController`

代表 base path：

- `/api/v1/workflow`

### 11.2 导入导出

代表 controller：

- `AccountUploadController`
- `ImportLogController`
- `UploadController`
- `DownloadController`
- 各类 `Export*Controller`

### 11.3 任务与轮询

代表 controller：

- `TaskController`
- `TaskResultController`
- `RefreshController`
- `AccountRefreshMutualTaskController`
- `LibPollingController`

代表 base path：

- `/api/task`
- `/api/refresh`
- `/lib/common`

### 11.4 缓存、迁移、调试、运维

代表 controller：

- `CardViewCacheEvictController`
- `CardViewCacheController`
- `AttributionReportCacheController`
- `AccountReportCacheController`
- `ProjectDebugController`
- `BackdoorController`
- `PortfolioDebugController`
- `EsDataRefreshController`
- `MongoDataMigrateController`
- `FundManagerRefreshController`
- `EsErrorDataRefreshController`

这类接口说明 `mom-robo` 同时承载了不少“业务后台运维台”角色。

## 12. 外部库、H5、SaaS、AI 与其他外围接口

## 12.1 外部库接口

主要来源模块：

- `mom-lib`

代表 base path：

- `/lib/portfolio`
- `/lib/simulate/portfolio`
- `/lib/asset`
- `/lib/monitor`

## 12.2 H5 / App

主要来源模块：

- `mom-h5`

代表 controller：

- `H5PortfolioController`
- `H5CardReportController`
- `H5UserController`
- `AppEtfController`
- `EtfFundComputeController`

## 12.3 SaaS / 客户化

主要来源模块：

- `mom-saas`

代表 controller：

- `VipReportController`
- `SectionReportController`
- `FeatureSearchSaasController`
- `HongTaController`
- `RrpController`

## 12.4 AI

代表 controller：

- `AiReportCardController`
- `AiReportDataController`
- `AiSelectSqlController`

## 13. 重构视角下的建议拆分顺序

如果以后要按业务域拆服务，我建议优先按下面顺序识别边界：

1. `投后/PMS_ELITE`
2. `私有资产`
3. `账户/基金搜索筛选`
4. `报告卡片与模板系统`
5. `权限与标签协作`
6. `风控与事件`
7. `工作流与后台任务`

理由是：

- 这些域的 controller 集合比较清晰
- 对前端而言业务语义也比较稳定
- 下游依赖差异明显，更适合逐步服务化

## 14. 一句话结论

`mom-robo` 的 API 面虽然很大，但从业务上看并不是无序堆积，而是围绕“搜索筛选、报告卡片、资产配置、投后、私有资产、权限协作、风控运维”这几大核心域展开；未来重构时应优先按这些业务域建边界，而不是按现有 controller 包名机械拆分。
