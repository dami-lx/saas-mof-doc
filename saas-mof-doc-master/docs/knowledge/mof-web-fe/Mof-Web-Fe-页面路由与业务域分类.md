---
tags:
  - mof-web-fe
  - frontend
  - routing
  - domain
status: active
updated: 2026-03-27
---

# Mof-Web-Fe 页面路由与业务域分类

## 1. 路由生成主链

当前前端路由不是手写在单个 router 文件里，而是通过“导航树 + 运行时转换”生成。

主链如下：

```text
js/bootstrap.tsx
  -> 引入 js/pages/nav.ts
  -> Root 接收 navs
  -> js/app/routes.tsx 调用 getRoutes(navs)
  -> 生成 Route / Redirect / Level3Nav
```

这里有三个关键事实：

1. `js/pages/nav.ts` 是业务分类总入口。
2. `js/app/routes.tsx` 是统一运行时编排器。
3. 每个页面并不是直接 mounted，而是先经过权限包装和 `Bundle` 包装。

## 2. 路由运行时做了什么

`js/app/routes.tsx` 不只是简单映射 URL，它还承担以下职责：

- 权限校验
- 查询参数解析
- `params / routeParams / location.query` 统一注入
- 页面级 `pageId` 透传
- 默认子路由重定向
- 三级导航条渲染

其中最重要的两个包装器是：

- `withPermission`
  - 无权限时统一弹窗并跳回首页
- `withHistoryBundle`
  - 把 query、match.params 和页面元信息整理后交给 `Bundle`

这意味着未来重构时，路由层不仅要保留 URL，还要保留“页面上下文装配语义”。

## 3. 权限与租户的影响

权限有两层：

- 路由显式 permission code
- `js/app/auth/index.ts` 中按租户推导出的 tenantPermissions

已确认的租户化开关包括：

- 是否展示尽调入口
- 是否展示定制归因行业
- 是否展示净值归因自定义按钮
- 是否隐藏某些业绩卡片
- 是否给模拟组合开放部分风控/归因能力

因此，路由并不是“纯路径树”，而是“路径 + 权限 + 租户定制化”的组合。

## 4. 一级业务域分类

`js/pages/nav.ts` 已经可以作为前端业务域地图。按当前导航树，可以把仓库的页面域整理为以下几类。

### 4.1 基金筛选与基础研究域

主要入口：

- `/app/fund`

对应子域：

- `product`
- `company`
- `manage`
- `fund-market`
- `new-fund`

这一组页面更接近“基金/管理人/公司/市场研究工作台”。

### 4.2 资产配置与策略域

主要入口：

- `/app/mom`

对应子域：

- `fund/strategy`
- `asset_new`
- `mom`
- `scenario_new`
- `aiFof`
- `industry`

这是当前前端里最贴近 `mom` 核心业务定位的一组页面。

### 4.3 投后与组合管理域

主要入口：

- `investedManage`
- `production`
- `production-old`
- `portfolio-report`
- `trial-balance`

这组页面和 `PMS_ELITE`、组合分析、持仓导入、组合监控关系最密切。

### 4.4 报告与卡片域

主要入口：

- `custom-report`
- `fund-rank`
- `portfolio-report`
- `js/v2/routes.ts` 中的 `report / simple-report / running / scenario/report / virtualFof/report`

这是 `mof-web-fe` 里最平台化的一层，路由背后往往不是传统页面，而是模板化报告容器。

### 4.5 风控与分析工具域

主要入口：

- `risk-control`
- `analyze-tool`

这类页面更像面向投研和投后团队的专题工具集。

### 4.6 协作与研究辅助域

主要入口：

- `my-research`
- `settings`
- `ams-local`

这部分承担个性化配置、本地化辅助和研究协同能力。

### 4.7 特殊专题域

主要入口：

- `due-diligence`
- `private-assets`
- `strategy`
- `etf`

这些不是基础门户首页的一部分，但已经被合并进统一前端壳中。

## 5. `js/pages` 与 `js/v2` 的职责分工

### 5.1 `js/pages`

更多承担：

- 历史业务页面
- 左侧导航主入口
- 传统表单、搜索、列表、筛选页

### 5.2 `js/v2`

更多承担：

- 独立报告
- 组合分析
- Dashboard2
- Portfolio 新页面
- 简版报告和公共报告

`js/v2/routes.ts` 暴露出的代表性页面包括：

- `/running/:pageKey/:dashboardKey?`
- `/report/:id`
- `/simple-report/:id`
- `/portfolio/analysis/:id?/:type?`
- `/portfolio/overview`
- `/portfolio/optimization/:id?`
- `/portfolio/risk/:id?/:type?`
- `/scenario/report/:id?`
- `/virtualFof/report/:id`

由此可见，`js/v2` 不是简单的目录重构，而是新一代“报告与组合操作台”。

## 6. 路由层面的重要契约

对未来重构最重要的，不是路径字符串本身，而是以下契约：

### 6.1 URL 必须能稳定映射到业务上下文

例如：

- 报告类路由通常携带 `report id`
- 组合分析类路由通常携带 `account id / type`
- Dashboard 类路由携带 `pageKey / dashboardKey`

### 6.2 路由必须能承载权限失败体验

当前系统不是静默隐藏，而是：

- 页面访问时动态校验
- 无权限时弹窗提示
- 回跳首页

### 6.3 路由必须能承载布局信息

`getRoutes` 会收集 `pageLayout`，说明布局不是单纯写死在页面内部，而和路由元数据相关。

### 6.4 路由必须能挂接报告/卡片运行时

很多 `report` 路由最终进入的是统一报告容器，而不是普通静态页。

## 7. 对未来拆分的建议

如果未来要把前端按业务域拆分，推荐优先按以下分组观察：

1. `基金研究门户`
2. `资产配置与策略`
3. `投后与 PMS 组合管理`
4. `报告与卡片平台`
5. `私有资产 / 尽调 / ETF 等专题应用`

这里尤其要注意：

- `报告与卡片平台` 不应被简单归入某一个业务域
- 它更像各业务共享的前端运行平台

## 8. 当前确认与待补充

### 8.1 已确认

- `js/pages/nav.ts` 是业务分类总入口。
- `js/v2/routes.ts` 已承担新报告和组合页的核心路由。
- 权限、页面上下文、Bundle 封装都在统一路由层完成。

### 8.2 待补充

- 每个一级业务域下具体 router 文件的 URL 清单。
- 路由到页面组件再到 API 域的逐条映射。
- 各租户配置对左侧导航和页面展示的实际影响范围。
