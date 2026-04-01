---
tags:
  - pms
  - position
  - mom
  - fof
  - refactor
status: draft
updated: 2026-03-27
---

# PMS_ELITE Position 模块专题

## 1. 模块定位

`position` 模块是 `PMS_ELITE` 的业务核心。

它名义上是“持仓查询模块”，但从实现看，它实际上承担了：

- 组合持仓查询
- 穿透持仓
- MOM 视角处理
- FOF 透视
- 虚母虚子处理
- 实时估值
- 持仓日历查询
- MOM 日历查询
- 持仓趋势查询

这也是整套系统里最适合优先抽离成独立领域服务的模块。

## 2. 接口清单

路由定义：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/api/position/urls.py`

视图：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/api/position/views.py`

服务：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/position_service.py`

接口包括：

- `GET /position/position_composition`
- `GET /position/position_calendar`
- `GET /position/mom_calendar`
- `GET /position/position_trend`

## 3. `position_composition` 是什么

### 3.1 外部看起来是什么

它是一个持仓查询接口。

### 3.2 实际上是什么

它是一个“带透视、口径、层级、实时估值能力的持仓构造引擎”。

核心链路：

- `PositionService.position_composition`
- `PortfolioPositionComposition.position_composition`

关键实现文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/position/position_composition.py`

## 4. `position_composition` 的输入语义

关键参数包括：

- `portfolio_id`
- `start_date`
- `end_date`
- `mom_perspective`
- `perspective_display`
- `is_original`
- `real_all_data`
- `real_time_quote`
- `with_otc_fund_predict`
- `merge_hke`
- `fof_perspective_method`
- `fof_perspective_display`
- `with_fof_report_date`

这些参数说明：

- 该接口不是一个“原始持仓查询”接口
- 而是一个“按业务视角解释持仓”的接口

## 5. 主实现链路

### 5.1 第一步：读取基础数据

`_prepare_data()` 首先从 Mongo 读取：

- `POSITION`
- `CASH`

这是它的基础数据层。

### 5.2 第二步：进入 `MomData`

如果组合中包含组合类证券，或者组合类型是：

- `GROUP`
- `SUB_ACCOUNT`

则会走：

- `MomData.generate(...)`

实现文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/business/mom/mom_data.py`

其输出的核心对象是：

- `hold_param`
- `node_value`

其中：

- `hold_param` 表示组合之间的持有关系
- `node_value` 表示节点级别的净值、份额、资产等特征值

### 5.3 第三步：对子层净值做补丁式修正

在 `position_composition.py` 中，如果检测到 `need_to_correct_nav` 的子层组合，会额外：

- 调 `get_portfolio_summary_values(...)`
- 回填 `NAV`
- 回填 `SHARE`

源码里已明确说明这是一种临时方案。

这说明当前系统在这块存在较强的历史耦合。

### 5.4 第四步：调用 `MOM.get_hold_position(...)`

这一步会真正把：

- 持有关系
- 节点值

转成前端消费的持仓结构。

### 5.5 第五步：格式翻译与分页

后续还会经过：

- `PositionCompositionTranslator`
- `merge_hke_position`
- `page_position`

说明这个模块同时承担了：

- 领域结果构造
- 输出模型翻译
- API 展示分页

## 6. `MomData` 的角色

`MomData` 是 `position` 模块最重要的内部核心之一。

关键职责：

- 生成持有关系
- 生成节点值
- 搜索虚母子层
- 处理多层组合
- 处理数据不对齐日期
- 结合 `DataPortal` 做数据补充

因此，它更像一个“组合透视数据构造器”。

## 7. FOF 透视链路

`FoFPerspective` 位于：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/position/fof.py`

执行时机：

- 在持仓结果已经初步形成后
- 根据 `fof_perspective_method` 和 `fof_perspective_display` 再做一次透视处理

它的能力包括：

- 加载基金报告数据
- 加载私有资产报告数据
- 选择透视报告期
- 处理 summary / hierarchy 两种展示方式
- 在 FOF 视角和 MOM 视角间做组合

因此：

- `with_fof_report_date` 是真实口径参数
- `fof_perspective_method` 不是展示参数，而是业务计算参数

## 8. 实时估值链路

若当前组合不经过 `MomData` 处理，且：

- `real_time_quote = true`

则会调用：

- `evaluate_latest_position_and_cash(...)`

并通过：

- `DataPortal`
- `MarketService`
- `market_interface`

加载：

- 最新行情
- 场外基金预测估值
- 债券估值与应计利息
- 私有资产多源价格

结论：

- 这个接口返回值可能是实时修正后的，不一定是纯落库快照。

## 9. `position_calendar` 与 `mom_calendar`

### 9.1 `position_calendar`

服务：

- `PositionService.position_calendar`

功能：

- 查询组合持仓数据日期分布

### 9.2 `mom_calendar`

服务：

- `PositionService.mom_calendar`

功能：

- 查询 MOM 事件相关日期

这两个接口虽然简单，但对前端选择时间区间和展示可用日期很重要。

## 10. `position_trend`

服务：

- `PositionService.position_trend`

核心类：

- `PositionTrend`

主要能力：

- 按采样频率提取日期
- 统计持仓趋势
- 补充价格和金额
- 对 MOM 场景补价格

这说明：

- 趋势接口不是持仓快照的简单拼接，而是经过二次处理的分析接口。

## 11. 模块的隐藏耦合

当前 `position` 模块耦合了过多职责：

- 持仓数据读取
- 组合穿透
- FOF 透视
- 实时估值
- 输出翻译
- 分页

这会导致：

- 重构难度高
- 单测边界不清晰
- 任何一个口径变更都可能影响整条链路

## 12. 重构建议

建议未来将 `position` 模块拆成至少 4 层：

### 12.1 Position Snapshot Loader

- 从 Mongo 拉原始持仓和现金

### 12.2 Portfolio Penetration Engine

- `MomData`
- `MOM`
- `FoFPerspective`

### 12.3 Valuation Enricher

- 实时估值
- 行情补充
- 多数据源价格决策

### 12.4 API Presenter

- translator
- merge_hke
- page

## 13. 一句话结论

`position` 模块并不是“查询模块”，而是 `PMS_ELITE` 的组合持仓领域引擎。
