---
tags:
  - mom
  - nav
  - performance
  - template
  - refactor
status: draft
updated: 2026-03-27
---

# NavPerformanceOverviewTemplate 净值表现链路专题

## 1. 这篇文档回答什么问题

这篇文档专门解释 `NavPerformanceOverviewTemplate` 这条链路在 `mom` 中做了什么，以及它为什么是 `stockBrinsonAttr` 的关键前置依赖。

本文关注的是：

1. 输入参数是怎么构造的。
2. 实际调用了什么计算框架。
3. 输出包含哪些指标和时间序列。
4. 哪些行为属于“净值表现计算”，哪些不应与“归因算法”混在一起。

## 2. 在总链路中的位置

相关总览：

- [stockBrinsonAttr 全链路拆解](./stockBrinsonAttr-全链路拆解.md)

`stockBrinsonAttr` 最终返回结果由两部分组成：

- `NavPerformanceOverviewTemplate`
- `AdvancedAttrTemplate`

前者提供净值表现语义，后者提供归因语义。

因此，`stockBrinsonAttr` 最终并不是“只看归因”，而是“归因 + 净值表现”的复合结果。

## 3. 入口与核心代码

模板文件：

- `/Users/jiangtao.sheng/Documents/demo/codex-mof/mom/mom-web/src/main/java/com/datayes/web/mom/service/card/cardTemplate/common/NavPerformanceOverviewTemplate.java`

参数生成辅助：

- `/Users/jiangtao.sheng/Documents/source/mom-robo/mom-web/src/main/java/com/datayes/web/mom/service/card/loader/ReportCardHelper.java`

核心入口是 `compute(ReportParam reportParam)`。

它的主要流程是：

1. 读取自定义参数：
   - `abnormalNavFilter`
   - `annualQ`
2. 通过 `cardHelper.generateParam(reportParam)` 生成 `MultiIntervalNavPerfParam`
3. 用 `JBrainNavPerfComputerAdapter.generateComputer(...)` 构造净值表现计算器
4. 计算：
   - 组合净值表现
   - 基准净值表现
5. 如果净值点不足，则返回 remark 而非正常结果

## 4. 输入参数是如何生成的

`ReportCardHelper.generateParam(...)` 是这条链路最重要的输入准备逻辑。

核心位置：

- `/Users/jiangtao.sheng/Documents/source/mom-robo/mom-web/src/main/java/com/datayes/web/mom/service/card/loader/ReportCardHelper.java:98`

这个方法做了几件事：

1. 先生成缓存 key。
2. 从内存缓存中读取 `MultiIntervalNavPerfParam`。
3. 未命中时走 `doGenerateParam(...)`。
4. 返回深拷贝，防止外部污染缓存对象。

### 4.1 影响缓存 key 的字段

能进入缓存 key 的字段，就是这条链路真正认为会影响结果的输入。

目前包括：

- `accountId`
- `idVersion`
- `startDate`
- `endDate`
- `benchmark`
- `rebalancePeriod`
- `riskFreeRate`
- `accountDataFrom`
- 自定义净值采样频率
- `navFrequency`
- `fundNavDataSource`

这个点对重构很有价值：

- 如果新系统的缓存键设计缺少这些字段，就可能发生口径串用。

### 4.2 `doGenerateParam(...)` 具体做了什么

它主要组装出一个标准化的净值表现请求对象：

1. 基准：
   - `benchmarkIndexComponent.loadComposition(...)`
2. 基准再平衡日：
   - `rebalancePeriodsGenerator.calculateRebalancePeriods(...)`
3. 无风险利率：
   - `riskFreeRate`
4. 净值前置规则：
   - `preBeginType`
5. 起止日期：
   - `start`
   - `end`
6. 净值频率：
   - 自定义采样频率映射后的 `frequency`
7. 净值序列：
   - `DataLoader.navLoader(param.getAccountDataFrom()).load(filter)`
8. 是否采样：
   - `sampling`

可以看出，这条链路本质上并不是“算某几个指标”，而是先把“净值表现计算问题”抽象成一个标准化输入对象。

## 5. 真实计算框架是什么

`NavPerformanceOverviewTemplate` 并没有直接自己写指标计算公式，而是借助：

- `JBrainNavPerfComputer`
- `JBrainNavPerfComputerAdapter`
- `NavPerfAdapter.getLoader()`

这意味着它依赖的是一套净值表现计算框架，而不是单个算法函数。

### 5.1 组合部分的计算

方法：

- `computeWithPortfolio(...)`

它主要计算：

- 组合累计超额收益
- 组合表现指标集合
- 组合累计收益序列
- 相对基准的相关性
- 胜率
- 盈亏比

关键调用包括：

- `computer.computeActiveAccumulateReturnSeries(false)`
- `JBrainNavPerfComputerAdapter.computeNew(param, indicators)`
- `computer.computeAccumulateReturnSeries(filterOutlier, outlinerBenchmark)`

### 5.2 基准部分的计算

方法：

- `computeWithBenchmark(...)`

它主要计算：

- 基准表现指标
- 基准累计收益序列

特别注意：

- 基准端的 `winRatio` 被固定为 `0D`
- `profitLossRatio` 为 `null`
- `spearman` 和 `pearson` 固定为 `1D`

这说明：

- 组合端和基准端虽然长得像同一模型，但实际并不是完全对称的。
- 新系统不要简单复制一个统一 DTO 再套一样的计算规则。

## 6. 输出到底包含什么

输出对象是：

- `BenchmarkNavPerformanceOverview`

其中实际承载的核心是两个 `NavPerformanceOverview`：

- `portfolio`
- `benchmark`

对 `stockBrinsonAttr` 来说，真正被下游使用的是：

- `portfolio`

其中最关键的内容包括：

- 累计收益
- 年化收益
- IR
- Sharpe
- 累计收益序列
- 累计超额收益
- Spearman / Pearson
- 胜率 / 盈亏比

## 7. 额外口径点

### 7.1 异常净值过滤

`abnormalNavFilterCustomParamHandler` 会控制是否过滤异常净值点。

如果开启，还会根据账户映射加载异常净值过滤基准：

- `OutlinerBenchmarkMappingConfig`

这说明：

- “收益序列怎么算”并不是完全只由原始净值决定，还受异常点过滤配置影响。

### 7.2 自定义年化因子

`annualQCustomParamHandler` 会生成 `CalcParam`。

随后：

- `PerformanceOverviewCalculator.handleCalcParam(...)`

会覆盖或补充部分指标，例如：

- `IR`
- `Sharpe`
- 年化收益

这意味着：

- 这条链路中有一层“通用净值表现框架输出”
- 还有一层“面向业务口径的再修正”

## 8. 和归因链路的边界

这条链路不应该和 `brain/mars` 的归因链路混为一谈。

边界建议如下：

### 8.1 它负责什么

- 净值序列准备
- 基准净值准备
- 收益与风险表现指标
- 累计收益/超额收益序列

### 8.2 它不负责什么

- 行业归因
- 风格因子归因
- Brinson 分解
- 风险模型暴露
- 股票级收益归因

## 9. 重构时建议保留的契约

建议把这条链路抽成一个独立能力，输出一个稳定对象，例如：

```text
NavPerformanceOverviewResult
- portfolio_metrics
- benchmark_metrics
- portfolio_acc_return_series
- benchmark_acc_return_series
- active_acc_return_series
- correlation_metrics
- win_loss_metrics
```

不要把它设计成前端视图专属结构。

理由：

- 它本身是被多个卡片复用的底层能力。
- 未来任何“净值表现 + 其他分析”类卡片都可能依赖它。

## 10. 当前已确认的重构风险

### 10.1 输入缓存键不可随意简化

因为当前缓存键明确包含：

- 账户
- 时间区间
- 基准
- 再平衡周期
- 无风险利率
- 数据来源
- 净值频率

如果新系统缓存键收得过粗，会出现错结果。

### 10.2 基准端不是简单复制组合端逻辑

基准输出的一些字段是固定值或特殊处理值。

### 10.3 年化口径并非完全来自底层框架

存在业务层对年化指标的再计算和覆盖。

## 11. 一句话结论

`NavPerformanceOverviewTemplate` 是 `mom` 中一个独立、可复用的“净值表现计算层”，不是 `stockBrinsonAttr` 的附属逻辑。

如果未来要重构，应把它从“卡片模板”提升为“基础领域服务”。
