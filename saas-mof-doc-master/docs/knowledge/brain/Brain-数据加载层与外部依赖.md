---
tags:
  - brain
  - data-loader
  - redis
  - mysql
  - oracle
  - mongo
  - refactor
status: draft
updated: 2026-03-28
---

# Brain 数据加载层与外部依赖

## 1. 数据加载层的地位

`data_loader` 是 `brain` 的基础设施核心之一。

它的作用不是简单“查库”，而是为上层算法单元提供统一的领域数据访问接口。

换句话说：

- `portfolio_management` 更关心“我要什么数据”
- `data_loader` 负责“从哪里取、用什么存储取”

## 2. 目录结构

关键目录：

- `lib/data_loader/brain_redis`
- `lib/data_loader/dy_mysql`
- `lib/data_loader/dy_oracle`
- `lib/data_loader/dy_mongodb`
- `lib/data_loader/dump_to_redis`

以及统一外观模块：

- `stock.py`
- `risk_model.py`
- `benchmark.py`
- `bond.py`
- `fund.py`
- `future.py`
- `security.py`

## 3. 配置层说明

配置解析位于：

- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/utils/cfg.py`

当前可见的底层依赖包括：

- MySQL
- Oracle
- Redis
- Redis bond
- Celery broker/backend
- Mongo

此外还有一些开关：

- `db_type`
- `use_parallel`
- `use_riskmdl_sw21`
- `split_run_mode`

这说明：

- 数据源选择和算法执行方式都不是硬编码，而是配置驱动

## 4. 数据加载的统一外观模式

### 4.1 `stock.py`

位置：

- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/data_loader/stock.py`

特点：

- 统一暴露股票收益、行业、行情、股本等能力
- 股票收益和行业优先来自 `brain_redis`
- 其他补充能力根据 `db_type` 从 MySQL/Oracle 读取

### 4.2 `risk_model.py`

位置：

- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/data_loader/risk_model.py`

特点：

- 股票风险模型数据主要来自 `brain_redis.risk_model`
- 债券风险模型相关能力根据 `db_type` 走 MySQL/Oracle

### 4.3 `benchmark.py`

位置：

- `/Users/jiangtao.sheng/Documents/source/mercury-brain/lib/data_loader/benchmark.py`

特点：

- 基准持仓有 Redis 和 DB 两条来源
- 支持复合基准、展开持仓、自定义拟合指数

## 5. Redis 在 brain 中的角色

从当前代码看，Redis 在 `brain` 中承担至少 4 类角色：

### 5.1 算法数据缓存

例如：

- 股票收益
- 行业分类
- 风险模型暴露
- 因子协方差
- 特质风险

### 5.2 基准持仓缓存

例如：

- benchmark holdings

### 5.3 Celery 任务参数或结果相关缓存

例如：

- `celery_task_args`
- backend redis

### 5.4 数据更新与检查目标

例如：

- `redis_check`
- `dump_to_redis`

这说明 Redis 不只是性能缓存，而是系统运行的重要组成部分。

## 6. MySQL / Oracle 在 brain 中的角色

从目录设计可以看出：

- `dy_mysql`
- `dy_oracle`

两套 loader 基本平行存在。

这说明系统有两个目标：

1. 通过统一接口兼容两类底层数据库
2. 在配置层通过 `db_type` 切换运行环境

从重构角度看，这是一种“存储适配器模式”的雏形。

补充一个这次已通过真实连通性验证的环境事实：

- Datayes MySQL 可以作为当前股票归因链路的稳定基础数据源
- Redis Cluster 可以作为当前股票归因链路的稳定运行时缓存
- `mysql_riskmdl_db` 虽然在配置层存在，但对股票归因运行时主链并不是首要直接依赖

## 7. Mongo 在 brain 中的角色

虽然 `brain` 的主算法数据很多来自 Redis 和 DB，但 `cfg.py` 也明确引入了 Mongo 配置。

此外任务入参查询还存在：

- `/api/task_args_mongo/<task_id>`

这说明 Mongo 在 `brain` 里更偏：

- 任务入参与运行辅助数据存储

而不是主分析数据源。

## 8. 对算法层最关键的数据清单

以新版股票归因为例，上层最依赖的数据包括：

- benchmark holdings
- exposure
- factor covariance
- specific risk
- stock return
- factor return
- stock industry

这些数据在并行归因子任务中被明确加载，说明它们就是实际算法输入契约。

## 9. 典型的数据来源组合

### 9.1 股票归因

- Redis 风险模型
- Redis 股票收益
- Redis 行业分类
- Redis/DB benchmark
- Datayes MySQL 基础映射与交易日

补充说明：

- benchmark 的业务 id 需要通过 `IDX_MAPPING_MOM.SECURITY_ID` 语义来解释
- 不能误当作 `IDX_MAPPING_MOM.ID`
- 当前 Redis 是 cluster，需要 cluster-aware 读取

### 9.2 债券分析

- MySQL/Oracle 债券风险模型
- 债券估值和类型数据

### 9.3 市场与证券基础信息

- MySQL/Oracle security / stock / fund / factor

## 10. 重构建议

建议未来将 `data_loader` 正式抽象成统一的数据访问层，按以下方式组织：

### 10.1 Domain Loader Interface

- StockLoader
- RiskModelLoader
- BenchmarkLoader
- BondLoader

### 10.2 Source Adapter

- Redis adapter
- MySQL adapter
- Oracle adapter
- Mongo adapter

### 10.3 Cache / Dump Tooling

- redis dump
- redis check

## 11. 一句话结论

`data_loader` 是 `brain` 的数据访问骨架层，未来重构时应优先保住它对上层算法暴露出的“领域数据契约”，而不是拘泥于当前底层存储细节。
