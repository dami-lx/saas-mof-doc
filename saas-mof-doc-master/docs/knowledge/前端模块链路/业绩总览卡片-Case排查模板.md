---
tags:
  - invested
  - ams
  - performance
  - nav
  - troubleshooting
status: active
updated: 2026-03-31
---

# 业绩总览卡片 Case 排查模板

## 1. 模板用途

这份模板用于统一排查 `业绩总览` 卡片问题，避免不同同学在不同页面状态下拿不同结果互相比。

推荐用于：

- 客户反馈图表或指标不一致
- QA 与开发结果对不上
- 新旧系统重构后做结果比对

## 2. Case 基本信息

| 项目 | 内容 |
| --- | --- |
| Case 名称 |  |
| accountId / 产品 ID |  |
| 产品名称 |  |
| 页面入口 |  |
| cardKey | `performanceOverview` |
| independent key | `navPerformanceOverview` |
| 提报时间 |  |
| 提报人 |  |

## 3. 当前页面状态

先把页面状态记全，再谈结果对不对。

| 项目 | 内容 |
| --- | --- |
| 当前 Tab | `收益走势` / `净值走势` |
| 当前频率 | `original` / `week` / `month` |
| 当前日期区间 |  |
| 是否过滤异常点 | 是 / 否 |
| 是否包含转型前业绩 | 是 / 否 |
| 是否设置年化因子 | 是 / 否 |
| `annualQ.returnQDays` |  |
| `calendarType` |  |
| 当前展示超额收益类型 | `extReturnSeries` / `activeReturnDivSeries` |
| 当前选中的指标列表 |  |

## 4. 现象分类

先判断问题属于哪一类：

- 只有收益走势图异常
- 只有净值走势图异常
- 只有表格指标异常
- 图和表都异常
- 只有组合侧异常
- 只有基准侧异常
- 只有相对基准结果异常

## 5. 一线判断规则

### 5.1 如果只有收益走势图异常

优先确认：

- 是否勾选了 `过滤异常点`
- 当前是否在 `收益走势` tab
- 当前频率是否一致
- 当前日期区间是否一致
- 当前看的是算术超额还是几何超额

### 5.2 如果只有净值走势图异常

优先确认：

- 当前 tab 是否是 `净值走势`
- `navTimeSeries` / `weeklyNavTimeSeries` / `monthlyNavTimeSeries` 用的是哪套
- 当前频率是否一致
- 是否并入了转型前业绩

### 5.3 如果只有指标异常

优先确认：

- 是否设置了 `annualQ`
- 是否包含转型前业绩
- 是否是组合侧还是基准侧字段
- 持仓附加指标是否单独缺失

## 6. 关键请求参数记录

建议直接记录本次请求参数，避免口头描述。

```json
{
  "abnormalNavFilter": false,
  "customNavStartDate": "",
  "customNavEndDate": "",
  "transformationFundContinuation": false,
  "navSampleFrequency": "original",
  "annualQ": {
    "returnQDays": ""
  },
  "calendarType": ""
}
```

## 7. 关键返回字段核对

### 7.1 顶层字段

| 字段 | 期望 | 实际 | 备注 |
| --- | --- | --- | --- |
| `portfolio` |  |  |  |
| `benchmark` |  |  |  |
| `navTimeSeries` |  |  |  |
| `extReturnSeries` |  |  |  |
| `activeReturnDivSeries` |  |  |  |
| `originalNavFrequency` |  |  |  |
| `transformDates` |  |  |  |

### 7.2 组合指标字段

| 字段 | 期望 | 实际 | 备注 |
| --- | --- | --- | --- |
| `annualTotalReturn` |  |  |  |
| `annualActiveReturn` |  |  |  |
| `activeAnnualReturnDiv` |  |  |  |
| `annualTotalRisk` |  |  |  |
| `annualActiveRisk` |  |  |  |
| `totalReturn` |  |  |  |
| `calmarRatio` |  |  |  |
| `sharpeRatio` |  |  |  |
| `ir` |  |  |  |
| `maxDrawdownRecoverDays` |  |  |  |

### 7.3 基准指标字段

| 字段 | 期望 | 实际 | 备注 |
| --- | --- | --- | --- |
| `annualTotalReturn` |  |  |  |
| `annualTotalRisk` |  |  |  |
| `sharpeRatio` |  |  |  |
| `winRatio` |  |  | 是否仍为兼容常量 |
| `profitLossRatio` |  |  | 是否仍为兼容常量 |
| `spearman` |  |  | 是否仍为兼容常量 |
| `pearson` |  |  | 是否仍为兼容常量 |

## 8. 分层定位

建议把问题固定分到下面四层之一：

### 8.1 页面状态层

常见问题：

- tab 不一致
- 频率不一致
- 异常点过滤开关不一致
- 是否包含转型前业绩不一致
- 年化因子设置不一致

### 8.2 DTO / 打包层

常见问题：

- 返回字段缺失
- 周频 / 月频序列挂错
- `transformDates` 丢失
- `benchmark` 兼容字段不符合旧口径

### 8.3 计算层

常见问题：

- 年化收益或年化风险与旧系统不一致
- 算术超额和几何超额口径混淆
- `annualQ` 修正没有生效

### 8.4 数据层

常见问题：

- 组合净值历史缺失
- 基准净值缺失
- 转型历史拼接异常
- 持仓补充数据缺失

## 9. 结论模板

### 9.1 结论摘要

- 问题归属层：`页面状态 / DTO 打包 / 计算 / 数据`
- 根因：  
- 是否可复现：是 / 否
- 是否影响客户：高 / 中 / 低

### 9.2 处理建议

- 是否需要调整前端展示：  
- 是否需要调整 `mom` 模板：  
- 是否需要调整 `brain` 计算：  
- 是否需要补数或修复底层净值：  

## 10. 附件清单

- 页面截图：
- 请求参数：
- 返回 JSON：
- 对照结果：
- 相关产品信息：
