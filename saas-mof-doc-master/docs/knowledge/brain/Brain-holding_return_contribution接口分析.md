---
tags:
  - brain
  - holding_return_contribution
  - refactor
status: active
updated: 2026-03-30
---

# holding_return_contribution 接口分析

## 1. 接口概述

**路径**: `/api/common/holding_return_contribution`

**功能**: 计算持仓资产的大类资产收益和子类资产收益贡献

**大类**: 基金、股票、债券、期货、现金

**子类**: 单个股票、单个债券等

## 2. 输入格式

```json
{
  "secIdInt": null,           // 公募基金ID（可选，与position二选一）
  "fundType": "self",         // 基金类型
  "beginDate": "20250101",    // 开始日期
  "endDate": "20250117",      // 结束日期
  "preBeginDate": "20241231", // 前一日期
  "isMutual": false,          // 是否公募
  "frequency": "day",         // 频率: day, week, month, semi, season
  "position": [...],          // 持仓列表
  "positionNavs": [...]       // 净值序列（私有产品）
}
```

### 2.1 Position 结构

```json
{
  "date": "20241231",
  "cashFlow": 0.0,
  "cashHolding": 0.0,
  "holding": [
    {
      "consPositionId": "10003956",   // 证券ID
      "exchangeCd": "XHKG",           // 交易所代码
      "consCategory": "E",            // 资产类别: E(股票), B(债券), F(基金), FU(期货), CB(可转债)
      "price": null,
      "volume": 6600.0,
      "weight": 0.244,                // 权重
      "type": "LONG",                 // 方向: LONG, SHORT
      "value": 2548647.29,            // 市值
      "securityType": "stock"
    }
  ]
}
```

### 2.2 资产类别编码

| 编码 | 含义 |
|------|------|
| E | 股票（A股+港股） |
| B | 债券（不含可转债） |
| CB | 可转债 |
| F | 基金 |
| PF | 私募基金 |
| FU | 期货 |
| I_L | 股指期货多单 |
| I_S | 股指期货空单 |
| C_L | 商品期货多单 |
| C_S | 商品期货空单 |
| R_L | 国债期货多单 |
| R_S | 国债期货空单 |
| SP | 私有产品 |
| NS | 非标 |
| SM | 模拟组合 |
| PD | 投后组合 |

## 3. 输出格式

```json
{
  "asset_contribution": [...],           // 大类资产贡献
  "future_contribution": [],             // 期货贡献（预留）
  "fund_contribution": [],               // 基金贡献（预留）
  "security_contribution": [...],        // 个券贡献
  "equity_industry_contribution": [...], // 股票行业贡献
  "future_category_contribution": [...], // 期货品种贡献
  "future_long_short_contribution": [...] // 期货多空贡献
}
```

### 3.1 security_contribution 结构

```json
{
  "CONS_SECURITY_ID_INT": 10003956,  // 证券ID
  "TYPE": "LONG",                    // 方向
  "accumulate_value": 0.05,          // 累积贡献值
  "ratio": 0.02,                     // 贡献比例
  "category": "E",                   // 资产类别
  "sector": "银行"                   // 行业（仅股票）
}
```

### 3.2 asset_contribution 结构

```json
{
  "category": "E",           // 资产类别
  "accumulate_value": 0.1,   // 累积贡献值
  "ratio": 0.3               // 贡献比例
}
```

## 4. 核心计算逻辑

### 4.1 数据加载

1. **股票数据**:
   - 收益率序列: `stock.get_stock_return_dict()`
   - 行业信息: `stock.get_stock_industry_dict()`

2. **债券数据**:
   - 现金流: `bond.get_cash_flow()`
   - 估值: `get_bond_valuation()`
   - 基本信息: `bond.get_info()`

3. **期货数据**:
   - 收盘价: `future.get_future_close_price_df()`
   - 合约信息: `future.get_future_info_df()`

4. **基金数据**:
   - 净值: `fund.get_mutual_fund_nav_df()`

### 4.2 贡献计算

核心类: `ReturnContribution` (来自 neptune 包)

```python
contribution_calculator = ReturnContribution(
    weight_series_dict=weight_series_dict,
    date_list=dat_list
)

# 计算个股贡献
security_contr_df = contribution_calculator.compute_hybrid_contribution(
    equity_param=equity_param,
    bond_param=bond_param,
    fund_param=fund_param,
    future_param=future_param,
    ...
)['sec_acc_df']

# 计算大类贡献
category_contr_df = contribution_calculator.compute_hybrid_contribution(
    ...,
    is_group=True
)['sec_acc_df']
```

## 5. 权重处理

### 5.1 权重归一化

```python
# 处理权重为0，市值不为0的情况
total_value, total_weight = period_holding['VALUE'].sum(), period_holding['WEIGHT'].sum()
if total_value and total_weight:
    period_holding['WEIGHT'] = [
        w if w != 0 else v * total_weight / total_value
        for w, v in zip(period_holding['WEIGHT'], period_holding['VALUE'])
    ]
```

### 5.2 期货空头权重

```python
# 空头权重为负
short_fu_index = calendar_holding_df[
    (calendar_holding_df['CONS_CATEGORY'] == 'FU') &
    (calendar_holding_df['TYPE'] == 'SHORT')
].index
calendar_holding_df.loc[short_fu_index, 'WEIGHT'] = -abs(calendar_holding_df['WEIGHT'])
```

## 6. 关键依赖

- `neptune.index_calculator.holding_index.contribution.ReturnContribution`
- `solar.math.common_function.compute_bond_return`
- Redis 缓存（收益率、行业等数据）

## 7. 待确认事项

1. `ReturnContribution` 类的具体实现（在 neptune 包中）
2. 累积贡献的计算公式
3. 多期聚合的年化方式