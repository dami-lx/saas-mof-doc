#!/bin/bash
# 知识库项目初始化脚本
# 用于初始化所有源代码子模块

set -e

echo "=========================================="
echo "  SaaS-MOF 知识库初始化"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查是否在 git 仓库中
if [ ! -d ".git" ]; then
    echo -e "${RED}错误: 请在 saas-mof-doc 根目录运行此脚本${NC}"
    exit 1
fi

# 子模块配置
declare -A SUBMODULES=(
    ["brain"]="sources/brain"
    ["earth"]="sources/earth"
    ["jupiter"]="sources/jupiter"
    ["mars"]="sources/mars"
    ["mof-web-fe"]="sources/mof-web-fe"
    ["mom"]="sources/mom"
    ["neptune"]="sources/neptune"
    ["pms"]="sources/pms"
    ["solar"]="sources/solar"
)

# 解析参数
INIT_ALL=true
SELECTED_MODULES=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "用法: $0 [选项] [模块名...]"
            echo ""
            echo "选项:"
            echo "  -h, --help    显示帮助信息"
            echo ""
            echo "可用模块:"
            for module in "${!SUBMODULES[@]}"; do
                echo "  - $module"
            done
            echo ""
            echo "示例:"
            echo "  $0                  # 初始化所有模块"
            echo "  $0 brain pms        # 只初始化 brain 和 pms"
            exit 0
            ;;
        *)
            SELECTED_MODULES+=("$1")
            INIT_ALL=false
            shift
            ;;
    esac
done

echo ""

# 初始化函数
init_submodules() {
    if [ "$INIT_ALL" = true ]; then
        echo "初始化所有子模块..."
        git submodule update --init --recursive
    else
        echo "初始化指定模块: ${SELECTED_MODULES[*]}"
        for module in "${SELECTED_MODULES[@]}"; do
            path=${SUBMODULES[$module]}
            if [ -n "$path" ]; then
                echo -e "${GREEN}[初始化] $module${NC}"
                git submodule update --init "$path"
            else
                echo -e "${RED}[错误] 未知模块: $module${NC}"
            fi
        done
    fi
}

init_submodules

echo ""
echo "=========================================="
echo -e "${GREEN}初始化完成!${NC}"
echo "=========================================="
echo ""
echo "项目结构:"
ls -la sources/ 2>/dev/null | grep "^d" | awk '{print "  " $NF}' | grep -v "^\.$" | grep -v "^\.\.$"
echo ""
echo "文档目录:"
ls docs/knowledge/ 2>/dev/null | while read dir; do
    echo "  $dir"
done
echo ""
echo "后续操作:"
echo "  - 更新子模块: git submodule update --remote"
echo "  - 查看状态: git submodule status"
echo "  - 打开文档: 使用 Obsidian 打开 docs/ 目录"