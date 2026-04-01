# Brinson-Core 症状到命令到结论速查表

## 用途

这份文档用于在遇到 Brinson 重构或 parity 偏差时，快速把：

- 症状
- 最优先命令
- 可能结论

串成一条最短工作路径。

它不是完整原理文档，而是“先跑什么，跑完怎么判断”的速查表。

## 使用原则

1. 先做完整 compare，再判断层级
2. 一次只验证一个假设
3. 先看最强证据，不要同时追多条线
4. 如果 period 已对，不要先改算法

## 1. 症状：只看到 summary 有偏差，但还不知道差在哪

先跑：

```bash
python3 brain-brinson-test/compare_outputs.py \
  brain-brinson-test/output/case1-result.json \
  brain-brinson-test/output/case1-compute-snapshot-core-exact.json
```

如果是 case2：

```bash
python3 brain-brinson-test/compare_outputs.py \
  brain-brinson-test/output/case2-result.json \
  brain-brinson-test/output/case2-compute-snapshot-brain-qa-compatible.json
```

优先结论：

- 如果直接 `COMPARE_OK`，说明完整结果已经对齐
- 如果只报少量 summary 字段，优先看 packing / compatibility
- 如果报表格长度差，优先看 exporter 或 packing 补位逻辑

## 2. 症状：period 级别可能不一致

先跑 Rust period 回放：

```bash
cargo run --example diagnose_periods -- \
  --request ../brain-brinson-test/a-brinson-request2.json \
  --snapshot ../brain-brinson-test/output/case2-snapshot-with-style-ids-v2.json \
  --output ../brain-brinson-test/output/case2-rust-period-sums.json
```

再跑 Python period 回放：

```bash
python3 tools/replay_python_brinson_periods.py \
  --request brain-brinson-test/a-brinson-request2.json \
  --snapshot brain-brinson-test/output/case2-snapshot-with-style-ids-v2.json \
  --output brain-brinson-test/output/case2-python-period-sums.json
```

优先结论：

- 如果 period count 不一致，先看 request / loader
- 如果 period count 一致但逐期值不一致，先看 reference data
- 如果 period sums 已对齐，停止改核心公式，转去看 packing / compatibility

## 3. 症状：行业 Brinson 基本对了，但 style / risk 漂得很明显

先看：

- snapshot 中 factor exposure / specific risk / industry rows 是否完整
- 是否遗漏 benchmark-only securities

优先检查代码：

- `brinson-core/src/engine/snapshot.rs`
- exporter 相关脚本
- `brinson-core/src/engine/stages.rs`

优先结论：

- 如果行业对、style/risk 不对，更像 reference-data coverage 问题
- 不要先怀疑行业 period 算法

## 4. 症状：只有 deviation 字段还在漂

先看 parity 报告：

```bash
python3 tools/generate_brinson_parity_report.py --refresh
```

然后对比：

- `core-exact`
- `brain-qa-compatible`

优先结论：

- 如果主 summary 已对，只剩 deviation 不同，优先看 compatibility profile
- case2 这类情况通常不是主链算法错误

## 5. 症状：`preBeginDate` 看起来很可疑

不要直接改代码，先验证：

- request 里有没有 `preBeginDate`
- 编译后的 request 首个持仓日是不是已经等于 pre-begin
- 真实 advanced holding attribution 路径里它是否真的进入了有效 period 链

优先看：

- `brinson-core/src/domain/compiled.rs`
- `brinson-core/src/domain/normalized.rs`
- `brain` / `mars` 对应 loader 路径

优先结论：

- `preBeginDate` 只是“可疑项”，不是默认真因
- 没有代码证据前，不要把它当修复方向

## 6. 症状：完整 compare 只差一批整行，不是值漂

优先动作：

- 先做 keyed compare
- 看缺的是哪一天、哪一类因子、是不是整批零值行

优先结论：

- 这更像 packing / output 语义问题
- 不是 period algorithm 问题

本项目中的真实例子：

- case2 的 `style_factor_return_ts`
- 最后发现是正式起始日需要补一整张零值截面

## 7. 症状：case1 和 case2 结论看起来互相冲突

优先动作：

- 不要强行用一个 case 的结论解释另一个 case
- 先看：
  - position 日期结构
  - observation count
  - best profile
  - 是否存在 pre-begin position

优先结论：

- case 差异本身就是信息
- “同一套规则解释所有 case” 在这个项目里通常不成立

## 8. 症状：不知道下一步先读代码还是先看文档

默认顺序：

1. 看 `Brinson-Core-知识库-MOC`
2. 看 `Brinson-Core-QA样例与Snapshot基线`
3. 跑完整 compare
4. 再决定进哪一层代码

优先结论：

- 文档负责缩小搜索范围
- 代码和产物负责最终证明
- 两者不是替代关系，而是先导航、后取证

## 9. 收尾时最低限度要留下什么

至少留下这四样：

1. 可复现命令
2. 当前剩余偏差
3. 归因到哪一层
4. 更新到知识库的结论

如果没有这四样，下一次接手大概率还会重复走路。
