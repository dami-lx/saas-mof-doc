# Brinson-Core 新 Case 接入 Checklist 模板

## 用途

这份模板用于接入新的 Brinson QA case，目标是：

- 尽快形成稳定 baseline
- 尽快知道问题在哪一层
- 尽量避免因为素材不齐或验证顺序混乱而绕路

建议每接入一个新 case，就按这份模板补齐一次。

## 0. Case 基本信息

- case 名称：
- 请求来源环境：
- 对应接口：
- 请求时间：
- 当前负责人：
- 当前状态：
  - 未开始 / 已采集 / 已回放 / 已完成 compare / 已进入修复

## 1. 基线产物是否齐全

### 必备文件

- [ ] request JSON
- [ ] QA final result JSON
- [ ] QA raw task JSON
- [ ] snapshot JSON
- [ ] Rust runtime output JSON
- [ ] parity report 或等效对比结果

### 按需补充

- [ ] Rust period replay output
- [ ] Python period replay output
- [ ] metadata 说明文件

### 文件路径

- request:
- QA result:
- raw task:
- snapshot:
- runtime output:
- parity report:
- rust period replay:
- python period replay:

## 2. 先做完整 compare，不要先看 summary

建议先执行：

```bash
python3 brain-brinson-test/compare_outputs.py \
  <baseline-result.json> \
  <runtime-output.json>
```

记录：

- compare 结果：
  - `COMPARE_OK` / `COMPARE_FAILED`
- 如果失败，首批 diff 是什么：
- 是否已经做过排序 / keyed compare：

## 3. 先归类到哪一层

### A. request / loader

- [ ] beginDate 已确认
- [ ] endDate 已确认
- [ ] preBeginDate 已确认
- [ ] 首个 position date 已确认
- [ ] 是否存在 pre-begin position 已确认
- [ ] observation count 已确认

如果这里有疑点，先不要改算法。

### B. reference data

- [ ] security universe 已确认
- [ ] benchmark-only securities 是否保留已确认
- [ ] factor exposures 已确认
- [ ] specific risks 已确认
- [ ] security industries 已确认
- [ ] covariance / returns 已确认

如果这里有疑点，先不要改 packing。

### C. period algorithm

- [ ] Rust period replay 已生成
- [ ] Python period replay 已生成
- [ ] period count 已比较
- [ ] period sums 已比较

如果这里已经对齐，停止改主链算法。

### D. packing / compatibility

- [ ] top-level 模块差异已拆开
- [ ] 大表是否只是缺行已判断
- [ ] deviation 是否是唯一剩余差异已判断
- [ ] compatibility profile 是否已切换测试

## 4. 假设与证据记录

每次只写一条当前最强假设：

- 假设：
- 为什么合理：
- 用什么证据验证：
- 当前结论：
  - 支持 / 证伪 / 未决
- 下一步最窄动作：

示例：

- 假设：
  - 首日缺行来自 packing 补位差异
- 为什么合理：
  - 交集行已全对，只差同一天的一整批零值行
- 用什么证据验证：
  - keyed compare + 首日 row inspection
- 当前结论：
  - 支持
- 下一步最窄动作：
  - 在 packing 层补正式起始日零截面，不动 period math

## 5. 最小验证闭环

每改完一轮，至少做这四步：

1. 重新生成 runtime output
2. 重新跑完整 compare
3. 必要时重跑 parity report
4. 更新剩余偏差记录

不要只看“感觉接近了”。

## 6. 当前状态记录

- best profile:
- 当前剩余差异：
- 当前确认已对齐的 top-level 模块：
- 当前仍未解释的点：

## 7. 完成标准

### 完全完成

- [ ] 完整 compare `COMPARE_OK`

### 可接受完成

- [ ] 主链结果完全对齐
- [ ] 剩余差异已明确归因到 compatibility / service surface
- [ ] 剩余偏差量级已记录
- [ ] 已有 profile 或后续计划承接

## 8. 收尾动作

- [ ] 更新 `Brinson-Core-QA样例与Snapshot基线`
- [ ] 更新 `Brinson-Core-重构问题日志`
- [ ] 如果方法论有变化，更新 skill 或其 references
- [ ] 如果这是长期基线，加入 parity report 体系

## 9. 推荐阅读顺序

接入新 case 时，推荐先读：

1. `Brinson-Core-知识库-MOC`
2. `Brinson-Core-QA样例与Snapshot基线`
3. `Brinson-Core-重构加速与证据优先原则`
4. `Brinson-Core-症状到命令到结论速查表`

这四份一起用，效率最高。
