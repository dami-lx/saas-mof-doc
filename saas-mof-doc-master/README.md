# SaaS-MOF 知识库

投资管理系统知识库项目，包含源代码和文档，用于 AI 辅助问答和文档生成。

## 项目结构

```
saas-mof-doc/
├── docs/                    # 知识文档 (Obsidian)
│   └── knowledge/
│       ├── brain/          # Brain 系统文档
│       ├── brinson-core/   # Brinson 归因文档
│       ├── pms-elite/      # PMS Elite 文档
│       └── ...
├── sources/                 # 源代码子模块
│   ├── brain/              # mercury-brain
│   ├── earth/              # earth
│   ├── jupiter/            # jupiter
│   ├── mars/               # mars
│   ├── mof-web-fe/         # 前端代码
│   ├── mom/                # mom-robo
│   ├── neptune/            # neptune
│   ├── pms/                # mercury-pms-elite
│   └── solar/              # solar
├── tools/                   # 工具脚本
├── skills/                  # Claude skills
└── init.sh                 # 初始化脚本
```

## 快速开始

### 方式一：一键初始化

```bash
git clone --recurse-submodules http://10.21.234.121/invest-platform/saas-mof-doc.git
```

### 方式二：分步初始化

```bash
git clone http://10.21.234.121/invest-platform/saas-mof-doc.git
cd saas-mof-doc
./init.sh
```

### 方式三：选择性拉取

```bash
git clone http://10.21.234.121/invest-platform/saas-mof-doc.git
cd saas-mof-doc

# 只初始化需要的模块
git submodule update --init sources/brain sources/pms
```

## 子模块仓库

| 目录 | 仓库地址 | 默认分支 |
|------|----------|----------|
| sources/brain | http://git.datayes.com/invest-brain/mercury-brain | aladdin-0.0.x |
| sources/earth | http://git.datayes.com/invest-brain/earth | 1.1.x |
| sources/jupiter | http://git.datayes.com/invest-brain/jupiter | 1.1.x |
| sources/mars | http://git.datayes.com/invest-brain/mars | 1.1.x |
| sources/mof-web-fe | http://git.datayes.com/aladdin/mof-web-fe | 1.0.x |
| sources/mom | http://git.datayes.com/invest-platform/mom-robo | aladdin-0.2.x |
| sources/neptune | http://git.datayes.com/invest-brain/neptune | 1.1.x |
| sources/pms | http://git.datayes.com/mercury/mercury-pms-elite | master |
| sources/solar | http://git.datayes.com/invest-brain/solar | 1.1.x |

## 常用操作

### 更新子模块

```bash
# 更新所有子模块到最新
git submodule update --remote

# 更新单个子模块
cd sources/brain && git pull origin master
```

### 切换子模块分支

```bash
cd sources/brain
git checkout release/2025Q1
cd ../..
git add .gitmodules sources/brain
git commit -m "chore: 切换 brain 到 release 分支"
```

### 查看状态

```bash
git submodule status
```

## 知识库使用

文档存放在 `docs/knowledge/` 目录，使用 Obsidian 打开 `docs/` 目录即可。

### 文档结构

- `brain/` - Brain 系统接口文档
- `brinson-core/` - Brinson 归因分析文档
- `pms-elite/` - PMS Elite 系统文档
- `mof-web-fe/` - 前端模块文档
- `mom-robo/` - MOM 系统文档

## 维护指南

详见 [SUBMODULE_GUIDE.md](./SUBMODULE_GUIDE.md)