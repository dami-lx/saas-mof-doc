---
tags:
  - invested
  - ams
  - attribution
  - industry
  - brain
  - mom
  - mof-web-fe
status: active
updated: 2026-03-31
---

# A股行业归因卡片项目实现与排查说明

## 1. 这篇文档解决什么问题

这篇文档是 [A股行业归因卡片客户业务说明](./A股行业归因卡片-客户业务说明.md) 的内部补充版。

客户版解决：

- 卡片业务含义怎么解释
- 主动收益 / 主动风险 / 主动权重怎么讲

本篇内部版解决：

- 前端入口在哪里
- 前后端字段怎么对应
- `mom` / `brain` / `mars` 各负责什么
- 展示的是哪部分 Brinson 结果
- 行业分类和年化切换会影响什么
- 遇到异常时先查哪里

## 2. 功能档案

### 2.1 卡片身份

- 卡片名称：`A股行业归因`
- card key：`stockIndustryAttr`
- 前端 independent key：`stockIndustryAttr`

关键文件：

- `mof-web-fe/js/v2/cards/+productAnalysis/attrIndustry/config.card.tsx`
- `mof-web-fe/js/v2/cards/+productAnalysis/attrIndustry/index.tsx`
- `mof-web-fe/js/v2/cards/+productAnalysis/attrIndustry/views/publicStock.tsx`
- `mof-web-fe/js/v2/cards/+productAnalysis/attrIndustry/services.ts`

### 2.2 和风格归因的差异

这张卡片与 `A股风格归因` 的核心差异是：

- 只看主动值，没有绝对值切换
- 没有稳定性图
- 支持行业分类切换
- 展示的是行业管理贡献，不展示行业逐项的 timing

### 2.3 页面交互

当前主要交互包括：

- `显示年化值`
- `行业分类切换`
- `穿透方式切换`

前端当前选择器实际限制为：

- `ZJ_1`
- `ZJ_2`

也就是：

- 证监会一级
- 证监会二级

## 3. 前端展示规则

### 3.1 数据对象

前端最终消费的主对象是：

- `industryBenchmark`

从名字上看容易误解，但这里的语义是：

- 行业主动归因结果列表

不是基准自身结果。

### 3.2 三张图的字段选择

年化状态下：

- 主动收益图用 `return`
- 主动风险图用 `risk`
- 主动权重图用 `weight`

非年化状态下：

- 主动收益图用 `deannualReturn`
- 主动风险图用 `deannualRisk`
- 主动权重图用 `deannualWeight`

### 3.3 总和规则

每张图标题的总和，都来自前端对当前列表字段直接求和：

- `sum(return or deannualReturn)`
- `sum(risk or deannualRisk)`
- `sum(weight or deannualWeight)`

因此排查总和问题时：

- 不要去找独立后端总数字段
- 直接以返回列表逐项求和为准

### 3.4 排序规则

前端柱图会按当前字段降序排序：

- 收益图按收益排序
- 风险图按风险排序
- 权重图按权重排序

这意味着：

- 同一行业在三张图中的顺序可能不同

## 4. 前后端字段映射

### 4.1 前端对象字段

`industryBenchmark` 列表的常见字段：

- `name`
- `return`
- `deannualReturn`
- `risk`
- `deannualRisk`
- `weight`
- `deannualWeight`
- `factorType`

### 4.2 `mom` 展示层映射

`mom` 最终返回的是：

- `summaryStyles`

前端 mapper 会把它转成：

- `industryBenchmark = summaryStyles`

并额外派生出：

- `industry.annual_return`
- `industry.annual_risk`
- `industry.weight`

等辅助结构。

### 4.3 `mom` 的聚合方式

`mom` 的 `IndustryAttrSupport.buildAttrIndustry(...)` 会按行业名分组，然后把三种归因类型分别塞入同一个 `SummaryStyle`：

- `active_return`
- `active_risk`
- `active_weight`

因此前端每一行行业数据，本质上是：

- 某行业的一行主动收益、主动风险、主动权重

## 5. 整体调用链

### 5.1 前端

前端卡片入口：

- `mof-web-fe/js/v2/cards/+productAnalysis/attrIndustry/index.tsx`

展示层：

- `views/publicStock.tsx`

### 5.2 `mom`

卡片模板入口：

- `mom/mom-web/.../StockIndustryAttrTemplate.java`

这层主要负责：

- 复用 `AdvancedAttrTemplate`
- 从 `AdvancedAttr.getBrinsonIndustryAttr()` 取行业归因底表
- 用 `IndustryAttrSupport.buildAttrIndustry(...)` 转成前端所需结构

### 5.3 `brain`

`mom` 依然是请求：

- `/api/equity/advanced_attribution`

也就是说：

- 行业归因卡片和风格归因卡片，本质上共享同一次 `AdvancedAttr` 计算大链

### 5.4 `mars`

行业归因底层仍由：

- `EquityBrinsonAttribution`

完成单期与累计计算。

## 6. 这张卡片展示的是哪部分 Brinson 结果

这是最重要的内部口径。

`brain` 在 `pack_accum_annualized_unannualized_industry_attr(...)` 中打包行业卡片数据时：

- 主动收益来自 `accumulated_management_df`
- 主动风险来自 `accumulated_management_df`
- 主动权重来自 `accumulated_sector_weight_series['active']`

其中主动收益 / 主动风险的行业值，都是对行业内三项管理贡献求和后得到：

- `sector_allocation`
- `equity_selection`
- `interaction`

因此这张卡片显示的是：

- 行业管理收益
- 行业管理风险
- 行业主动权重

它不直接显示：

- `timing_return`
- `timing_risk`

这些 timing 结果属于 Brinson 总结层，会在 `accumulate_results` 或 Brinson 树图那类视图中体现，而不会拆到行业条目上。

## 7. 关键公式

### 7.1 行业主动权重

设：

- `W_p,i` = 组合行业权重
- `W_b,i` = 基准行业权重

则：

- `W_a,i = W_p,i - W_b,i`

### 7.2 行业主动收益

设：

- `R_p,i` = 组合在行业 `i` 内的收益
- `R_b,i` = 基准在行业 `i` 内的收益

则：

- `Allocation_i = (W_p,i - W_b,i) × R_b,i`
- `Selection_i = W_b,i × (R_p,i - R_b,i)`
- `Interaction_i = (W_p,i - W_b,i) × (R_p,i - R_b,i)`

行业展示收益为：

- `ActiveReturn_i = Allocation_i + Selection_i + Interaction_i`

### 7.3 行业主动风险

风险也按与收益对应的三部分拆分：

- 配置风险
- 选股风险
- 交互风险

底层风险贡献使用风险模型协方差和主动风险归一化结果进行分解。

行业展示风险为：

- `ActiveRisk_i = AllocationRisk_i + SelectionRisk_i + InteractionRisk_i`

对于大多数排查场景，不需要先下钻到更细的矩阵公式，先确认：

- 当前看的是行业管理风险，而不是 timing risk

通常就能避免一半以上误判。

## 8. 关键口径

### 8.1 只看主动，不看绝对

这张卡片没有绝对值模式。

### 8.2 行业收益是管理收益，不含 timing

行业条目显示的是：

- 配置
- 选股
- 交互

不显示：

- timing

### 8.3 主动权重没有额外过滤

和风格卡片不同，这里没有 `特殊性成分` 需要排除。

### 8.4 年化 / 非年化会影响三张图

这张卡片里：

- 收益会变
- 风险会变
- 权重也会跟着切换字段

但字段是否真的不同，要以返回值为准；不要直接套用风格归因卡片“权重不变”的经验。

### 8.5 行业分类切换会改变结果

行业分类切换不是只改展示名，而是：

- 重新定义股票归属行业
- 因而会改变每个行业条目的收益、风险和权重

## 9. 容易误解的点

### 9.1 把这张卡片当成完整 Brinson 结果

它不是完整 Brinson 总结页，而是：

- 行业条目视角

### 9.2 误以为行业条目里包含 timing

实际上不包含。

### 9.3 误把 `industryBenchmark` 理解成基准自身

这里仍然是主动值列表。

### 9.4 用风格卡片的经验判断行业卡片

两者共享同一大链，但展示口径不完全相同。

### 9.5 忽略行业分类切换的影响

不同分类体系下，行业条目和结果不应直接做一一对应比较。

## 10. 常见排查入口

### 10.1 总和不对

先查：

- 当前是否同一行业分类
- 当前是否同一年化状态
- 是否拿排序后的图去和未排序的原表逐行比较

### 10.2 和 Brinson 树图对不上

先查：

- 行业卡片只看 management
- Brinson 总图还包含 timing

### 10.3 行业切换后结果变化很大

先查：

- 是否切换了行业分类体系
- 是否切换了穿透方式

### 10.4 页面无数据

先查：

- A 股持仓是否足够
- 是否有基准
- 是否形成完整归因周期

## 11. 推荐阅读顺序

如果只是要业务解释：

1. [A股行业归因卡片客户业务说明](./A股行业归因卡片-客户业务说明.md)

如果要做排查：

1. 本文
2. [stockBrinsonAttr 全链路拆解](../stockBrinsonAttr-全链路拆解.md)
3. [Brinson Core 知识库 MOC](../brinson-core/Brinson-Core-知识库-MOC.md)

如果要做重构：

1. 本文
2. [stockBrinsonAttr 全链路拆解](../stockBrinsonAttr-全链路拆解.md)
3. `brain` / `mars` / `brinson-core` 对应专题
