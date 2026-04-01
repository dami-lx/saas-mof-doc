---
tags:
  - moc
  - frontend
  - service-chain
  - knowledge-base
status: active
updated: 2026-03-31
---

# 前端模块链路 MOC

## 1. 这组文档解决什么问题

这组文档不是按仓库分目录，而是按前端实际可见的业务模块来组织知识。

它主要回答下面几类问题：

- 某个功能在前端从哪个页面进入。
- 页面发起了哪些 API 请求。
- 请求落到 `mom` 的哪个 controller / service。
- 是否继续下钻到 `pmsLite` 或 `brain`。
- 数据最终来自哪里。
- 这一类功能主要是“查询型能力”还是“计算型能力”，公式入口在哪里。

对不熟悉代码的人，这组文档应该能作为第一跳导航页；对未来重构的人，它应该能快速回答“这块能力到底属于哪个服务边界”。

## 2. 使用方法

推荐从“前端模块”进入，再顺着下面四层往下查：

1. 页面入口 / 路由
2. 前端 API 文件
3. `mom` 控制器与实现入口
4. 下游 `pms` / `brain` / 外部数据源

如果需要进一步看算法或卡片框架，再跳转到已有专题文档：

- [stockBrinson 全链路拆解](../stockBrinsonAttr-全链路拆解.md)
- [NavPerformanceOverviewTemplate 净值表现链路专题](../NavPerformanceOverviewTemplate-净值表现链路专题.md)
- [PMS_ELITE 穿透持仓与指标口径专题](../PMS_ELITE-穿透持仓与指标口径专题.md)
- [Brain 接口知识库 MOC](../brain/Brain-接口知识库-MOC.md)
- [Mom-Robo 接口知识库 MOC](../mom-robo/Mom-Robo-接口知识库-MOC.md)
- [Mof-Web-Fe 接口知识库 MOC](../mof-web-fe/Mof-Web-Fe-接口知识库-MOC.md)

## 3. 模块总览

| 前端模块 | 主要页面 / 路由入口 | 前端主要目录 | `mom` 主入口 | 下游依赖重点 | 文档 |
| --- | --- | --- | --- | --- | --- |
| 公募基金 | `/app/fund/product/filter/public`、`/app/fund/market/public`、`/report/:id(MUTUAL-.*)` | `js/pages/product/filter/publicV2`、`js/pages/fund-market/public-market`、`js/v2/pages/IndependentReport` | `/api/account/mutual`、`/api/card` | `rof` 搜索域、报告卡片、部分 `brain` 绩效/归因 | [公募基金模块链路](./公募基金模块链路.md) |
| 私募基金 | `/app/fund/product/filter/private`、`/app/fund/market/private`、`/report/:id(PRIVATE-.*)` | `js/pages/product/filter/privateV2`、`js/pages/fund-market/private-market`、`js/v2/pages/IndependentReport` | `/api/account/pfund`、`/api/card` | `rof` 搜索域、报告卡片、部分 `brain` 绩效/归因 | [私募基金模块链路](./私募基金模块链路.md) |
| 资产配置 | `/app/asset/*`、`/app/topbottom/*`、`/app/fund-allocation/*` | `js/pages/asset_new`、`js/pages/topbottom`、`js/pages/fund-allocation` | `/api/assetallocation`、`/api/allocation`、`/api/netValue` | 组合创建、再平衡、资产配置算法、`pmsLite` 组合映射 | [资产配置模块链路](./资产配置模块链路.md) |
| 模拟组合 | `/app/scenario/*`、`/scenario/report/:id?`、`/app/aifof/*`、`/virtualFof/report/:id` | `js/pages/scenario_new`、`js/pages/aiFof`、`js/v2/pages/IndependentReport` | `/api/scenario`、`/api/smartFof` | 情景分析、智能 FOF 推荐、回测、净值/归因 | [模拟组合模块链路](./模拟组合模块链路.md) |
| 投后 / AMS Pro | `/production2/*`、`/portfolio/*`、`/app/investedmanage/*`、`/running/:pageKey/:dashboardKey?` | `js/pages/production`、`js/v2/pages/Portfolio`、`js/pages/investedManage` | `/api/account/internal`、`/api/account/production`、`/pmsLite`、`/api/card` | `pmsLite` 持仓与导入、卡片报告、`brain` 绩效/归因 | [投后与 AMS Pro 模块链路](./投后与AMS-Pro模块链路.md) |

## 3.1 已展开的二级专题

当前已经开始把 `投后 / AMS Pro` 继续拆成可独立查询的二级专题：

- [投后与 AMS Pro 组合总览专题](./投后与AMS-Pro-组合总览专题.md)
- [投后与 AMS Pro 数据导入专题](./投后与AMS-Pro-数据导入专题.md)
- [投后与 AMS Pro 监控专题](./投后与AMS-Pro-监控专题.md)
- [投后与 AMS Pro 业绩分析与报告专题](./投后与AMS-Pro-业绩分析与报告专题.md)
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
- [投后与 AMS Pro 页面动作与请求模型对照表](./投后与AMS-Pro-页面动作与请求模型对照表.md)

公募 / 私募模块也已经开始展开二级专题：

- [公募基金筛选专题](./公募基金-筛选专题.md)
- [公募基金市场专题](./公募基金-市场专题.md)
- [公募基金报告专题](./公募基金-报告专题.md)
- [公募基金页面动作与请求模型对照表](./公募基金-页面动作与请求模型对照表.md)
- [私募基金筛选专题](./私募基金-筛选专题.md)
- [私募基金市场专题](./私募基金-市场专题.md)
- [私募基金报告专题](./私募基金-报告专题.md)
- [私募基金页面动作与请求模型对照表](./私募基金-页面动作与请求模型对照表.md)

资产配置模块已展开二级专题：

- [资产配置研究与创建专题](./资产配置-研究与创建专题.md)
- [资产配置落地组合与编辑专题](./资产配置-落地组合与编辑专题.md)
- [资产配置子类资产与再平衡专题](./资产配置-子类资产与再平衡专题.md)
- [资产配置页面动作与请求模型对照表](./资产配置-页面动作与请求模型对照表.md)

模拟组合模块已展开二级专题：

- [模拟组合情景管理专题](./模拟组合-情景管理专题.md)
- [模拟组合情景回测与报告专题](./模拟组合-情景回测与报告专题.md)
- [模拟组合智能 FOF 专题](./模拟组合-智能FOF专题.md)
- [模拟组合页面动作与请求模型对照表](./模拟组合-页面动作与请求模型对照表.md)

## 4. 需要单独看待的“跨模块平台层”

这部分不应该被简单归入某一个业务模块，但几乎所有模块都会经过它：

### 4.1 报告 / 卡片平台

前端入口：

- `mof-web-fe/js/v2/routes.ts`
- `mof-web-fe/js/v2/pages/IndependentReport/PageRouter/index.tsx`
- `mof-web-fe/js/pages/custom-report/*`

后端入口：

- `mom/mom-web/src/main/java/com/datayes/web/mom/card/CardViewController.java`
- `mom/mom-web/src/main/java/com/datayes/web/mom/card/CardDataController.java`

下游依赖：

- `pms` / `pmsLite` 提供持仓、组合、导入、估值等底层数据
- `brain` 提供净值表现、归因、风格、风险、压力测试等计算

推荐阅读：

- [Mof-Web-Fe 卡片报告框架与前后端契约专题](../mof-web-fe/Mof-Web-Fe-卡片报告框架与前后端契约专题.md)
- [Brain 任务编排与执行链](../brain/Brain-任务编排与执行链.md)

### 4.2 组合管理平台

前端入口：

- `mof-web-fe/js/v2/pages/Portfolio/*`
- `mof-web-fe/js/modules/portfolio/*`

后端入口：

- `mom/mom-web/src/main/java/com/datayes/web/ams/controller/PortfolioController.java`

下游依赖：

- `pmsLite` 组合主数据
- `mom` 里的净值型组合 / 资产配置 / 智能 FOF 适配层

推荐阅读：

- [PMS_ELITE 接口总览与模块边界](../pms-elite/PMS_ELITE-接口总览与模块边界.md)
- [PMS_ELITE Position 模块专题](../pms-elite/PMS_ELITE-Position模块专题.md)

## 5. 当前已确认的结构性结论

- `mof-web-fe` 的一级模块和后端服务边界并不一一对应，同一页面域经常同时调用 `mom`、`pmsLite` 和卡片平台。
- “列表筛选型页面”和“报告分析型页面”虽然都在同一业务模块里，但实现链路完全不同。
- `投后 / AMS Pro` 是最典型的“双链路模块”：
  - 主数据、持仓、导入、调仓以 `pmsLite` 为主
  - 业绩分析、归因、报告导出又会重新回到 `mom` 卡片和 `brain`
- `资产配置`、`模拟组合`、`智能 FOF` 的创建和编辑接口虽然看上去是前端页面能力，本质上都在创建 `mom account` 与 `pms portfolio` 的映射关系。

## 6. 当前已完成与下一步

### 6.1 已完成

- 建立按前端业务模块出发的总导航。
- 为五个模块建立统一知识模板。
- 第一轮补齐了各模块的页面入口、前端 API 锚点、`mom` 控制器锚点和主要下游方向。

### 6.2 下一步建议

1. 继续把每个模块里的“页面 -> API 文件 -> controller -> service -> 数据源”补成二级清单。
2. 把“公式 / 口径”单独做成每篇文档里的固定章节，避免散落在实现说明里。
3. 对 `投后 / AMS Pro` 再拆成：
   - 组合总览
   - 数据导入
   - 监控
   - 业绩分析 / 报告
4. 对 `公募基金`、`私募基金` 补“页面筛选字段 -> 后端查询字段 -> ES/缓存/标签”的映射。
5. 对 `资产配置`、`模拟组合` 继续补“页面按钮动作 -> 请求模型 -> service 实现 -> 数据源”的细粒度映射。
