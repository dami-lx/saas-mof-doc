---
tags:
  - invested
  - ams
  - import
  - delivery
  - knowledge-base
status: active
updated: 2026-03-31
---

# 投后与 AMS Pro 数据导入专题

## 1. 这个专题关注什么

这篇文档只看导入链路，包括：

- 持仓导入
- 交易导入
- 净值导入
- 导入历史
- 手工录入 / 文本录入

它不讨论监控页和报告页。

## 2. 前端页面入口

路由定义：

- `mof-web-fe/js/v2/pages/Portfolio/upload2/router.tsx`

关键页面：

- `/portfolio/manage/position-upload/:id?`
- `/portfolio/manage/trade-upload/:id?`
- `/portfolio/manage/net-value-upload/:id?`
- `/portfolio/manage/file-parse-log/:id?`
- `/portfolio/manage/historyposition/:id?`
- `/portfolio/manage/adjust-position/:id?`
- `/portfolio/manage/today-position/:id?`
- `/portfolio/manage/record/:id?`
- `/portfolio/manage/fund-dividend/:id?`

投后旧页面中也有平行实现：

- `mof-web-fe/js/pages/production/import/*`

## 3. 前端 API 入口

### 3.1 持仓导入

关键文件：

- `mof-web-fe/js/v2/pages/Portfolio/upload2/containers/position-upload/service.ts`
- `mof-web-fe/js/v2/pages/Portfolio/historyposition/services.ts`

已确认接口：

- `PUT ${mof_api}/pmsLite/portfolio/position/upload/v2?portfolioId={id}&deliveryMode={deliveryMode}`
- `GET ${mof_api}/pmsLite/portfolio/position/check/v2?...`
- `GET ${mof_api}/pmsLite/portfolio/position/upload/status/v2?portfolioId={id}&taskId={taskId}`

### 3.2 交易导入

关键文件：

- `mof-web-fe/js/v2/pages/Portfolio/upload2/containers/trade/service.ts`

已确认接口：

- `POST ${mof_api}/api/transaction/delivery?portfolio_id={id}&upsert=true&deliveryMode={deliveryMode}`
- `GET ${mof_api}/pmsLite/portfolio/trade/upload/status/v2?portfolioId={id}&taskId={taskId}`

### 3.3 净值导入

关键文件：

- `mof-web-fe/js/v2/pages/Portfolio/upload2/containers/net-value/components/single-import/service.ts`
- `mof-web-fe/js/v2/pages/Portfolio/upload2/containers/net-value/components/upload-in-page/service.ts`
- `mof-web-fe/js/v2/pages/Portfolio/upload2/containers/net-value/components/multi-import/service.tsx`

已确认接口：

- `POST ${mof_api}/pmsLite/portfolio/delivery/checkUploadNav`
- `POST ${mof_api}/pmsLite/portfolio/delivery/uploadNav`
- `POST ${mof_api}/pmsLite/portfolio/delivery/uploadTextNav`
- `POST ${parser_api}/pmsLite/portfolio/delivery/multiNav/upload`
- `POST ${parser_api}/pmsLite/portfolio/delivery/multiNav/check`

### 3.4 导入历史

关键文件：

- `mof-web-fe/js/v2/pages/Portfolio/upload2/containers/history/Base/service.ts`
- `mof-web-fe/js/v2/pages/Portfolio/upload2/containers/history/components/detail/service.ts`

已确认接口：

- `GET ${mof_api}/pmsLite/portfolio/delivery/history`
- `GET ${mof_api}/pmsLite/portfolio/delivery/history/date`
- `GET ${mof_api}/pmsLite/portfolio/delivery/history/detail?taskId={taskId}`

## 4. 后端入口

主 controller：

- `mom/mom-web/src/main/java/com/datayes/web/ams/controller/PortfolioController.java`

已确认导入相关接口：

- `POST /pmsLite/portfolio/position/check/{id}`
- `PUT /pmsLite/portfolio/position/upload/{id}`
- `GET /pmsLite/portfolio/position/upload/status/{id}`
- `POST /pmsLite/portfolio/trade/check/{id}`
- `PUT /pmsLite/portfolio/trade/upload/{id}`
- `GET /pmsLite/portfolio/trade/upload/status/{id}`

V2 接口：

- `POST /pmsLite/portfolio/trade/check/v2`
- `POST /pmsLite/portfolio/position/check/v2`
- `PUT /pmsLite/portfolio/trade/upload/v2`
- `PUT /pmsLite/portfolio/position/upload/v2`
- `GET /pmsLite/portfolio/trade/upload/status/v2`
- `GET /pmsLite/portfolio/position/upload/status/v2`
- `GET /pmsLite/portfolio/delivery/history/date`
- `GET /pmsLite/portfolio/delivery/history`
- `GET /pmsLite/portfolio/delivery/history/detail`
- `POST /pmsLite/portfolio/delivery/checkUploadNav`
- `POST /pmsLite/portfolio/delivery/uploadNav`
- `POST /pmsLite/portfolio/delivery/uploadTextNav`

## 5. 链路结构

这条链路明显是“解析 -> 校验 -> 入库 / 交付 -> 异步状态查询”的任务流。

可抽象成统一模式：

1. 上传文件或文本
2. `check` 接口返回结构化 `delivery_data`
3. 前端二次确认或编辑
4. `upload` 接口真正提交
5. 通过 `taskId` 轮询状态
6. 在导入历史页回看结果

## 6. 数据来源与外部依赖

### 6.1 `pmsLite`

这是导入落库的主目的地，负责：

- 持仓
- 交易
- 净值
- 交付历史

### 6.2 `parser_api`

净值批量导入已明确走 `parser_api`，说明：

- 文件解析并不完全发生在 `mom`
- 有专门的解析服务参与

### 6.3 `mom`

`mom` 主要承担：

- 鉴权
- 前端协议适配
- 与 `pmsLite` 的聚合封装

## 7. 公式与口径

这条链路的核心不在数值公式，而在导入口径：

- `deliveryMode`
  - 增量 / 替换 / 全量 / 清空全量等
- `taskType`
  - `delivery_trades`
  - `delivery_positions`
  - `delivery_capital`
- 净值文本录入与文件导入的兼容格式

这些口径未来必须整理成枚举和验证规则，而不能散落在页面里。

## 8. 重构时必须保留的契约

- `check -> upload -> status -> history` 四段式协议必须保留。
- 不能把 V1/V2 接口差异直接抹平，需要先做兼容清单。
- `parser_api` 参与的文件解析链不能漏掉。
- 导入历史页依赖 `taskId` 与 `taskType`，这是稳定查询主键的一部分。

## 9. 后续建议

- 单独补一张“导入类型 -> check 接口 -> upload 接口 -> 状态接口”的矩阵表。
- 继续下钻 `portfolioService.check* / upload*` 到具体 DAO / 远程调用层。
