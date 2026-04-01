# Brinson-Core 重构加速与证据优先原则

## 目的

这份文档不是解释 Brinson 公式本身，而是把“如何更快、更少走弯路地完成重构和数值核对”固化成方法。

它回答四类问题：

1. 为什么之前会反复绕路
2. 每一层到底该看什么
3. 开始动代码前必须准备哪些证据
4. 什么情况下应该停止改算法，转去改 compatibility / packing

## 1. 为什么会走弯路

这类重构最容易犯的错，不是不会写代码，而是把不同层的问题混在一起。

最典型的错误链路是：

1. 先看到 summary 有偏差
2. 直接怀疑公式
3. 修改 period math
4. 过几轮后才发现真正的问题是：
   - 请求作用域不一致
   - snapshot 覆盖不完整
   - exporter 丢了 benchmark-only rows
   - service output 有额外 packing 语义

如果不先固定“问题所在层”和“这一层的证据来源”，就很容易在正确方向附近来回试错。

## 2. 分层核对矩阵

### 2.1 request / loader 层

目标问题：

- 哪些 position date 真正进入了链路
- `beginDate`、`preBeginDate`、首个持仓日分别是什么
- benchmark 组合和持仓范围是否被正确传进来

最强证据：

- request JSON
- request compile / normalize 路径
- 实际参与计算的持仓日期序列

该层优先使用：

- request 文件
- `CompiledBrinsonRequest` / normalize 相关代码
- 对比首个 position date、`beginDate`、`preBeginDate`

不要用这些来直接下结论：

- 顶层 summary 是否接近
- 单个 deviation 字段

如果这一层出问题，常见表现是：

- 第一段 period 缺失
- observation count 不对
- `preBeginDate` 看起来存在，但实际没进主链

### 2.2 reference data 层

目标问题：

- Rust 和 baseline 是否使用了相同的证券集合、收益、行业、factor exposure、covariance、specific risk

最强证据：

- snapshot JSON
- exporter 逻辑
- keyed row compare

该层优先使用：

- snapshot inspection
- exporter 代码追踪
- 缺失 key / 长度 / universe 比较

不要用这些来直接下结论：

- “数据库应该已经查出来了”
- period 结果差一点点，所以数据应该差不多

如果这一层出问题，常见表现是：

- 行业主链看起来正常，但 style / risk 大幅漂移
- benchmark-only securities 被静默丢掉
- factor exposure / specific risk 行数偏少

### 2.3 period algorithm 层

目标问题：

- Rust 与 Python 是否真的在逐期贡献值上不一致

最强证据：

- period-level replay
- period count
- 逐期 sum compare

该层优先使用：

- `cargo run --example diagnose_periods -- ...`
- `python3 tools/replay_python_brinson_periods.py -- ...`

不要用这些来直接下结论：

- 只看 final report
- 只看 packed summary

如果这一层出问题，常见表现是：

- `sector_allocation / equity_selection / interaction` 在 period 级已经分叉
- Rust/Python period count 不一致

### 2.4 packing / compatibility 层

目标问题：

- 主链是不是已经对了，只是服务出参表面还不一样

最强证据：

- 完整 JSON compare
- top-level 模块 compare
- 大表 keyed compare

该层优先使用：

- `python3 brain-brinson-test/compare_outputs.py ...`
- `python3 tools/generate_brinson_parity_report.py --refresh`
- 对大表先排序或 keyed compare，再比较数值

不要用这些来直接下结论：

- 只看 5 个 summary 字段
- 只看一张表局部样本

如果这一层出问题，常见表现是：

- period 值已经一致
- 主 summary 已一致
- 只剩 deviation 或某些服务端辅助表不一致

## 3. 为什么“完整 compare 自动化”比“summary compare”更重要

因为 summary compare 只能告诉你“这里不一样”，不能告诉你“不一样到底发生在哪一层”。

完整 compare 的价值在于：

1. 可以迅速判断偏差是不是只集中在一个 top-level 模块
2. 可以发现“交集已全对，只是缺一批行”这种现象
3. 可以把问题从“数值为什么不一样”缩到“哪一类 row 根本没生成出来”

这次 case2 的 `style_factor_return_ts` 就是典型例子：

- 一开始只看 summary，只会得到“case2 还没全对”
- 完整 compare 后才看到：
  - 交集已经全对
  - 只差首日 `48` 条零值行

这会直接决定修复应该放在 packing 层，而不是 algorithm 层。

## 4. 基线产物清单

每个真实 case 在开始重构前，至少要齐这几样：

1. request JSON
2. QA final result JSON
3. QA raw task JSON
4. snapshot JSON
5. Rust runtime output JSON
6. parity report
7. Rust period replay output
8. Python period replay output
9. 简短 metadata：
   - best profile
   - 当前剩余偏差
   - 已知 caveat

这些东西缺一项，并不一定意味着任务做不了，但意味着你要明确知道“此处证据不完整”。

很多绕路，本质上都是拿不同层的产物在互相比，却没有意识到它们不是同一层证据。

## 5. 为什么要把“假设”和“证据”成对记录

因为大部分错误方向都不是明显荒谬，而是“很像对的”。

比如：

- `preBeginDate` 看起来非常可疑
- benchmark-only securities 的问题也看起来很像真因
- style/risk exporter coverage 看起来也足够合理

如果只记“想到过什么”，不记“用什么证据把它证实/证伪”，后面就会反复回到同一个假设。

推荐模板：

- 假设：
  - 一句话
- 为什么看起来合理：
  - 1-2 个现象
- 用什么证据验证：
  - 精确到命令 / 文件 / compare 方法
- 结论：
  - 支持 / 证伪 / 未决
- 下一步：
  - 只做最窄的一步

这个模板的意义，不是写得漂亮，而是防止“猜测”在团队协作里慢慢变成“默认真相”。

## 6. 为什么要把 compatibility 单独看成一层

很多人第一次遇到这种问题，会天然把“结果不完全一致”理解成“算法没写对”。

但实际上，服务出参有一整层可能属于：

- 历史统计口径
- 打包顺序
- 零值补位
- summary 字段定义
- sample / population 等统计模式差异

当下面这些条件同时成立时，就应该优先怀疑 compatibility，而不是算法：

1. period count 一致
2. period sums 一致
3. 主 summary 一致
4. 剩余差异只在少量服务表面字段

case2 最后就是这样收口的：

- 行业主链已经一致
- `style_factor_return_ts` 经过 packing 兼容后也一致
- 最后只剩 3 个 deviation 字段有极小残差

这时继续去扭 period math，收益很低，风险很高。

## 7. 这几条原则到底能帮我们做什么

### 7.1 减少无效代码改动

先确定层，再改代码，会让很多“看起来努力、实际上在错误层操作”的改动直接消失。

### 7.2 更快定位真正证据

不是所有文件都同样重要。

有了分层矩阵后，遇到问题时可以直接问：

- 我现在缺的是 request 证据，还是 snapshot 证据，还是 period replay 证据？

### 7.3 更好交接

后续不管是继续做 Brinson，还是扩展到 `mom-robo`，都可以复用这套方法，而不是重新经历一遍“先怀疑算法，再逐渐发现是输出层”的过程。

## 8. 最小可执行工作流

拿到一个新 case 时，优先按这个顺序做：

1. 冻结基线产物
2. 先做完整 compare，而不是只看 summary
3. 把偏差归类到四层之一
4. 写一条假设/证据记录
5. 只改那一层最窄的实现
6. 重新生成 output
7. 再跑完整 compare
8. 更新知识库和 skill

这套工作流的本质是：

- 让“证据”比“直觉”更早进入决策

这就是它能显著减少弯路的原因。
