---
tags:
  - brain
  - holding_return_contribution
  - java_refactor
status: active
updated: 2026-03-30
---

# holding_return_contribution 接口重构分析

## 1. 接口概述

**路径**: `/api/common/holding_return_contribution`

**功能**: 计算持仓资产的大类资产收益和子类资产收益贡献

**大类**: 基金、股票、债券、期货、现金

**子类**: 单个股票、单个债券等

## 2. 核心算法

### 2.1 ReturnContribution 类

核心计算在 neptune 包的 `ReturnContribution` 类中:

```python
contribution_calculator = ReturnContribution(
    weight_series_dict=weight_series_dict,
    date_list=dat_list
)

# 计算个股贡献
result = contribution_calculator.compute_hybrid_contribution(
    equity_param=equity_param,
    bond_param=bond_param,
    fund_param=fund_param,
    future_param=future_param,
    ...
)

# 计算大类贡献
result = contribution_calculator.compute_hybrid_contribution(
    ...,
    is_group=True
)
```

### 2.2 单期贡献计算

```python
def _period_contribution(trading_day_list, security_return_series_dict, portfolio_weight_series_dict):
    # contribution = weight * return
    security_contr_series = weight_series * security_return_series
```

### 2.3 累积贡献计算

```python
def _accumulate_contribution(trading_day_list, security_contr_series_dict):
    # 几何链接累积
    A = [1.]
    for trading_day in trading_day_list[1:]:
        x_k = security_contr_series_dict[trading_day]
        A.append(A[-1] * (1 + x_k.sum()))

    for i in range(1, len(trading_day_list)):
        tmp = security_contr_series_dict[trading_day_list[i]]
        sec_acc_ret = sec_acc_ret.add(A[i-1] * tmp, fill_value=0)
```

### 2.4 大类资产贡献计算

```python
if is_group:
    # 使用 one-hot 编码按资产类别聚合
    classification_sparse_matrix = pd.get_dummies(security_type_series.loc[idx])
    sector_contr_series = security_contr_series.dot(classification_sparse_matrix)
```

## 3. 资产收益率计算

### 3.1 股票收益率

直接从数据源获取:
```python
equity_return_series_dict = stock.get_stock_return_dict(sec_id_ints, tds=dat_list, freq=frequency)
```

### 3.2 期货收益率

价格百分比变化:
```python
def compute_future_return(future_price_series_dict, trading_day_list):
    future_return_df = pd.DataFrame(future_price_series_dict).T.reindex(trading_day_list).pct_change()
    # 返回每期的收益率
```

### 3.3 债券收益率

考虑全价和现金流的复杂计算:
```python
def compute_bond_return(trading_day_list, cash_flow_df, full_price_series_dict, bond_info_df):
    # 1. 计算期间现金流
    coupon_sum_dict, pure_coupon_dict = _calc_coupon(cash_flow_df, trading_day_list)

    # 2. 计算全价变化 + 现金流
    local_return = (price_diff + coupon) / begin_price
```

### 3.4 可转债收益率

价格百分比变化（与期货类似）:
```python
def compute_convertible_bond_return(price_dict, trading_day_list):
    return_df = pd.DataFrame(price_dict).T.reindex(trading_day_list).pct_change()
```

### 3.5 基金收益率

净值转换为收益率:
```python
def get_return_df_day_index(fund_nav_dict, expand_trading_day_list, expand_interpolate_day_list):
    # 净值插值后计算收益率
    interpolate_nav = nav_series.reindex(inter_day_list).interpolate()
    return_series = reindex_inter.pct_change()
```

## 4. 权重处理

### 4.1 权重归一化

```python
# 处理权重为0，市值不为0的情况
total_value, total_weight = period_holding['VALUE'].sum(), period_holding['WEIGHT'].sum()
if total_value and total_weight:
    period_holding['WEIGHT'] = [
        w if w != 0 else v * total_weight / total_value
        for w, v in zip(period_holding['WEIGHT'], period_holding['VALUE'])
    ]
```

### 4.2 期货空头权重

```python
# 空头权重为负
short_fu_index = calendar_holding_df[
    (calendar_holding_df['CONS_CATEGORY'] == 'FU') &
    (calendar_holding_df['TYPE'] == 'SHORT')
].index
calendar_holding_df.loc[short_fu_index, 'WEIGHT'] = -abs(calendar_holding_df['WEIGHT'])
```

## 5. 输出结构

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

## 6. Java 实现计划

### 6.1 核心类

1. `ReturnContribution` - 主计算类
2. `AssetReturnCalculator` - 各类资产收益率计算
3. `ContributionAccumulator` - 累积贡献计算
4. `HoldingContributionRequest` - 请求解析
5. `HoldingContributionResult` - 结果封装

### 6.2 数据结构

- `WeightSeries` - 权重序列
- `ReturnSeries` - 收益率序列
- `ContributionSeries` - 贡献序列

### 6.3 关键算法

1. 单期贡献: `weight * return`
2. 几何链接累积: `A[k] = A[k-1] * (1 + sum(contribution))`
3. 大类聚合: 按资产类别 one-hot 编码后矩阵乘法

## 7. 测试用例

### 7.1 输入文件

- `brain-holding-return-test/holding_return_contribution2025.json` - 小规模测试
- `brain-holding-return-test/holding_return_contribution2024.json` - 大规模测试

### 7.2 预期输出

- `brain-holding-return-test/output/case2025-result.json`
- `brain-holding-return-test/output/case2024-result.json`

### 7.3 Brain QA 环境

- 域名: `brain-web.respool2.wmcloud-qa.com`
- 端口: 80
- 无需认证
- API: POST `/api/common/holding_return_contribution`
- 任务查询: GET `/api/task/{task_id}`

## 8. Java 实现进度

### 8.1 已完成的类

**Domain 类**:
- `HoldingContributionRequest` - 请求封装（含 `@JsonIgnoreProperties(ignoreUnknown = true)` 处理未知字段）
- `HoldingContributionResult` - 结果封装，包含：
  - `AssetContribution` - 大类资产贡献
  - `SecurityContribution` - 个券贡献
  - `IndustryContribution` - 行业贡献
  - `TimeSeriesPoint` - 时序数据点
- `PositionSnapshot` - 持仓快照
- `Holding` - 持仓明细
- `PositionNav` - 净值序列

**Service 层**:
- `HoldingContributionService` - 主服务类，协调整个计算流程

**Engine 层**:
- `ReturnContributionCalculator` - 核心计算引擎
  - `computeHybridContribution()` - 混合资产贡献计算
  - `computePeriodContribution()` - 单期贡献计算
  - `accumulateContribution()` - 几何链接累积
  - `aggregateByCategory()` - 按类别聚合

**Loader 接口**:
- `ReturnDataLoader` - 收益率数据加载接口
  - `loadEquityReturns()` - 股票收益率
  - `loadBondReturns()` - 债券收益率
  - `loadFutureReturns()` - 期货收益率
  - `loadFundReturns()` - 基金收益率
  - `loadConvertibleBondReturns()` - 可转债收益率
  - `loadPrivateFundNavs()` - 私募基金净值
- `IndustryDataLoader` - 行业数据加载接口
  - `loadEquityIndustry()` - 股票行业映射
  - `loadFutureCategory()` - 期货品种映射

### 8.2 待实现

1. **数据加载器实现** - 需要对接实际数据源：
   - MySQL 数据库
   - REST API
   - 或其他数据服务

2. **期货特殊处理**:
   - 多空方向区分
   - 品种贡献计算
   - 多空贡献计算

3. **私募产品处理**:
   - 净值插值
   - 收益率计算

### 8.3 文件路径

```
brinson-core-java-claude/
├── src/main/java/io/github/brinson/
│   ├── holding/
│   │   ├── domain/
│   │   │   ├── HoldingContributionRequest.java
│   │   │   ├── HoldingContributionResult.java
│   │   │   ├── PositionSnapshot.java
│   │   │   ├── Holding.java
│   │   │   └── PositionNav.java
│   │   ├── engine/
│   │   │   └── ReturnContributionCalculator.java
│   │   ├── loader/
│   │   │   ├── ReturnDataLoader.java
│   │   │   └── IndustryDataLoader.java
│   │   └── service/
│   │       └── HoldingContributionService.java
│   └── ...
└── src/test/java/io/github/brinson/holding/
    └── HoldingContributionTest.java
```

### 8.4 测试验证

测试用例已配置，可以加载输入文件和预期输出进行比对。

**注意事项**:
- Maven settings 需要配置外部仓库访问（temp-settings.xml 已创建）
- 测试使用 `mvn exec:java` 运行，需要 Java 17+
- 预期输出已保存到 `brain-holding-return-test/output/` 目录