---
tags:
  - mof-web-fe
  - frontend
  - state-management
  - api
status: active
updated: 2026-03-27
---

# Mof-Web-Fe 状态管理与数据请求专题

## 1. 总体结论

`mof-web-fe` 的前端状态层和请求层都处于“多代模式并存”状态：

- 全局状态仍以 `Redux + Saga` 为主
- 新页面开始引入 `zustand`
- 绝大多数数据访问已经通过 `js/api/*` 按后端域封装
- 异步任务、报告生成、卡片计算普遍依赖轮询

未来重构时，应该保留“分层语义”，而不是机械复刻当前库选型。

## 2. 状态管理分层

### 2.1 全局状态层

`js/app/redux/store.ts` 说明当前全局 store 仍是系统基础设施：

- 使用 `redux`
- 注入 `redux-saga`
- 支持 Sentry Redux enhancer
- 支持 reducer 动态注入
- 支持 saga 动态注入

这说明 Redux 在本仓库中的主要价值不是“所有页面状态全都放进去”，而是承担：

- 应用级全局状态
- 动态模块装载
- 传统页面的副作用编排

### 2.2 页面局部状态层

已确认以下新页面使用 `zustand`：

- `js/pages/fund-rank/store.ts`
- `js/pages/portfolio-report/store.ts`
- `js/pages/trial-balance/store.ts`
- 部分局部弹窗和专题模块

这些 store 的共同特征是：

- 更贴近单页面或单专题
- 以数据加载、筛选参数、轮询结果为中心
- 不强依赖全局 reducer 注入机制

因此可以把它视为“第二代页面状态方案”。

### 2.3 hooks 与局部共享状态

`js/hooks/*` 提供了更轻量的局部能力，例如：

- `usePreference`
- `useLocalStorage`
- `useTradingDayInfo`
- `use-query`
- `use-shared-state`
- `portfolioHooks/*`

这部分更多承担“可复用页面逻辑”，而不是大状态容器。

## 3. 请求层总体结构

当前请求层可以拆成三层。

### 3.1 第一层：通用请求底座

核心文件：

- `js/app/ajax/index.ts`

主要职责：

- axios 实例创建
- 登录/权限/密码过期拦截
- `get/post/put/del/json/mof_fetch`
- 通用轮询函数 `task`
- `withGateway`
- `methodFactory`

这层是整个前端所有 API 包的底座。

### 3.2 第二层：统一结果解析封装

核心文件：

- `js/api/call-api.ts`

主要职责：

- 统一处理 `DataResponse<T>` 与 `ListResponse<T>`
- 把 `S00000` 作为成功状态
- 对业务错误做统一弹窗

这层比底层 ajax 更偏“业务友好 API”。

### 3.3 第三层：按后端域拆分的 typed API 包

核心目录：

- `js/api/mof`
- `js/api/rof`
- `js/api/parser`
- `js/api/indicator`
- `js/api/intelligence`
- `js/api/adventure`
- `js/api/aladdin-info`
- `js/api/aladdin-monitor`
- `js/api/research`
- `js/api/schedule`
- `js/api/market-adv`

其中已确认文件规模：

- `mof`: 289 个一级文件，明显是最大后端域
- `parser`: 87 个一级文件
- `rof`: 53 个一级文件

这三类是当前前端最核心的服务消费面。

## 4. 外部服务域映射

根据 `public/hosts*.json` 和各个 `ajax/index.ts`，已确认如下映射：

- `js/api/mof` -> `mof_api`
- `js/api/rof` -> `rof_api`
- `js/api/parser` -> `parser_api`
- `js/api/indicator` -> `indicator_api`
- `js/api/research` -> `research_api`
- `js/api/aladdin-info` -> `info_api`
- `js/api/aladdin-monitor` -> `monitor_api`
- `js/api/adventure` -> `rrp_api`
- `js/api/intelligence` -> `rrp_app_api`
- `js/api/market-adv` -> `rrp_market_adv`

因此前端并没有把所有业务都压到一个 `BFF` 上，而是直接对接多个后端服务域。

对未来重构，这带来两个重要结论：

1. 前端已经部分承担“客户端聚合层”职责。
2. 如果未来引入新的 BFF，需要先识别哪些跨域聚合逻辑已经在前端发生。

## 5. 请求结果格式并不统一

`js/app/ajax/index.ts` 已明确写出：

- 有的接口返回 `msg`
- 有的接口返回 `message + success`
- 有的老接口直接返回结果，没有统一应用层包装

因此当前请求层真正的价值不在“发 HTTP 请求”，而在“吸收后端格式不一致性”。

未来重构时，务必要保留一个“结果适配层”，否则会把后端历史不一致直接扩散到新前端里。

## 6. 轮询是核心能力，不是边角料

### 6.1 底层轮询

`js/app/ajax/index.ts` 的 `task(...)` 提供通用轮询：

- 默认可根据 `taskId` 轮询 `/api/polling/{taskId}`
- 支持自定义完成条件
- 支持前端延时
- 支持进度条计数

### 6.2 API 包自动轮询

`js/api/mof/ajax/index.ts` 和 `js/api/rof/ajax/index.ts` 都引入了 `withAutoPolling`。

这意味着部分接口只要返回轮询任务态，API 客户端就会自动帮助前端取到最终结果。

### 6.3 特定业务轮询

已确认的特例包括：

- `js/api/mof/ajax-with-polling-pms.ts`
  - 轮询 PMS 投后相关任务状态
- `js/utils/polling-request/index.ts`
  - 提供批量收集、去重、取消、回调分发的轮询请求管理器
- `js/pages/portfolio-report/store.ts`
  - 通过 `PollingServiceImpl` 管理组合报告卡片刷新

结论是：轮询在当前系统中是“标准交互形态”，尤其用于：

- 报告生成
- 卡片计算
- 批量导入
- 组合分析

## 7. 典型数据加载模式

当前前端常见有三种数据加载模式。

### 7.1 页面初始化拉取

特点：

- 页面打开即请求
- 通常走 Redux、hooks 或 zustand 直接触发

### 7.2 参数驱动刷新

代表：

- `fund-rank/store.ts`
- `portfolio-report/store.ts`

特点：

- 筛选参数变化后重新请求
- 页面本地 store 保存快照

### 7.3 任务式异步生成

代表：

- 报告卡片
- 组合报告
- 批量导入/解析

特点：

- 先发 create 接口
- 获得 taskId 或 polling ids
- 周期性轮询
- 卡片可渐进返回

## 8. 对未来重构必须保留的契约

### 8.1 API 域边界必须显式化

不要把所有接口重新混成一个“超大 client”。现有 `js/api/*` 的分域方式虽然不完美，但已经表达了后端域边界。

### 8.2 结果解析与错误处理必须统一

不管将来用什么语言和框架，都必须保留：

- 权限失效统一处理
- 登录失效统一跳转
- 密码过期统一跳转
- 业务错误统一呈现

### 8.3 轮询必须成为一等公民

报告、卡片、解析、组合计算都是轮询驱动。若新实现只支持“同步请求”，会直接破坏用户体验和系统语义。

### 8.4 状态容器应按使用场景拆分

建议未来采用：

- 全局应用状态
- 页面专题状态
- 局部 hooks 逻辑

而不是再回到“全部放全局 store”。

## 9. 当前确认与待补充

### 9.1 已确认

- Redux/Saga 仍是应用壳主状态容器。
- 新页面已使用 Zustand。
- 请求层已经有清晰的三层结构。
- 前端直接消费多个后端域。
- 轮询是标准能力层。

### 9.2 待补充

- `js/api/mof` 每个接口到页面调用点的映射。
- `withAutoPolling` 的完整行为边界。
- `parser / rof / mof` 各域接口在前端视角下的业务归类。
