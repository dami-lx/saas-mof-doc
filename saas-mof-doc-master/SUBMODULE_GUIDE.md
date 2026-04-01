# 知识库项目维护指南

## 项目结构

```
saas-mof-doc/
├── docs/                    # 文档 (Obsidian 知识库)
│   └── knowledge/          # 知识文档
├── sources/                 # 源代码子模块
│   ├── brain/              # mercury-brain
│   ├── earth/              # earth
│   └── ...                 # 其他项目
├── tools/                   # 工具脚本
├── skills/                  # Claude skills
├── .gitmodules             # 子模块配置
└── init.sh                 # 初始化脚本
```

## 用户使用方式

### 方式一：一键初始化（推荐）

```bash
# Clone 并自动初始化所有子模块
git clone --recurse-submodules http://10.21.234.121/invest-platform/saas-mof-doc.git

# 或者 clone 后再初始化
git clone http://10.21.234.121/invest-platform/saas-mof-doc.git
cd saas-mof-doc
./init.sh
```

### 方式二：选择性拉取

```bash
git clone http://10.21.234.121/invest-platform/saas-mof-doc.git
cd saas-mof-doc

# 只初始化需要的子模块
git submodule update --init sources/brain sources/pms
```

## 维护操作

### 添加新子模块

```bash
# 添加子模块到指定分支
git submodule add -b master http://git.datayes.com/invest-brain/mercury-brain sources/brain

# 添加到特定 tag
git submodule add http://git.datayes.com/invest-brain/mercury-brain sources/brain
cd sources/brain
git checkout v1.0.0
```

### 更新子模块到最新版本

```bash
# 更新单个子模块
cd sources/brain
git pull origin master

# 更新所有子模块
git submodule update --remote
```

### 切换子模块分支/标签

```bash
cd sources/brain
git checkout release/2025Q1
cd ../..
git add sources/brain
git commit -m "chore: 切换 brain 到 release/2025Q1 分支"
```

### 查看子模块状态

```bash
git submodule status
```

## 子模块仓库地址

| 目录 | 仓库地址 | 分支 |
|------|----------|------|
| sources/brain | http://git.datayes.com/invest-brain/mercury-brain | aladdin-0.0.x |
| sources/earth | http://git.datayes.com/invest-brain/earth | 1.1.x |
| sources/jupiter | http://git.datayes.com/invest-brain/jupiter | 1.1.x |
| sources/mars | http://git.datayes.com/invest-brain/mars | 1.1.x |
| sources/mof-web-fe | http://git.datayes.com/aladdin/mof-web-fe | 1.0.x |
| sources/mom | http://git.datayes.com/invest-platform/mom-robo | aladdin-0.2.x |
| sources/neptune | http://git.datayes.com/invest-brain/neptune | 1.1.x |
| sources/pms | http://git.datayes.com/mercury/mercury-pms-elite | master |
| sources/solar | http://git.datayes.com/invest-brain/solar | 1.1.x |

## 注意事项

1. **子模块是只读引用**：用户在 sources/ 下修改不会影响原仓库
2. **锁定版本**：子模块指向特定 commit，确保团队成员使用相同版本
3. **分支切换**：需要先提交主仓库变更才能切换子模块分支