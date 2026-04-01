---
tags:
  - mom-robo
  - controller
  - module
  - inventory
  - refactor
status: active
updated: 2026-03-27
---

# Mom-Robo 控制器与模块清单

## 1. 用途

这篇文档不是逐个 endpoint 的流水账，而是做“控制器索引”。

适合以下场景：

- 你已经知道某个接口大概属于哪个业务域，想快速定位 controller
- 你在准备做服务拆分，需要先看每个模块暴露了哪些 controller
- 你想知道某个 API 前缀大概率落在哪个 Maven 模块

## 2. 模块级 controller 数量

- `mom-web`: 180
- `mom-legacy`: 27
- `mom-portfolio-service`: 14
- `mom-private-asset-service`: 6
- `mom-user`: 5
- `mom-lib`: 5
- `mom-h5`: 5
- `mom-workflow`: 1
- `mom-fundpool`: 4
- `mom-saas`: 18
- `mom-datayesir`: 3
- `mom-ai-api`: 1
- `due-diligence`: 1

## 3. 关键模块索引

## 3.1 `mom-web`

主要职责：

- 主业务 API 门户

高频 controller 分组：

### 账户与筛选

- `AccountSearchController` -> `/api/accounts`
- `AccountController` -> `/api/accounts`
- `AccountSearchExportController` -> `/api/accounts/export`
- `MutualSearchController` -> `/api/account/mutual`
- `PrivateFundSearchController` -> `/api/account/pfund`
- `InternalAccountSearchController` -> `/api/account/internal`
- `RealComputeController` -> `/api/compute`
- `SelectedPoolController` -> `/api/account/selectedPool`

### 卡片与报告

- `CardViewController` -> `/api/card`
- `CardDataController` -> `/api/card`
- `CardController` -> `/api/card`
- `CardViewDataController` -> 卡片视图数据
- `ReportCardTemplateController` -> `/api/report/card/template`
- `ReportTemplateController` -> 报告模板
- `CardViewCacheEvictController` -> `/api/card/cache`

### 资产配置

- `UpBottomAssetAllocationController` -> `/api/assetallocation`
- `NetValueController` -> `/api/netValue`
- `AllocationSearchController` -> `/api/allocation`
- `SmartFofManagementController` -> `/api/smartFof`
- `SmartFofBrainController` -> `/api/smartFof/brain`

### 基础对象与研究页

- `FundManagerController` -> `/api/fundManager`
- `FundCompanyController` -> `/api/fundCompany`
- `SecurityController` -> `/api/security`
- `BenchmarkCommonController` -> `/api/benchmark`
- `IndustryAllocationController` -> `/api/industryAllocation`
- `IndicatorController` -> `/api/v1/indicator`
- `FamaFrenchController` -> `/api/card/famaFrench`

### 风控与运维

- `RcPlanController` -> `/api/rc/plan`
- `RcReportController` -> `/api/rc/report`
- `TaskController` -> `/api/task`
- `TaskResultController` -> `api/task`
- `RefreshController` -> `/api/refresh`
- `ProjectDebugController` -> `/debug`

## 3.2 `mom-legacy`

主要职责：

- 历史接口保留层

代表 controller：

- `AttributionController` -> `/api/attribution`
- `AccountAttributionController` -> `/api/account/attribution`
- `StrategyPerfController` -> `/api/strategy`
- `RiskControlController` -> `/api/riskControl`
- `MarketEventController`
- `BenchmarkController`
- `SimulateAccountController`
- `ValuationRecordController`
- `AccountExportController`
- `FeedbackController`

重构提示：

- 这部分非常值得单独做“兼容层清单”

## 3.3 `mom-portfolio-service`

主要职责：

- 投后/PMS_ELITE 产品域

代表 controller：

- `PortfolioEliteController` -> `/api/portfolio`
- `PortfolioAccountSearchController` -> `/api/portfolio`
- `PortfolioEliteTransactionController` -> `/api/portfolio`
- `PortfolioEliteIndicatorController` -> `/api/portfolio`
- `PortfolioDividendController` -> `/api/portfolio/dividend`
- `PortfolioTenantConfigController` -> `/api/portfolio/tenant/config`
- `PortfolioTryCalcController` -> `/api/portfolio/tryCalc`
- `PortfolioEliteTransferController` -> `/api/portfolio`
- `PortfolioBondRatingController`
- `PortfolioImportTypeController`
- `PortfolioEliteRealtimeController`
- `PortfolioEliteAuthController`
- `PortfolioAccountSearchExportController`
- `MSRSPortfolioController` -> `/api/portfolio/msrs`

## 3.4 `mom-private-asset-service`

主要职责：

- 私有资产专属域

代表 controller：

- `PrivateAssetController`
- `PrivateAssetExternalController` -> `/api/account/passet/external`
- `PrivateAssetExportController` -> `/api/account/passet/list`
- `PrivateAssetDividendController` -> `/api/v1/asset/dividend`
- `PrivateAssetLogCenterController` -> `/api/private/asset/`
- `PrivateAssetTestController` -> `/api/account/passet/test`

## 3.5 `mom-user`

主要职责：

- 权限、角色、租户、数据分享

代表 controller：

- `PrivilegeController` -> `/api/privilege`
- `RoleController` -> `/api/privilege/role`
- `UserPrivilegeController`
- `GlobalPrivilegeController` -> `/api/privilege`
- `DataAuthController` -> `/api/dataAuth`

## 3.6 `mom-lib`

主要职责：

- 面向外部系统或外部库的标准化接口

代表 controller：

- `LibPortfolioController` -> `/lib/portfolio`
- `LibSimulatePortfolioController` -> `/lib/simulate/portfolio`
- `LibAssetController` -> `/lib/asset`
- `LibPollingController` -> `/lib/common`
- `LibMonitorController` -> `/lib/monitor`

## 3.7 `mom-h5`

主要职责：

- H5 / App 轻端接口

代表 controller：

- `H5PortfolioController`
- `H5CardReportController`
- `H5UserController`
- `AppEtfController`
- `EtfFundComputeController`

## 3.8 `mom-workflow`

主要职责：

- 审批与工作流

代表 controller：

- `WorkflowController` -> `/api/v1/workflow`

## 3.9 `mom-saas`

主要职责：

- SaaS / 客户化 / 行业化专题接口

代表 controller：

- `VipReportController`
- `VipReportExportController`
- `VipReportViewController`
- `FeatureSearchSaasController`
- `FeatureSearchAttrController`
- `SectionReportController`
- `HongTaController`
- `HongTaConfigController`
- `RrpController`
- `SearchClientController`

## 3.10 其他外围模块

- `mom-fundpool`:
  - `FundPoolController`
  - `FundPoolListExportController`
  - `FundPoolOperateController`
  - `FundPoolOperateRecordController`
- `mom-datayesir`:
  - `MutualFundDataController`
  - `MutualFundDatayesirController`
  - `GuangdaPocController`
- `mom-ai-api`:
  - `AiSelectSqlController`
- `due-diligence`:
  - `DueDiligenceController`

## 4. API 前缀到模块的大致映射

下面这组映射适合做快速反查。

- `/api/card*` -> 主要在 `mom-web`
- `/api/report/card/template*` -> `mom-web`
- `/api/account/mutual*` -> `mom-web`
- `/api/account/pfund*` -> `mom-web`
- `/api/accounts*` -> `mom-web`
- `/api/assetallocation*` -> `mom-web`
- `/api/smartFof*` -> `mom-web`
- `/api/fundManager*` / `/api/manager*` -> `mom-web`
- `/api/benchmark*` -> `mom-web`
- `/api/rc*` -> `mom-web`
- `/api/portfolio*` -> `mom-portfolio-service`
- `/api/account/passet*` -> `mom-private-asset-service`
- `/api/dataAuth` / `/api/privilege*` -> `mom-user`
- `/lib/*` -> `mom-lib`
- `/api/v1/workflow*` -> `mom-workflow`

## 5. 对未来重构的直接价值

这份索引最重要的价值不是“知道 controller 文件在哪”，而是帮助回答下面三个问题：

1. 某个前端接口到底属于哪个业务域。
2. 某个业务域目前分散在哪些模块。
3. 如果要拆服务，哪一组 controller 可以先一起搬走。

## 6. 一句话结论

`mom-robo` 的 controller 虽然很多，但并不是无序分布；只要先按模块和 API 前缀建立索引，再按业务域归类，整体结构就会清晰很多，也更适合作为后续重构和服务拆分的知识底稿。
