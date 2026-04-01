---
tags:
  - pms
  - penetration
  - position
  - indicator
  - refactor
status: draft
updated: 2026-03-27
---

# PMS_ELITE 穿透持仓与指标口径专题

## 1. 这篇文档回答什么问题

这篇文档专门解释 `PMS_ELITE` 在整条链路中的角色，以及为什么它不是“一个简单持仓查询接口”。

本文重点解释：

1. `mom` 实际向 `pms` 请求了什么。
2. `pms` 的持仓查询内部做了哪些业务计算。
3. `pms` 的指标查询内部做了哪些补算。
4. 哪些参数是真正影响口径的。
5. 重构时哪些语义不能丢。

## 2. 在总链路中的位置

相关总览：

- [stockBrinsonAttr 全链路拆解](./stockBrinsonAttr-全链路拆解.md)

在 `stockBrinsonAttr` 这条链里，`mom` 依赖 `PMS_ELITE` 至少完成两件事：

1. 提供组合持仓及穿透后的层级持仓。
2. 提供净资产/净值/份额等指标，用于把持仓转成权重。

## 3. mom 侧如何调用 PMS

在 `mom` 中，最关键的 PMS 侧调用发生在：

- `/Users/jiangtao.sheng/Documents/demo/codex-mof/mom/mom-web/src/main/java/com/datayes/web/mom/service/card/loader/position/pmselite/PmsEliteAccountPositionLoader.java`

主要有两类调用：

### 3.1 持仓查询

- `pmsPositionLoader.positionComposition(...)`

### 3.2 指标查询

- `indicatorLoaderProxy.loadIndicators(...)`

其中：

- 持仓查询提供层级持仓结构
- 指标查询提供 `netAsset`

`mom` 需要把两者结合，才能得到最终用于归因的 `DailyPosition.weight`。

## 4. PMS 持仓接口的真实入口

API 入口：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/api/position/views.py`

服务层：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/position_service.py`

核心控制器：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/position/position_composition.py`

请求参数定义：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/api/standard_input/position_args.py`

## 5. 持仓查询支持哪些关键口径参数

从 `position_args.py` 和 `position_service.py` 可以看出，这条接口会受到以下参数影响：

- `mom_perspective`
- `perspective_display`
- `is_original`
- `security_types`
- `realtime_computation`
- `real_all_data`
- `real_time_quote`
- `with_otc_fund_predict`
- `merge_hke`
- `fof_perspective_method`
- `fof_perspective_display`
- `with_fof_report_date`

这说明：

- `PMS_ELITE` 不是“输入时间区间，返回固定持仓”的接口。
- 它返回的是“在特定业务视角下解释过的持仓”。

## 6. 持仓查询内部到底做了什么

### 6.1 第一阶段：从 Mongo 取基础数据

`_prepare_data()` 中首先读取：

- `SchemaType.POSITION`
- `SchemaType.CASH`

也就是说，`pms` 的第一层数据源是 Mongo 中的业务数据集合，而不是实时拼 SQL。

### 6.2 第二阶段：进入 MOM 语义处理

如果当前组合中包含组合类证券，或者本身是：

- `GROUP`
- `SUB_ACCOUNT`

则会进入 `MomData + MOM` 处理链。

关键代码位置：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/position/position_composition.py:156`
- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/business/mom/mom_data.py:108`

`MomData.generate(...)` 的核心职责是：

1. 构造持有关系 `hold_param`
2. 构造节点特征值 `node_value`
3. 处理多层组合
4. 处理虚母虚子
5. 处理不同透视视角

这意味着：

- `pms` 本身内部就有一套“组合穿透引擎”。

### 6.3 第三阶段：对子层虚母净值做补齐

`position_composition.py` 里有一段非常重要的临时代码：

- 会对 `need_to_correct_nav` 的子层组合额外调用 `get_portfolio_summary_values(...)`
- 然后把 `NAV` 和 `SHARE` 回填到 `node_value`

源代码里甚至明确写了：

- 这是一个临时方案
- 后期应该改掉

这对重构非常重要：

- 说明当前 `PMS` 内部仍然存在“口径补丁式耦合”
- 新系统应尽量把这类逻辑显式建模，而不是继续隐式回填

### 6.4 第四阶段：生成最终持仓视图

后续通过 `MOM.get_hold_position(...)` 输出最终持仓。

如果 `real_all_data` 开启且子层数据未对齐，对应日期会被直接跳过，不输出持仓。

这说明：

- 对同一个时间区间，不同开关参数可能不只是改变数值，还会改变“哪些日期存在结果”。

### 6.5 第五阶段：实时估值

对于不经过 MOM 模块处理的组合，如果 `real_time_quote=true`，则会调用：

- `evaluate_latest_position_and_cash(...)`

这一步会结合 `DataPortal` 和行情接口做最新估值。

结论：

- 返回结果可能不是“静态落库结果”，而是“实时修正后的结果”。

## 7. FOF 透视的真正位置

`FOF` 透视不是 `mom` 实现的，而是在 `pms` 的 `position_composition.py` 最后阶段执行：

- 当 `fof_perspective_method in ['annual', 'latest']`
- 且 `fof_perspective_display in ['summary', 'hierarchy']`

就会构造 `FoFPerspective(...)` 并调用 `fof()`

相关代码位置：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/position/position_composition.py:113`

因此：

- `withFofReportDate`
- `fof_perspective_method`
- `fof_perspective_display`

这些都不是“前端展示附属参数”，而是会改变持仓构成口径的参数。

## 8. 指标接口的真实意义

API 入口：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/api/portfolio/indicator/views.py`

服务层：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/indicator_service.py`

核心计算：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/business/indicator/indicator_calculation.py`

### 8.1 它不是“查现成指标”

`get_portfolio_indicators(...)` 的行为是分两层的：

1. 先从 Mongo 取：
   - `INDICATOR`
   - `DEDUCE_INDICATOR`
2. 再通过 `get_portfolio_summary_values(...)` 补算摘要值

这说明：

- 指标接口不是纯存储读取
- 它也是一个计算型接口

### 8.2 `mom` 为什么要用它

在当前链路中，`mom` 主要用它来拿：

- `netAsset`

然后把层级持仓的市值换算为：

- 占净值比权重

如果没有这一步，后续发给 `brain` 的持仓权重就不成立。

## 9. PMS 的底层依赖

### 9.1 Mongo 和 Redis

`pms.cfg` 中显式配置了：

- Mongo
- Redis

位置：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/etc/pms.cfg`

### 9.2 DataPortal

`DataPortal` 是 `pms` 的内部数据聚合入口，组织了：

- `AssetService`
- `MarketService`
- `UniverseService`
- `FxRateService`
- `PortfolioService`
- `BehaviorService`

位置：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/data_service/data_portal.py`

### 9.3 行情和估值接口

`MarketService` 会通过 `market_interface.py` 继续调用：

- 历史行情
- 最新行情
- 场外基金预测估值
- 债券估值
- 债券应计利息
- 私有资产多源价格

位置：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/data_service/market_service.py`
- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/data_interface/market_interface.py`

### 9.4 data_sdk

`pms` 还通过 `data_sdk` 接到底层数据服务，包括：

- 股票
- 基金
- 债券
- 私有资产
- 组合
- 汇率
- 行情

这也是为什么 `pms` 虽然是一个服务，但本身已经承担了很强的数据聚合职责。

## 10. 对当前请求参数的具体解释

结合当前用户示例，可以把关键参数理解为：

### 10.1 `accountDataFrom=PMS_ELITE`

含义：

- 强制 `mom` 走 `PMS_ELITE` 数据路径准备持仓和指标。

### 10.2 `withFofReportDate=false`

含义：

- 会影响 `FOF` 透视的报告期口径。
- 不是无关参数。

### 10.3 `moneyFundPenetrate=true`

含义：

- 会影响穿透口径。
- 在 `mom` 调用 `PMS` 的持仓查询参数中会被显式透传。

### 10.4 `aiStock=true`

现阶段观察：

- 在 `stockBrinsonAttr -> brain -> mars` 主链上未发现明确生效点。
- 但不能据此推导它在 `PMS` 全局完全无意义，只能说当前专题范围内尚未发现它是归因主链核心参数。

## 11. 重构时应保留的稳定契约

建议把 `PMS_ELITE` 这一层抽象成两个稳定接口，而不是暴露一堆原始细节：

### 11.1 Position Composition Contract

输出应该明确包含：

- 日期
- 层级持仓
- 展示视角
- 是否穿透
- 是否实时估值
- 口径元数据

### 11.2 Portfolio Indicator Contract

输出至少应明确包含：

- `nav`
- `share`
- `net_asset`
- `date`
- `portfolio_id`
- 是否原始数据

## 12. 当前最重要的重构风险

### 12.1 误把 PMS 当成原始数据源

这是最容易犯的错误。

实际上它是：

- 原始数据
- 组合规则
- 穿透规则
- 指标补算
- 实时估值

的混合层。

### 12.2 透视参数不能简单砍掉

尤其是：

- `mom_perspective`
- `perspective_display`
- `fof_perspective_method`
- `fof_perspective_display`
- `with_fof_report_date`
- `real_time_quote`

这些会真实改变结果集。

### 12.3 当前实现中存在临时补丁逻辑

对子层虚母 `NAV/SHARE` 的回填就是一个明显例子。

新系统应优先把这些补丁逻辑显式化。

## 13. 一句话结论

`PMS_ELITE` 在这条链路中承担的是“组合持仓与指标语义层”，而不是简单的底层数据接口。

如果未来要异语言重写，应该优先重建它的“口径契约”，而不是只重写一个持仓查询 API。
