---
tags:
  - mof-web-fe
  - frontend
  - report
  - card-framework
status: active
updated: 2026-03-27
---

# Mof-Web-Fe 卡片报告框架与前后端契约专题

## 1. 为什么这个专题重要

对 `mof-web-fe` 来说，最有复用价值的能力不是单个页面，而是“卡片报告框架”。

这个框架把以下事情连成了一体：

- 卡片定义
- 卡片动态加载
- 页面模板编排
- 异步创建报告
- 单卡异步计算
- 轮询拿结果
- 缓存复用
- 单卡重算
- 图片/PDF 预览

未来如果整个系统重构，这套能力很可能需要被单独抽象成新的前端平台层，甚至对应一个新的后端报告编排接口层。

## 2. 核心组成

### 2.1 卡片平台基础层

位于：

- `framework/src/components/Card`
- `framework/src/components/CardGrid`
- `framework/src/utils/api/card.ts`

其职责包括：

- 卡片懒加载
- 卡片网格布局
- 用户/租户/全局配置持久化
- dashboard/page 配置读写

### 2.2 报告运行层

位于：

- `js/components/cards-flow/*`
- `js/v2/pages/Report/*`
- `js/v2/pages/IndependentReport/*`

其职责包括：

- 根据模板和卡片列表创建报告
- 处理缓存卡片
- 轮询获取已完成卡片
- 渐进式把卡片结果下发给 UI
- 支持取消报告
- 支持单卡重算

### 2.3 Storybook 调试层

位于：

- `storybook/card/platform/*`

其职责包括：

- 独立调试卡片
- 在非完整业务页面中模拟报告上下文
- 提供图片/PDF 预览能力

这说明团队已经把“卡片作为独立运行单元”来对待，而不只是页面内部组件。

## 3. 卡片加载模型

`framework/src/components/Card/index.tsx` 展示了当前卡片加载模式：

- 卡片以 `type` 为标识
- 通过 `doImportDelegate` 动态导入真实卡片组件
- 通过 `IntersectionObserver` 懒加载
- 注入配置与 customization
- 用 `enhance` 包装成统一卡片组件

这说明在当前系统中，卡片是“按类型动态分发”的，而不是静态 import 到页面中。

对重构的启示是：

- 卡片必须保持稳定的 `cardKey/type` 身份
- 卡片运行时必须支持动态装配
- 卡片与页面不应该强耦合

## 4. 卡片布局模型

`framework/src/components/CardGrid/index.tsx` 使用 `react-grid-layout`：

- 卡片通过布局配置驱动
- 支持响应式布局
- 支持拖拽与 resize
- 支持根据卡片渲染高度回写布局高度

这意味着卡片页面不是普通文档流页面，而是“可编排 dashboard 页面”。

未来如果重写，必须确认是否保留：

- 自定义面板布局
- 卡片级拖拽
- 响应式布局映射

## 5. 报告创建与单卡计算契约

`js/components/cards-flow/apis.ts` 已经暴露出当前报告平台对后端的主要契约。

### 5.1 创建整份报告

通过 `createReport(...)`，根据报告类型走不同接口：

- meta 报告
- default 报告
- custom 报告

输入要素包括：

- `accountId`
- `cardKeys`
- `reportType`
- `options`
- `sectionId`
- `regen`
- `accountDataFrom`
- `templateType`
- `category`

### 5.2 获取缓存卡片

通过 `postCachedCardAPI(cacheId, cardKeys)` 获取已缓存卡片。

### 5.3 单卡重算

通过 `sendComputeSingleAPI(key, params)` 触发单卡异步计算。

### 5.4 轮询报告

通过 `pollingReport(taskId, holdSec)` 轮询获取已完成卡片。

### 5.5 清除缓存

通过 `clearReportCach(accountId)` 触发整份报告相关缓存清理。

## 6. 卡片请求流程的稳定语义

`js/components/cards-flow/services.ts` 中 `RequestReportCards` 表明当前卡片流的稳定过程是：

1. 计算出本次需要请求的卡片集合
2. 先尝试命中缓存卡片
3. 对未命中的卡片创建报告任务
4. 获取 `reportMeta + taskDesc`
5. 轮询后端直到卡片逐步准备完成
6. 每拿到一批卡片结果就回调 UI
7. 全部结束后对缺失卡片补空结果/错误结果

这套流程的关键点是“渐进式交付”，不是等全部完成后一次返回。

未来重构时，如果把它改成“单次同步拿整份报告”，会丢失当前用户体验和系统扩展性。

## 7. 单卡远程计算模型

`js/utils/ajaxUrls.ts` 和 `js/v2/pages/Report/useRemoteData.ts` 说明单卡也可以脱离整份报告单独计算。

代表接口模式：

```text
/api/card/defaultReport/computeSingle/custom/async/{cardKey}
```

典型输入包括：

- `accountId`
- `startDate`
- `endDate`
- `benchmark`
- `customParamMap`
- `accountDataFrom`

这正是你前面追踪过的 `stockBrinsonAttr` 这类接口所在的前端入口模型。

因此可以说：

- 整份报告 = 多张卡片编排
- 单卡接口 = 报告平台的最小计算单元

## 8. 偏好配置与持久化

`framework/src/utils/api/card.ts` 已确认卡片/页面配置会存到 `usermaster_api` 下的 preference 接口。

已支持的层级包括：

- `global`
- `tenant`
- `user`

读配置时会做多级 merge，写配置时可以按层级保存。

这意味着卡片平台不仅是“展示平台”，还是“可配置平台”。

未来如果重构成其他语言或其他前端平台，必须保留：

- 卡片标识稳定性
- 页面/卡片布局配置持久化
- 用户级、租户级、全局级配置叠加

## 9. Storybook 的真实意义

`storybook/card/platform` 不是简单组件文档，而是一个“卡片运行沙箱”。

它会模拟：

- 报告账户上下文
- 页面类型
- 描述映射
- 图片导出预览
- PDF 打印预览

这说明项目团队已经把“卡片可单独运行、可单独调试、可单独导出”当作工程要求。

## 10. 对未来重构必须保留的前后端契约

### 10.1 稳定的 card key

卡片是按 key/type 识别、加载、缓存和重算的。

### 10.2 异步任务语义

卡片和报告计算不是简单同步接口，必须支持：

- create task
- polling
- cancel
- partial ready

### 10.3 缓存语义

当前系统明确支持：

- 命中缓存卡片
- 按账号清缓存
- 单卡重算

### 10.4 模板语义

报告并不是纯卡片列表，还包含：

- `templateType`
- `category`
- `sectionId`
- slot/template cards

### 10.5 多输出语义

同一套卡片数据最终可能用于：

- 页面展示
- 图片导出
- PDF 打印

## 11. 当前确认与待补充

### 11.1 已确认

- `framework` 提供卡片基础设施。
- `cards-flow` 提供报告请求与轮询流程。
- 单卡与整份报告都支持异步计算。
- 配置可持久化到 usermaster preference。
- Storybook 可作为卡片运行沙箱。

### 11.2 待补充

- `js/v2/cards` 的全量卡片分类。
- 卡片 key 到具体后端接口的映射表。
- 导出链路与页面展示链路是否完全共享同一数据结构。
