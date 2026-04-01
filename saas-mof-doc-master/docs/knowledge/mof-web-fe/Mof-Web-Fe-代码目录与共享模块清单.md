---
tags:
  - mof-web-fe
  - frontend
  - inventory
  - modules
status: active
updated: 2026-03-27
---

# Mof-Web-Fe 代码目录与共享模块清单

## 1. 目录总观

`mof-web-fe` 的代码组织不是标准单层 React 工程，而是多类职责并存：

- 应用壳
- 历史页面
- 新一代页面
- 平台组件
- 业务共享模块
- API 客户端
- Storybook 文档

从重构角度看，目录的价值不在“物理位置”，而在“职责意图”。

## 2. 核心目录职责

### 2.1 `framework/`

定位：

- 卡片平台与布局平台

已确认内容：

- `components/Card`
- `components/CardGrid`
- `components/Loader`
- `components/dashboardLib`
- `utils/api/card.ts`

这一层不应简单视为普通组件库，它实际上承担：

- 卡片懒加载
- 卡片布局管理
- 卡片配置持久化
- Dashboard 类能力

### 2.2 `js/app/`

定位：

- 应用运行时壳层

主要职责：

- 启动与应用装配
- 路由生成
- Redux store
- 权限体系
- 全局弹窗与外挂能力
- 配置读取与全局 ajax 底座

这是整个前端最接近“平台内核”的部分。

### 2.3 `js/pages/`

定位：

- 第一代业务页面树

已确认覆盖的业务目录包括：

- `product`
- `company`
- `manage`
- `fund`
- `fund-market`
- `mom`
- `asset_new`
- `scenario_new`
- `aiFof`
- `investedManage`
- `production`
- `production-old`
- `risk-control`
- `custom-report`
- `my-research`
- `private-assets`
- `due-diligence`
- `strategy`
- `etf`
- `portfolio-report`
- `trial-balance`

这层更多代表业务入口面。

### 2.4 `js/v2/`

定位：

- 新一代报告、组合与 Dashboard 页面

已确认主要页面簇：

- `Dashboard2`
- `IndependentReport`
- `Portfolio/*`
- `Report`
- `PublicReport`
- `simple-report`
- `index-report`
- `virtual-fof-report`
- `CombiningMonitor`

这层更多代表新一代页面模型和卡片模型。

### 2.5 `js/components/`

定位：

- 横跨全仓的基础业务组件层

这里既有通用 UI，也有带强业务语义的组件，例如：

- 筛选器
- 卡片头部
- 表格封装
- benchmark 选择器
- 行业选择器
- 导出组件
- cards-flow
- echarts/highcharts 封装

因此不能把它等同为纯视觉组件库。

### 2.6 `js/modules/`

定位：

- 共享业务模块层

这部分很重要，因为它比 `js/components` 更接近“可复用业务能力”。

已确认的典型模块包括：

- `asset-allocation`
- `portfolio`
- `portfolio-penetrate`
- `production`
- `report`
- `report-simple`
- `risk-control-report-common`
- `table-page-common`
- `market-analysis`
- `pool`
- `strategy`
- `product`
- `data-management`
- `historical-document`
- `prompts-polling`

这部分很适合作为未来“前端 bounded context”拆分参考。

### 2.7 `js/api/`

定位：

- 多后端域 typed API 客户端层

详见《状态管理与数据请求专题》。

### 2.8 `js/hooks/`

定位：

- 横跨页面的逻辑复用层

可将其视为“轻量应用服务”。

### 2.9 `style/`

定位：

- 全局 less、主题和历史样式资产

### 2.10 `storybook/` 与 `docs/`

定位：

- 组件说明、开发规范、调试载体

Storybook 不只是文档展示，也被用来独立调试卡片与组件。

### 2.11 `tools/`

定位：

- 辅助生成与工程治理工具

已确认内容包括：

- 自定义 eslint rules
- 路由/模板辅助脚本
- 上传模板脚本

## 3. 共享模块的重构意义

`js/modules/*` 是当前仓库里最值得重点梳理的一层，因为它们通常不是“页面专属代码”，而是被多个页面重用的业务能力。

可粗分为以下几类。

### 3.1 组合与资产配置类

- `asset-allocation`
- `portfolio`
- `portfolio-penetrate`
- `valuation-step-table`

### 3.2 报告与卡片类

- `cards`
- `report`
- `report-simple`
- `calculate-custom`
- `prompts-polling`

### 3.3 数据管理与导入导出类

- `data-management`
- `batch-create`
- `batch-update`
- `export-list-all`
- `custom-rate-export`
- `import-overview`
- `file-upload-log`

### 3.4 风控与通用表页类

- `risk-control-report-common`
- `table-page-common`

### 3.5 研究与市场分析类

- `market-analysis`
- `related-news-common`
- `private-fund-search`

这些模块未来很适合从“共享 React 代码”升级为“明确的前端领域包”。

## 4. `framework` 与 `js/modules` 的区别

这是当前仓库里非常容易混淆的一点。

### 4.1 `framework`

更偏平台基础设施，关注：

- 卡片生命周期
- 卡片布局
- 配置持久化
- dashboard 能力

### 4.2 `js/modules`

更偏可复用业务能力，关注：

- 某类页面/业务块的复用
- 与具体业务实体相关的数据加载和交互

未来重构时，建议把这两层继续分开：

- `framework` -> 平台能力层
- `modules` -> 业务能力层

## 5. 文档与规范体系

仓库内已有一套轻量工程文档：

- `docs/introduction.stories.mdx`
- `docs/spec.stories.mdx`
- `docs/faq.stories.mdx`
- `docs/antd.md`

其价值主要是：

- 统一开发规范
- 支持组件独立调试
- 给团队留出知识沉淀入口

这说明团队已有“文档伴随代码演化”的意识，只是还缺少面向系统重构的高层知识结构。

## 6. 对未来重构的拆分建议

按当前目录职责，未来可优先考虑拆成如下逻辑包：

1. `portal-shell`
2. `report-runtime`
3. `portfolio-app`
4. `fund-research-app`
5. `shared-domain-modules`
6. `ui-and-chart-kit`
7. `api-clients`

## 7. 当前确认与待补充

### 7.1 已确认

- `framework` 是平台层，不是普通组件目录。
- `js/app` 是应用壳。
- `js/pages` 与 `js/v2` 是双代页面并存。
- `js/modules` 是非常重要的共享业务层。

### 7.2 待补充

- 各 `js/modules` 的页面引用面统计。
- `js/v2/cards` 的专题清单。
- `framework` 与模块联邦/远程模块之间的真实耦合关系。
