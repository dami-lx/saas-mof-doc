---
tags:
  - brain
  - mars
  - solar
  - saturn
  - dependency
  - refactor
status: draft
updated: 2026-03-27
---

# Brain 本地依赖包边界：mars solar saturn

## 1. 为什么要单独写这篇

如果不把 `brain` 和本地依赖包的边界讲清楚，很容易在重构时误判：

- 以为 `brain` 自己实现了算法
- 或以为 `mars / solar / saturn` 是一些无关的小工具包

实际上，它们之间是明确分工的。

## 2. 已确认的依赖关系

在 `brain/lib` 中可以直接搜到大量依赖：

- `from mars...`
- `from solar...`
- `from saturn...`

这些依赖主要分布在：

- `portfolio_management/algorithm_unit`
- `portfolio_management/parallel_algorithm_unit`
- `analysis`
- `input_loader`

## 3. `mars` 主要承担什么

从当前 import 看，`mars` 主要承担：

### 3.1 持仓归因算法

例如：

- `mars.attribution.holding.equity_attribution`
- `mars.attribution.holding.bond_attribution`
- `mars.attribution.holding.hybrid_attribution`
- `mars.attribution.holding.price_diff_attribution`
- `mars.attribution.holding.other_attribution`
- `mars.attribution.holding.fund_attribution`

### 3.2 净值归因算法

例如：

- `mars.attribution.nav.style_attribution`
- `mars.attribution.nav.selection_timing`

### 3.3 压力测试/情景分析

例如：

- `mars.stress_test.equity.historical_scenario`
- `mars.stress_test.equity.hypothetical_scenario`
- `mars.stress_test.bond.hypothetical_scenario`

结论：

- `mars` 更接近“算法核心包”

## 4. `solar` 主要承担什么

从当前 import 看，`solar` 更偏基础数学与通用配置工具：

例如：

- `solar.math.common_function`
- `solar.config`
- `solar.pandas_util`
- `solar.bond_valuation`

典型用途：

- 净值插值
- 债券收益计算
- 风险计算函数
- 因子顺序与频率配置

结论：

- `solar` 更像“算法基础库与数学工具库”

## 5. `saturn` 主要承担什么

当前在 `brain` 中能明显看到：

- `saturn.simulator.fund_simulation`

说明 `saturn` 至少承担：

- 模拟器
- 组合仿真相关能力

结论：

- `saturn` 更像“模拟执行与仿真工具包”

## 6. brain 与这些包的真实边界

### 6.1 brain 负责什么

- HTTP API
- Celery 调度
- 任务编排
- 数据加载
- 算法输入装配
- 结果包装

### 6.2 mars 负责什么

- 归因算法
- 压力测试算法
- 风格/择时等分析算法

### 6.3 solar 负责什么

- 数学工具
- 配置常量
- 通用序列与计算方法

### 6.4 saturn 负责什么

- 模拟器与仿真能力

## 7. 典型调用模式

### 7.1 股票归因

`brain`：

- 从 `data_loader` 取 exposure / return / industry / benchmark

然后调用：

- `mars.attribution.holding.equity_attribution`

### 7.2 风格分析

`brain`：

- 组织净值和因子数据

然后调用：

- `mars.attribution.nav.style_attribution`
- `solar.config.Q_MAP`

### 7.3 再平衡模拟

`brain`：

- 组织净值、约束、数据输入

然后调用：

- `saturn.simulator.fund_simulation`

## 8. 为什么这层边界很重要

如果未来要异语言重写 `brain`，有三种可能路径：

### 8.1 只重写 API 与调度层

保留：

- `mars`
- `solar`
- `saturn`

这是一条风险最低的路径。

### 8.2 重写数据装配与任务层，算法仍复用本地包

这适合逐步迁移。

### 8.3 连算法层一起迁移

这时必须明确：

- 哪些逻辑属于 `brain`
- 哪些逻辑其实在 `mars / solar / saturn`

否则很容易只迁移了 API 外壳，却遗漏真正算法核心。

## 9. 重构建议

建议未来显式定义以下接口边界：

### 9.1 Brain Domain Request

- 由 `brain` 负责构造

### 9.2 Algorithm Engine Interface

- 由 `mars` 提供

### 9.3 Math Utility Interface

- 由 `solar` 提供

### 9.4 Simulation Interface

- 由 `saturn` 提供

## 10. 一句话结论

`brain` 是“算法运行平台”，而 `mars / solar / saturn` 是它依赖的“算法核心与基础工具层”。
