---
tags:
  - mof-web-fe
  - frontend
  - architecture
  - refactor
status: active
updated: 2026-03-27
---

# Mof-Web-Fe 工程总览与技术栈

## 1. 仓库定位

`mof-web-fe` 是整个系统的前端门户仓库，承接了基金筛选、资产配置、投后管理、组合分析、报告卡片、尽调、私有资产、ETF、风控等多个业务域。

虽然仓库名是 `mof-web-fe`，但 `package.json` 中包名仍然是 `mom`，仓库说明也写的是“萝卜投资魔方模块”。这说明它不是一个纯技术中台前端，而是从历史 `mom` 业务逐步演化出的“全站前端聚合层”。

对于未来重构，应该把它视为：

- 一个前端门户壳层
- 一个多业务域路由聚合器
- 一个报告/卡片运行平台
- 一个跨多个后端域的 BFF 消费端

## 2. 核心技术栈

从 `package.json` 可以确认当前主栈如下：

- React 17
- React Router 5
- Redux 4
- Redux Saga 1.1
- Redux Thunk 2.3
- Ant Design 5
- Axios 0.23
- Dayjs
- Styled Components 6
- ECharts 5
- Highcharts 7
- Storybook 6
- TypeScript 5.2
- 构建工具以 `@ams/mesh` 为中心，可切换 `vite / webpack / rspack`
- 运行环境要求 `node >= 18`

工程脚本显示出明显的多构建器并行历史：

- `pnpm start` 走 `mesh start -b vite`
- `pnpm start:webpack`
- `pnpm start:rspack`
- `pnpm doc` 启动 storybook
- `pnpm type-check`
- `pnpm test`

这意味着当前仓库仍处在“新旧工具链并存”阶段，未来重构时可以优先把构建标准化，但不应假设所有页面都已经完全适配单一 bundler。

## 3. 运行时启动链路

前端主启动链路如下：

```text
js/bootstrap.tsx
  -> js/app/application.tsx
  -> js/app/components/root/index.tsx
  -> js/app/routes.tsx
  -> js/pages/nav.ts + js/v2/routes.ts
```

其中关键职责为：

- `js/bootstrap.tsx`
  - 初始化 Sentry
  - 装配 `navs`
  - 渲染最外层 `App`
- `js/app/application.tsx`
  - 初始化 dayjs 插件
  - 注入 Redux store
  - 注入 `ConnectedRouter`
- `js/app/components/root/index.tsx`
  - 等待权限初始化完成
  - 根据 `navs` 生成实际路由
  - 注入 `ConfigProvider / ThemeProvider / GlobalStyle`
  - 统一挂载外部运行时组件，如登录、权限弹窗、风险提示、通知等
- `js/app/routes.tsx`
  - 将导航配置转换为 React Router Route
  - 统一处理权限校验、Bundle 包装、三级导航渲染和默认重定向

因此，重构时应把“页面入口”与“运行时壳层”分开理解：

- 页面入口不是单一文件，而是由导航配置驱动
- 运行时不仅负责渲染页面，还负责权限、布局、Sentry、全局弹窗和外挂能力

## 4. 环境与外部服务配置

`public/hosts_dev.json` 说明前端运行时通过 `window._config` 绑定环境地址。已确认的关键域包括：

- `mof_api`
- `rof_api`
- `parser_api`
- `indicator_api`
- `research_api`
- `monitor_api`
- `info_api`
- `rrp_api`
- `rrp_app_api`
- `cards_pdf_api`
- `pdf_api`
- `usermaster_api`
- `pms_api`
- `navi_api`

此外还存在模块联邦相关 remote：

- `mof_private_assets_remote`
- `mof_card_pages_remote`
- `mof_main_remote`
- `mof_etf_remote`

这说明该前端不仅仅是“请求多个 HTTP API”，还承担了模块联邦宿主的角色。

## 5. 工程结构的代际特征

仓库有非常明显的“多代前端并存”特征：

### 5.1 第一代主路径

- `js/pages/*`
- `js/components/*`
- `js/modules/*`
- `js/app/*`

这一层仍是门户主干，承担大多数传统页面和通用组件。

### 5.2 第二代能力层

- `js/v2/pages/*`
- `js/v2/cards/*`
- `js/v2/routes.ts`

这一层更多承载报告、组合分析、独立报告、Dashboard、组合风险与新组合页。

### 5.3 平台型抽象层

- `framework/src/*`

这是独立于具体页面的卡片框架层，负责卡片懒加载、卡片布局、配置持久化等。

换句话说，这个仓库并不是“旧代码等于垃圾代码，新代码都在 v2”。更准确的理解是：

- `js/app` 是运行时壳
- `js/pages` 是传统业务页面树
- `js/v2` 是新一代报告/组合能力
- `framework` 是跨代共用的卡片平台层

## 6. 目录别名与代码组织信号

`tsconfig.json` 暴露了重要 alias：

- `dyc/* -> framework/src/*`
- `mof/* -> js/v2/*`
- `rrp/* -> js/v2/*`
- `js/* -> js/*`
- `pages/* -> js/pages/*`

这些 alias 反映出实际架构意图：

- `dyc` 是面向平台能力的抽象别名
- `mof` 与 `rrp` 在前端代码里已经部分指向同一套 `js/v2` 实现
- 历史目录和新目录通过 alias 被揉成了统一导入面

未来如果迁移到其他语言或其他前端架构，这些 alias 对应的“逻辑层级”比目录名本身更值得保留。

## 7. 运行时外围能力

除页面本身外，前端壳层还统一挂了多个全局能力：

- 登录状态处理
- 权限弹窗
- 风险提示
- 通知中心
- 帮助入口
- 免责声明弹窗
- route pingback / 埋点
- Sentry 监控

这些能力集中在 `js/app/components/external` 和 `js/app/components/root` 体系中。

这意味着未来重构不能只“把页面重写出来”，还需要补回一套全局运行时能力，否则会在权限体验、风险提示和可观测性上退化。

## 8. 对重构最重要的结论

### 8.1 这不是单纯 UI 重写问题

`mof-web-fe` 更像一个前端操作系统外壳，而不是一组静态页面。

### 8.2 最值得抽象的不是组件，而是运行模式

真正稳定的东西包括：

- 路由装配模式
- 权限拦截模式
- 多后端 API 适配模式
- 卡片异步计算与轮询模式
- 页面/卡片配置持久化模式

### 8.3 未来可以拆成四层

建议未来重构时按以下边界拆分：

1. `Portal Shell`
2. `Domain Applications`
3. `Report/Card Runtime`
4. `Gateway/API Client Layer`

## 9. 当前确认结论与待确认项

### 9.1 已确认

- 启动入口、路由生成、权限拦截链路明确。
- 多构建器并存、React 17 与 Router v5 仍是当前主栈。
- 多后端域配置由 `window._config` 注入。
- `framework` 是跨页面的卡片平台层。

### 9.2 待确认

- 模块联邦 remote 在不同环境下的真实装载边界。
- `js/v2` 与 `js/pages` 的实际替代关系是否已有清晰迁移计划。
- 某些特殊租户定制逻辑是否还散落在页面层，而不只在统一权限层。
