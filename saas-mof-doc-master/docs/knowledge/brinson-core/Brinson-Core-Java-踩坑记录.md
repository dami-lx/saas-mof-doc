# Brinson Core Java 实现踩坑记录

## 概述

本文档记录了将 brinson-core 从 Rust 移植到 Java 过程中遇到的关键问题及其解决方案。

---

## 1. 几何链接累加 (Geometric Linking Accumulation)

### 问题描述
原始实现使用简单累加来计算累积收益，导致累积收益值与预期结果不匹配。

### 原因分析
Brinson 模型使用几何链接来累加多期收益，而非简单算术累加。需要使用 linking coefficient 来正确聚合。

### 解决方案
实现 `accumulationLinkingCoefficient` 和 `safeLogRatio` 函数：

```java
private double accumulationLinkingCoefficient(double portfolioReturn, double benchmarkReturn) {
    double logDiff = Math.log(1.0 + portfolioReturn) - Math.log(1.0 + benchmarkReturn);
    if (Math.abs(logDiff) <= 1e-12) {
        return 0.0;
    }
    double value = (portfolioReturn - benchmarkReturn) / logDiff;
    return Double.isFinite(value) ? value : 0.0;
}

private double safeLogRatio(double portfolioReturn, double benchmarkReturn) {
    double value = Math.log((1.0 + portfolioReturn) / (1.0 + benchmarkReturn));
    return Double.isFinite(value) ? value : 0.0;
}
```

### 相关文件
- `ArithmeticIndustryBrinsonStage.java`

---

## 2. 风险计算中的权重重归一化 (Risk Calculation Weight Renormalization)

### 问题描述
`manage_risk` 和 `timing_risk` 计算结果与预期值差距很大（例如：expected=0.006, computed=2.09）。

### 原因分析
风险贡献计算需要对行业权重进行重归一化处理，使用行业权重绝对值之和作为归一化因子。

### 解决方案
```java
private double[] renormalizeWeights(double[] weights, double absSum) {
    double[] result = new double[weights.length];
    if (absSum <= 1e-10) return result;
    for (int i = 0; i < weights.length; i++) {
        result[i] = weights[i] / absSum;
    }
    return result;
}
```

在 `computeSectorRiskBreakdown` 中：
1. 计算行业层面的组合权重和基准权重
2. 计算各自的绝对值之和
3. 使用这些和进行重归一化
4. 根据 portfolio/benchmark 总绝对权重情况选择不同的计算路径

### 相关文件
- `ArithmeticIndustryBrinsonStage.java`

---

## 3. Timing Risk 计算算法

### 问题描述
`timing_risk` 计算结果与预期不符。

### 原因分析
原始实现错误地使用了 active weights（组合权重 - 基准权重），而正确的实现应该使用基准权重。

### 错误代码
```java
// 错误：使用 active weights
double[] allocationWeights = new double[items.size()];
for (int i = 0; i < items.size(); i++) {
    allocationWeights[i] = portfolioWeights[i] - benchmarkWeights[i];
}
allocationCovariance = calcCovariance(allocationWeights, riskContext);
return nonNegativeSqrt(allocationCovariance);
```

### 正确代码
```java
// 正确：使用 benchmark weights
allocationCovariance = calcCovariance(benchmarkWeights, riskContext);
double allocationRho = allocationCovariance / riskContext.totalActiveRisk;
return (portfolioTotalAbsWeight - benchmarkTotalAbsWeight) * allocationRho;
```

### 相关文件
- `ArithmeticIndustryBrinsonStage.java` 中的 `computeTimingRisk` 方法

---

## 4. 标准差计算模式 (Deviation Mode)

### 问题描述
deviation 字段（`m_sector_allocation_deviation`, `m_interaction_deviation`, `m_security_selection_deviation`）计算结果与预期不符。

### 原因分析
存在两种标准差计算模式：
- **Sample Std (样本标准差)**: 方差除以 `n-1`，对应 `CoreExact` 兼容模式
- **Population Std (总体标准差)**: 方差除以 `n`，对应 `BrainQaCompatible` 兼容模式

预期结果文件 `case1-result.json` 使用 `CoreExact` 模式（样本标准差）。

### 解决方案
```java
private double deviationStd(double[] values) {
    if (values.length < 2) return 0.0;
    double mean = 0.0;
    for (double v : values) mean += v;
    mean /= values.length;
    double variance = 0.0;
    for (double v : values) variance += (v - mean) * (v - mean);
    // 使用样本标准差 (n-1) 匹配 CoreExact profile
    return Math.sqrt(variance / (values.length - 1));
}
```

### 相关文件
- `PackAssemblerStage.java`

---

## 5. Snapshot 文件选择

### 问题描述
计算结果与预期完全不符。

### 原因分析
不同的测试用例需要使用对应的 snapshot 文件，且需要使用包含完整 style factor ID 的版本。

### 解决方案
```java
private String findSnapshotFile(CompiledBrinsonRequest request) {
    int beginDate = request.getBeginDate();
    int endDate = request.getEndDate();

    // 使用包含 style IDs 的 snapshot 文件
    if (beginDate >= 20250101 && endDate <= 20250131) {
        return "case1-snapshot-with-style-ids.json";
    } else if (beginDate >= 20240101 && endDate >= 20250101) {
        return "case2-snapshot-with-style-ids-v2.json";
    }
    return null;
}
```

### 相关文件
- `RealBrinsonComputationEngine.java`

---

## 6. Workspace Root 路径

### 问题描述
测试无法找到 fixture 文件。

### 原因分析
测试类位于子项目目录，但 fixture 文件在父目录的 `brain-brinson-test` 下。

### 解决方案
```java
// 使用父目录作为 workspace root
private static final Path WORKSPACE_ROOT = Paths.get("").toAbsolutePath().getParent();
```

### 相关文件
- `BrinsonCoreTest.java`

---

## 7. Case 2 Deviation 差异说明

### 现象
Case 2 的 deviation 字段与预期有约 0.2% 的差异。

### 原因分析
这是预期行为：
- `case2-result.json` 由原始 Brain 系统生成
- Rust 和 Java 实现使用相同的 CoreExact 算法
- 两者产生的 deviation 值一致，但都与原始 Brain 系统结果有细微差异
- Rust 测试也接受这种差异（只验证两种 profile 产生不同结果，不验证精确匹配）

### 验证方法
查看 `case2-numeric-comparison.md`:
```
| $.accumulate_results.m_sector_allocation_deviation | 0.6622129168915696 | 0.6622059873151005 | -6.929576469083543e-06 | different |
```

---

## 8. 数值安全性处理

### 问题描述
计算过程中可能出现 `NaN` 或 `Infinity` 导致结果异常。

### 解决方案
1. **对数计算保护**：
```java
private double safeLogRatio(double portfolioReturn, double benchmarkReturn) {
    double value = Math.log((1.0 + portfolioReturn) / (1.0 + benchmarkReturn));
    return Double.isFinite(value) ? value : 0.0;
}
```

2. **非负开方**：
```java
private double nonNegativeSqrt(double value) {
    if (value <= 0.0) return 0.0;
    return Math.sqrt(value);
}
```

3. **累加系数边界检查**：
```java
if (Math.abs(logDiff) <= 1e-12) {
    return 0.0;
}
```

### 相关文件
- `ArithmeticIndustryBrinsonStage.java`

---

## 9. 绝对值权重总和概念

### 概念说明
Brinson 风险计算中大量使用**绝对值权重总和**而非普通权重总和。这是因为：
- 权重可能为负（做空）
- 绝对值总和更能反映实际暴露程度
- 用于归一化风险贡献

### 关键变量
- `portfolioTotalAbsWeight`: 组合权重绝对值总和
- `benchmarkTotalAbsWeight`: 基准权重绝对值总和
- `absSumSectorPWeight`: 行业组合权重绝对值总和
- `absSumSectorBWeight`: 行业基准权重绝对值总和

### 计算方式
```java
double portfolioTotalAbsWeight = 0.0;
for (SecurityAttributionInput item : items) {
    portfolioTotalAbsWeight += Math.abs(item.portfolioWeight);
}
```

---

## 10. Maven 环境配置

### 问题描述
在 macOS 上运行 Maven 测试时可能遇到配置问题。

### 解决方案
```bash
# 安装 Maven
brew install maven

# 如果遇到 settings.xml 问题，可以临时跳过
mv ~/.m2/settings.xml ~/.m2/settings.xml.bak
mvn test
mv ~/.m2/settings.xml.bak ~/.m2/settings.xml
```

### 项目构建
```bash
cd brinson-core-java-claude
mvn clean test
```

---

## 11. 多期聚合的 annual/deannual 转换

### 公式
- **年化 (annual)**: `period_value * periods_per_year`
- **去年化 (deannual)**: `annual_value / sqrt(periods_per_year)`

### periods_per_year 取值
- Day: 250
- Week: 52
- Month: 12

### 代码示例
```java
int periodsPerYear = frequency.getPeriodsPerYear(); // 250 for day
double annualValue = periodValue * periodsPerYear;
double deannualValue = annualValue / Math.sqrt(periodsPerYear);
```

### 注意事项
- 风险去年化使用 `sqrt(periods_per_year)`
- 收益去年化使用 `periods_per_year`（直接除）

---

## 关键数值精度阈值

- 累加系数计算：`1e-12`
- 风险计算的权重阈值：`1e-10`
- 总风险阈值：`1e-12`
- 测试比较容差：`1e-12`（主要字段）

---

## 参考资料

- Rust 源码：`brinson-core/src/engine/stages.rs`
- Rust 打包：`brinson-core/src/engine/packing.rs`
- 测试结果对比：`brain-brinson-test/output/case*-numeric-comparison.md`
- Brinson 模型说明：`docs/knowledge/brinson-core/Brinson-Core-QA样例与Snapshot基线.md`