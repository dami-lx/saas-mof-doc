# Brinson-Core 知识库 MOC

## 定位

`brinson-core` 是未来统一重构代码包中的 Brinson 计算核心雏形，当前定位不是服务，而是纯代码库。

它的职责是：

- 承接 `brain` 当前 `advanced_attribution` 的输入输出契约
- 为未来整合 `mom-robo` 里的报告拼装逻辑提供稳定计算核心
- 以 QA 样例作为 golden baseline，约束 Rust 重构结果

## 推荐阅读顺序

1. [[Brinson-Core-重构蓝图与一致性校验]]
2. [[Brinson-Core-Python链路到Rust映射]]
3. [[Brinson-Core-数据依赖与Provider设计]]
4. [[Brinson-Core-真实环境探测记录-2026-03-28]]
5. [[Brinson-Core-Exporter与旧Pandas兼容方案]]
6. [[Brinson-Core-QA样例与Snapshot基线]]
7. [[Brinson-Core-重构问题日志]]
8. [[Brinson-Core-重构加速与证据优先原则]]
9. [[Brinson-Core-症状到命令到结论速查表]]
10. [[Brinson-Core-新Case接入Checklist模板]]
11. [[Brinson-Core-行业Brinson真实Stage实现进展]]
12. [[../stockBrinsonAttr-全链路拆解]]
13. [[../brain/Brain-任务编排与执行链]]
14. [[../brain/Brain-数据加载层与外部依赖]]

## 当前状态

- 已创建 Rust 工程：`/Users/jiangtao.sheng/Documents/demo/codex-mof/brinson-core`
- 已兼容 `brain` 的 Brinson 请求 DTO
- 已引入规范化哈希、fixture 加载、golden oracle、深度 JSON 对比
- 已纳入两个真实 QA case 作为回归测试
- 已支持文件快照形式的 reference data provider
- 已打通真实 MySQL / Redis 到 snapshot JSON 的 exporter 路线
- 已沉淀可复用 skill：`/Users/jiangtao.sheng/Documents/demo/codex-mof/skills/brinson-refactor-playbook`，用于新会话接力、偏差排查和知识库更新

## 后续重构主线

1. 保留当前 golden 测试集不动
2. 把 `GoldenCaseOracle` 替换为真实 `BrinsonComputationEngine`
3. 为 benchmark、收益率、行业分类、风险模型等引入 provider trait
4. 最终把 `brain` 和 `mom-robo` 对 Brinson 的调用都迁入统一代码包
