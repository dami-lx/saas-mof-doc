---
tags:
  - brain
  - risk-model
  - redis
  - attribution
  - refactor
status: active
updated: 2026-03-28
---

# Brain 风险模型数据专题

## 1. 这篇文档解决什么问题

这篇文档专门回答 `brain` 里的“风险模型数据”到底是什么、从哪里来、怎样进入算法，以及未来重构时应当把它抽象成什么样的稳定数据契约。

这里的“风险模型数据”主要指股票侧归因、风格暴露、风险分解里使用的几类核心输入：

- `exposure`
- `factor_covariance`
- `specific_risk`
- `factor_return`
- `specific_return`

## 2. 关键源码位置

主要文件：

- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/data_loader/risk_model.py`
- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/data_loader/brain_redis/risk_model.py`
- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/data_loader/brain_redis/dump.py`
- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/portfolio_management/input_loader/holding_attr/equity_holding_attr_loader.py`
- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/portfolio_management/input_loader/holding_attr/equity_advanced/equity_advanced_holding_attr_loader.py`
- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/portfolio_management/parallel_algorithm_unit/parallel_tasks/equity.py`
- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/portfolio_management/algorithm_unit/holding_attr/equity_advanced/equity_attribution_advanced.py`

## 3. 先给一个结构性结论

对股票归因主链来说，`brain` 并不是实时直接查风险模型数据库。

它的主路径更像：

1. 底层 MySQL / Oracle 提供原始风险模型数据。
2. `brain_redis.dump` 负责把这些数据预热到 Redis。
3. 运行时算法几乎统一从 `brain_redis.risk_model` 读取缓存。
4. 输入加载器再把这些缓存包装成统一的 `risk_model_dict` 结构给算法层消费。

所以从重构视角看，最应该显式建模的不是“某张库表”，而是这个统一输入契约。

## 4. 风险模型在代码中的职责分层

## 4.1 外观层：`lib/data_loader/risk_model.py`

这个文件本身非常薄，它扮演的是统一 facade。

可以确认：

- 股票风险模型相关函数来自 `lib.data_loader.brain_redis.risk_model`
- 债券风险模型相关函数根据 `db_type` 来自 `dy_mysql.risk_model` 或 `dy_oracle.risk_model`

这意味着：

- 股票侧风险模型主链是 Redis 缓存驱动
- 债券侧风险模型更偏底层库适配驱动

这也是判断 `mysql_riskmdl_db` 是否是“股票归因运行期硬依赖”的关键依据：

- 对股票侧运行时主链，答案偏向“不是”
- 对缓存预热、底层回源、某些债券或非缓存链路，答案是“仍然有用”

## 4.2 缓存读取层：`brain_redis/risk_model.py`

这个文件是股票风险模型读取主入口。

它提供的能力包括：

- `get_exposure`
- `get_specific_risk`
- `get_factor_covariance`
- `get_factor_return`
- `get_specific_return`
- 以及对应的 `*_by_tds` 批量版本

这些函数直接决定了算法层能看到什么数据形态。

## 4.3 缓存预热层：`brain_redis/dump.py`

这个文件负责把底层风险模型数据批量 dump 到 Redis。

从代码可见，至少有这些 dump 能力：

- `dump_risk_model`
- `dump_risk_model_cne6`
- `dump_factor_return`
- `dump_factor_return_cne6`

这说明运行时查询性能依赖“预热缓存是否完整”，而不只是底层 DB 是否可用。

## 5. 风险模型数据项的具体含义

## 5.1 `exposure`

含义：

- 单个证券对风格因子、行业因子的暴露矩阵

典型形态：

- `pd.DataFrame`
- `index = sec_id_int / security id`
- `columns = style factors + industry factors`

它在算法中的作用是：

- 把持仓权重映射到因子空间
- 用于计算主动暴露、组合暴露、风格偏好等结果

## 5.2 `factor_covariance`

含义：

- 因子收益之间的协方差矩阵

典型形态：

- `pd.DataFrame`
- `index/columns = factor names`

它在算法中的作用是：

- 结合暴露与权重，计算 ex-ante 风险
- 用于风格稳定性、主动风险、组合风险分解

## 5.3 `specific_risk`

含义：

- 单只证券的特质风险

典型形态：

- `pd.Series`
- `index = sec_id_int / security id`

它在算法中的作用是：

- 与因子风险一起构成总风险的另一部分

## 5.4 `factor_return`

含义：

- 每个交易日的因子收益序列

典型形态：

- `dict[td] -> pd.Series`

它在算法中的作用是：

- 做风格因子归因
- 生成风格贡献、风格收益时间序列

## 5.5 `specific_return`

含义：

- 每个交易日、每只证券的特质收益

典型形态：

- `dict[td] -> pd.Series`

它在算法中的作用：

- 在历史情景、风险拆解等场景中与因子收益配合使用

## 6. 风险模型数据从哪里来

## 6.1 底层来源

从 `brain_redis/dump.py` 的导入关系可以看到：

- 若 `db_type = mysql`，则风险模型原始数据来自 `lib.data_loader.dy_mysql.risk_model`
- 若 `db_type = oracle`，则来自 `lib.data_loader.dy_oracle.risk_model`

也就是说 Redis 不是原始真源，而是运行时主缓存。

补充一个经过真实探测后的判断：

- 当前股票归因运行链路只要 Redis 风险模型缓存完整，就不需要在请求执行期直接命中 `riskmdl` MySQL
- `riskmdl` MySQL 更像 dump / 回源层，而不是运行时主读路径

## 6.2 dump 到 Redis 的流程

`dump_risk_model` / `dump_factor_return` 的行为大致是：

1. 按交易日区间切 batch
2. 批量从底层 risk model loader 读取
3. 用 `to_pickle_xz` 压缩序列化
4. 写入 Redis 对应 key

可确认的缓存内容包括：

- exposure
- factor covariance
- specific risk
- factor return

这意味着未来如果重写，不论底层数据源换不换，都需要保住“预热成可快速按日读取的风险模型缓存”这层能力。

## 7. Redis 读取时的数据行为

## 7.1 单日读取

单日读取函数会：

1. 按日期和模型版本拼接 Redis key
2. `rdb.get(name)`
3. `read_pickle_xz(result)` 解压回 pandas 对象

## 7.2 多日批量读取

批量读取函数会使用 `pipeline` 一次性拉多个交易日，例如：

- `get_exposure_by_tds`
- `get_factor_covariance_by_tds`
- `get_specific_risk_by_tds`

这说明上层算法在长区间归因时，已经显式优化过 Redis 往返次数。

结合本次真实环境探测，还可以再补一个非常重要的实现事实：

- 当前 Redis 是 cluster 模式，不是单机
- 调试脚本如果直接拿一个节点去 `GET`，会碰到 `MOVED`
- 所以后续重构配套工具必须具备 cluster-aware 访问能力

## 7.3 非交易日与缺失回填

批量读取逻辑里可以看到一个很关键的设计：

- 如果起始日不是交易日，先取前一个交易日
- 若某些日子 Redis 中缺少数据，则复用前一个交易日的数据

这意味着系统实际上允许“风险模型按最近交易日对齐”，而不是要求请求日期必须和风险模型发布日期完全一致。

这个行为对未来重写很重要，因为它不是数据源细节，而是实际业务口径。

## 7.4 缺失值处理

读取后常见处理包括：

- `fillna(0)`
- 对指定证券集合 `reindex`
- 对无效证券过滤 `index > 0`

这说明上层算法依赖的是“已对齐、可计算”的矩阵，而不是完全原始的风险模型快照。

## 8. 模型版本与 schema

当前源码里至少有两个维度的风险模型切换。

## 8.0 关于 `riskmdl` 数据库是否“没有在代码中使用”

这个问题需要区分“代码里被引用”和“运行时主链是否依赖”。

### 结论先说

- `riskmdl` 数据库在代码里 **是有使用的**
- 但对股票 Brinson / 股票归因的运行时主链，它 **不是当前最主要的直接读取入口**

### 为什么说“代码里有使用”

`brain_redis.dump` 在预热风险模型缓存时，会按 `db_type` 导入底层 risk model loader：

- `lib/data_loader/brain_redis/dump.py`

在 MySQL 模式下它会导入：

- `lib.data_loader.dy_mysql.risk_model`

再进一步进入：

- `lib.data_loader.dy_mysql.risk_model_sw21`

这些函数内部明确调用了：

- `query_riskmdl`

也就是说：

- riskmdl 库仍然是风险模型原始数据的上游来源之一

### 为什么又说“不是运行时主入口”

股票侧统一 facade：

- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/data_loader/risk_model.py`

其中股票相关函数直接来自：

- `lib.data_loader.brain_redis.risk_model`

而 `equity_advanced_holding_attr_loader` 在装载 `risk_model_dict` 时调用的也是：

- `rm.get_exposure`
- `rm.get_factor_covariance`
- `rm.get_specific_risk`

这组函数在 facade 层被绑定到 Redis 读取实现，而不是 MySQL riskmdl 直查实现。

所以更准确的说法是：

- `riskmdl` 被用于“缓存预热 / 原始数据回源 / 部分底层适配”
- 不是股票归因请求执行时的主读取路径

## 8.1 行业体系切换：`use_riskmdl_sw21`

在 `brain_redis/risk_model.py` 中：

- 如果 `use_riskmdl_sw21 = True`
- 则 exposure / covariance / specific risk / factor return / specific return 的 key 命名会切到 `sw21` 版本

这表示行业口径切换并不只是算法层概念，也会影响缓存命名与底层数据来源。

## 8.2 模型版本切换：`cne5` / `cne6`

代码里还能看到：

- 默认 `model_version='cne5'`
- 也支持 `cne6`
- 不同版本使用不同 schema：
  - `RISK_MODEL_SCHEMA`
  - `RISK_MODEL_SCHEMA_CNE6`

这说明“风险模型”并不是单一结构体，而是带版本的领域对象。

## 8.3 schema 的真正作用

上层算法并不只拿数据矩阵，还依赖 `schema` 提供：

- `style_field`
- `industry_field`

比如行业归因、风格归因在组装结果时会依赖这些字段做分类、排序和输出封装。

所以未来重写时不能只保留数值矩阵，还必须保留因子分类元数据。

## 9. 风险模型如何进入算法层

## 9.1 输入加载器中的统一装配

在 `equity_holding_attr_loader.py`、`equity_advanced_holding_attr_loader.py` 以及并行任务 `parallel_tasks/equity.py` 中，可以看到统一装配逻辑：

```python
risk_model_dict = {
    "data": {
        td: {
            "exposure": ...,
            "factor_covariance": ...,
            "specific_risk": ...
        }
    },
    "schema": RISK_MODEL_SCHEMA
}
```

同时还会并行装配：

- `factor_return_series_dict`
- `security_return_series_dict`
- `benchmark_weight_series_dict`
- `portfolio_weight_series_dict`
- `security_sector_series_dict`

这组结构其实就是股票归因算法的真实输入契约。

## 9.2 算法消费方式

以 `equity_attribution_advanced.py` 里的 `calc_style_stability` 为例，算法会：

1. 取某一日的 `exposure`
2. 取同日 `factor_covariance`
3. 取同日 `specific_risk`
4. 与组合权重、基准权重做证券交集对齐
5. 再按暴露列顺序重排协方差矩阵
6. 最后计算主动风险、组合风险、风格暴露稳定性

这说明上层算法依赖的不是松散数据，而是日级别严格对齐后的三元组：

- 暴露矩阵
- 因子协方差
- 特质风险

## 10. 与其他外部数据的耦合关系

风险模型数据并不是孤立输入，它至少和以下外部数据一起使用：

- 股票收益：`stock.get_stock_return`
- 股票行业：`stock.get_stock_industry`
- 组合持仓：来自 PMS / 账户持仓展开
- 基准持仓：`benchmark.composite_holding_weight`
- 交易日历：`cal.get_trading_days`

所以从系统边界看，风险模型模块更准确的名字应该是：

`股票归因核心市场数据包`

而不只是狭义的“风险模型查询器”。

## 11. 对未来重构最重要的稳定契约

## 11.1 契约一：按日读取，而不是按区间 SQL 聚合

当前算法实际消费的是：

- `dict[trade_date] -> 当日风险模型切片`

未来重写时，如果直接改成“每次现场拼整段区间矩阵”，虽然功能可能还能做出来，但系统行为和性能模型都会改变。

## 11.2 契约二：风险模型数据必须带 schema

不能只返回数值矩阵，至少还要带：

- style factor 列表
- industry factor 列表

否则算法结果封装层会丢失可解释性。

## 11.3 契约三：风险模型读取需支持证券子集裁剪

当前 `get_exposure` / `get_specific_risk` 支持传 `sec_id_ints`。

这很关键，因为绝大多数分析只需要组合和基准相关证券的子集，而不是全市场暴露矩阵。

## 11.4 契约四：风险模型允许使用“最近可用交易日”回填

这是当前实现里的真实业务行为，不建议在重构中悄悄改掉。

## 11.5 契约五：缓存层是主路径，不是可有可无的优化

股票风险模型主链对 Redis 依赖非常重。

如果未来去掉预热缓存，改成在线查库，系统吞吐和延迟模型都会发生根本变化。

## 12. 代码层面的风险与待确认项

### 12.1 `get_specific_risk` 中存在一个值得复核的分支

在 `/lib/data_loader/brain_redis/risk_model.py` 中，`get_specific_risk` 的 key 选择条件看起来像：

- `model_version != 'cne5'` 时走普通 key
- `model_version == 'cne5'` 时反而走 `cne6` key

从命名语义上看，这很像一个需要复核的条件反转点。

当前我只把它记为“疑似实现风险”，不把它当成已证实结论。

### 12.2 风险模型发布日期与请求日期的对齐规则仍值得补测

源码中已经确认：

- 会在某些场景回退前一交易日

但不同算法是否全部遵循同一口径，还建议后续结合样例任务做一次运行级验证。

## 13. 一句话结论

`brain` 的股票风险模型链路本质上是“底层库 -> Redis 预热缓存 -> 统一日级风险模型字典 -> 归因算法消费”的体系；未来重构时最值得保留的不是某个 Redis key，而是这套日级、带 schema、可裁剪、可回填的风险模型输入契约。
