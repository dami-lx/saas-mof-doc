---
tags:
  - pms
  - transaction
  - api
  - refactor
status: draft
updated: 2026-03-27
---

# PMS_ELITE Transaction 模块专题

## 1. 模块定位

`transaction` 模块对外只暴露了一个查询接口，但内部仍然有完整的交易记录组装逻辑。

它的职责主要有两类：

1. 普通交易记录查询
2. 组合之间持有关系记录查询

## 2. 接口清单

路由：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/api/transaction/urls.py`

视图：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/api/transaction/views.py`

服务：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/transaction_service.py`

核心实现：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/transaction/transaction_composition.py`
- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/transaction/translators.py`

接口：

- `GET /transaction/record`

## 3. `GET /transaction/record`

视图：

- `TransactionView.get`

服务：

- `TransactionService.get_transaction_record`

核心类：

- `PortfolioTransactionComposition`

功能：

- 查询指定组合、时间区间、交易类型、资产类型下的交易记录
- 支持分页

从实现上看，它的处理流程与 `position_composition` 很像，只是对象换成了交易记录：

1. 读取交易数据
2. 计算/整理字段
3. 翻译为 API 输出结构
4. 做分页

## 4. `mom_record`

虽然不是独立接口，但它通过 `portfolio/mom_list` 暴露出来，是一个很重要的隐式能力。

服务：

- `TransactionService.mom_record`

功能：

- 查询组合类证券交易
- 用 `MomData.generate_record(...)` 生成组合间持有关系记录

这说明：

- `transaction` 模块不仅有普通交易查询
- 还承担了“组合持有关系变更记录”的构造

## 5. 核心实现结构

### 5.1 `PortfolioTransactionComposition`

职责：

- 读取交易数据
- 计算指标/字段
- 组织输出结构
- 支持分页

### 5.2 `TransactionRecordTranslator`

职责：

- 把底层交易对象转成 API 输出字段

这也说明 `transaction` 模块同样存在“领域结果”和“展示结果”耦合。

## 6. 重构建议

建议将未来的交易模块拆成：

- `Transaction Query`
- `Transaction Presentation`
- `Holding Relationship Record`

尤其是 `mom_record` 不适合继续混在普通交易查询服务里。

## 7. 一句话结论

`transaction` 模块表面很薄，但它其实承担了“交易记录查询”和“组合间关系记录生成”两种不同职责。
