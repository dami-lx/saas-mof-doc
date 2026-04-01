---
tags:
  - pms
  - help
  - monitor
  - ops
  - refactor
status: draft
updated: 2026-03-27
---

# PMS_ELITE Help Monitor 模块专题

## 1. 模块定位

这两个模块不是核心业务接口，而是运维和工具接口：

- `help`
- `monitor`

重构时不建议继续与正式业务 API 混在同一个发布面上。

## 2. Monitor 模块

### 2.1 接口

路由：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/api/monitor/urls.py`

接口：

- `GET /monitor/heartbeat`

服务：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/controller/monitor_service.py`

### 2.2 功能

`get_heartbeat()` 会检查：

- 业务 Redis
- 业务 Mongo
- data-sdk default db
- data-sdk portfolio db
- data-sdk cache redis

它最终输出：

- 中间件心跳明细
- 总体状态位

说明：

- 这个接口不是应用级健康检查，而是“依赖级健康检查”。

## 3. Help 模块

### 3.1 接口清单

路由：

- `/Users/jiangtao.sheng/Documents/source/mercury-pms-elite/lib/api/help/urls.py`

接口：

- `GET /help/test`
- `GET /help/celery_test`
- `GET /help/exception`
- `DELETE /help/delete_portfolio`
- `POST /help/mongodb`
- `PUT /help/mongodb`
- `PATCH /help/mongodb`
- `DELETE /help/mongodb`

### 3.2 功能分类

#### 调试类

- `test`
- `celery_test`
- `exception`

#### 数据修复/高危运维类

- `delete_portfolio`
- `mongodb` 的查改删增

## 4. `delete_portfolio` 的真实含义

这个接口不是业务上的“软删除组合”。

它做的是：

- 查询已经软删除的组合
- 对组合数据做硬删除

实际会删除：

- 多张 Mongo 业务表
- 任务参数表
- 持仓缓存 Redis key
- 最终再删除组合主表记录

因此它属于：

- 高风险运维能力

## 5. `mongodb` 接口的真实含义

通过 `HelpService` 可以直接：

- 查询 Mongo 数据
- 插入 Mongo 数据
- 更新 Mongo 数据
- 删除 Mongo 数据

这是一组非常强的后门型运维能力。

虽然有 token 校验，但从系统设计角度：

- 不应与正式业务接口共用同一发布面

## 6. 重构建议

建议未来将 `help` 与 `monitor` 独立为：

### 6.1 Admin API

- 数据修复
- Mongo 运维
- 组合硬删除

### 6.2 Observability API

- heartbeat
- 依赖健康检查

并与正式业务网关隔离。

## 7. 一句话结论

`help` 和 `monitor` 模块更多是运维系统的一部分，而不是业务系统的一部分。
