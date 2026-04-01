---
tags:
  - mom-robo
  - module
  - spring-boot
  - refactor
status: active
updated: 2026-03-27
---

# Mom-Robo 模块总览与聚合入口

## 1. 先给一个总览结论

`mom-robo` 不是“前端接口都写在 `mom-web` 里的单体”。

更准确地说，它是一个由 `mom-application` 启动、通过 `scanBasePackages` 聚合多个业务模块 controller 的 Spring Boot 应用。

这意味着未来如果要拆分服务，第一步不能只按包名拆 controller，而要先识别：

1. 哪些模块只是被聚合进来。
2. 哪些模块本身已经具备独立业务域。
3. 哪些接口是面向前端，哪些接口其实是内部平台或外部库能力。

## 2. 聚合启动入口

启动类位置：

- `/Users/jiangtao.sheng/Documents/source/mom-robo/mom-application/src/main/java/com/datayes/web/MomApplication.java`

从源码可确认：

- 使用 `@SpringBootApplication(scanBasePackages = ...)`
- 扫描的包不仅包含 `com.datayes.web`
- 还包含：
  - `com.datayes.mom.portfolio`
  - `com.datayes.mom.h5`
  - `com.datayes.gzb`
  - `com.datayes.transaction`
  - `com.datayes.store`
  - `com.datayes.web.ams`
  - `com.datayes.mom.privateasset`
  - `com.datayes.mom.lib`
  - `com.datayes.datayesir`
  - 等其他包

这说明：

- controller 注册不是单模块本地行为
- `mom-robo` 的对外 API 面是聚合后的总和

## 3. Maven 模块结构

根 `pom.xml` 中可以确认的核心模块包括：

- `mom-web`
- `mom-legacy`
- `mom-portfolio-service`
- `mom-private-asset-service`
- `mom-user`
- `mom-lib`
- `mom-h5`
- `mom-workflow`
- `mom-fundpool`
- `mom-saas`
- `mom-datayesir`
- `mom-ai-api`
- `due-diligence`
- 以及若干基础模块，如 `mom-common`、`mom-storage`、`mom-security`

这说明 `mom-robo` 更像“业务门户 + 多域后端聚合层”，而不是纯粹的 BFF。

## 4. controller 数量分布

我对主要模块中的 `*Controller.java` 做了一次静态统计，结果如下：

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

从这个分布可以看出：

- `mom-web` 是绝对主入口
- 但 `mom-portfolio-service`、`mom-private-asset-service`、`mom-user` 等已经具备独立服务边界雏形
- `mom-legacy` 仍然保留了相当一批历史接口

## 5. 模块职责的第一层划分

## 5.1 `mom-web`

定位：

- 主业务 API 聚合层
- 前端最直接的接口来源

可见子域很多，包括：

- 账户搜索与筛选
- 报告卡片
- 资产配置
- 基准与行业模型
- 风控
- 标签、分组、用户配置
- 缓存、迁移、任务、导出上传

## 5.2 `mom-legacy`

定位：

- 历史保留接口集合

代表领域：

- 老版归因
- 老版产品/账户相关接口
- 风控旧接口
- 导出上传
- 首页、市场事件、风险任务等历史能力

重构时要注意：

- 这些接口很可能仍被线上历史前端或定时任务依赖

## 5.3 `mom-portfolio-service`

定位：

- 投后 / PMS_ELITE 相关接口层

代表领域：

- 投后产品管理
- 投后筛选
- 交易导入
- 指标查询
- 分红
- 租户配置
- 迁移与试算

这是当前系统里边界相对清晰、最适合独立拆分的业务域之一。

## 5.4 `mom-private-asset-service`

定位：

- 私有资产专属接口层

代表领域：

- 私有资产列表与导出
- 私有资产外部对接接口
- 分红
- 日志中心
- 测试与导入辅助

## 5.5 `mom-user`

定位：

- 权限、角色、租户、数据授权

代表领域：

- 数据权限
- 角色权限
- 用户权限
- 全局租户管理

这部分本质上是通用平台能力，而不是单纯业务页面接口。

## 5.6 `mom-lib`

定位：

- 面向外部库/外部系统的轻量 API

代表领域：

- `/lib/portfolio`
- `/lib/simulate/portfolio`
- `/lib/asset`
- `/lib/common`
- `/lib/monitor`

这组接口更像“标准化查询出口”。

## 5.7 `mom-h5`

定位：

- H5 / App 轻端接口

代表领域：

- H5 产品页
- H5 卡片报告
- ETF 能力
- H5 用户接口

## 5.8 `mom-workflow`

定位：

- 工作流协作与审批集成

代表领域：

- 工作流开关
- 回调
- 文件上传下载

## 5.9 其他模块

- `mom-fundpool`: 基金池相关能力
- `mom-saas`: SaaS / VIP 报告 / 行业定制 / FeatureSearch 等
- `mom-datayesir`: 数据接口适配
- `mom-ai-api`: AI SQL 等轻量 AI 能力
- `due-diligence`: 尽调相关接口

## 6. 从重构视角看这套结构意味着什么

## 6.1 `mom-robo` 更像 API 聚合层

它并不是所有业务逻辑都在自己内部完成，而是汇聚：

- 搜索
- 评价报告
- 资产配置
- 投后
- 私有资产
- 权限
- 工作流

这些不同领域的 controller。

## 6.2 “模块”不等于“服务”

虽然 Maven 层已经拆了很多模块，但它们当前仍由同一个 Spring Boot 聚合进程统一暴露。

所以未来拆分时不能简单照着 Maven module 直接切服务，而要结合：

- 业务域耦合
- 前端调用关系
- 权限体系
- 下游依赖

## 6.3 `mom-web` 是业务门户层，不是唯一真边界

很多人第一次看 `mom-robo` 容易把 `mom-web` 当成全部接口层，但源码显示不是这样。

真正更稳的判断方式是：

- 先看聚合入口
- 再看 controller 来源模块
- 最后按业务属性重新归类

## 7. 一句话结论

`mom-robo` 是一个“Spring Boot 聚合业务门户”，其中 `mom-web` 是最大 API 面，但投后、私有资产、权限、工作流、外部库接口等已经形成独立业务子域，未来重构应优先按这些业务边界而不是按历史包路径拆分。
