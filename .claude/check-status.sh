#!/bin/bash
# 检查同步配置状态

cd "$(dirname "$0")/.." || exit 1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     /minimal 自动同步状态检查        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
echo ""

# 检查 Git 仓库
echo -e "${BLUE}[Git 仓库]${NC}"
if [ -d ".git" ]; then
    echo -e "${GREEN}✓${NC} 已初始化"
else
    echo -e "${RED}✗${NC} 未初始化"
fi

# 检查 Git 用户信息
echo ""
echo -e "${BLUE}[Git 用户信息]${NC}"
GIT_NAME=$(git config user.name)
GIT_EMAIL=$(git config user.email)
if [ "$GIT_NAME" = "fies09" ] && [ "$GIT_EMAIL" = "fanyong109@163.com" ]; then
    echo -e "${GREEN}✓${NC} 用户名: $GIT_NAME"
    echo -e "${GREEN}✓${NC} 邮箱: $GIT_EMAIL"
else
    echo -e "${YELLOW}!${NC} 用户名: ${GIT_NAME:-未设置}"
    echo -e "${YELLOW}!${NC} 邮箱: ${GIT_EMAIL:-未设置}"
fi

# 检查远程仓库
echo ""
echo -e "${BLUE}[远程仓库配置]${NC}"
if git remote | grep -q "github"; then
    GITHUB_URL=$(git remote get-url github 2>/dev/null)
    echo -e "${GREEN}✓${NC} GitHub: $GITHUB_URL"
else
    echo -e "${RED}✗${NC} GitHub: 未配置"
fi

if git remote | grep -q "gitee"; then
    GITEE_URL=$(git remote get-url gitee 2>/dev/null)
    echo -e "${GREEN}✓${NC} Gitee: $GITEE_URL"
else
    echo -e "${RED}✗${NC} Gitee: 未配置"
fi

# 检查 Token
echo ""
echo -e "${BLUE}[API Token]${NC}"
if [ -n "$GITHUB_TOKEN" ]; then
    echo -e "${GREEN}✓${NC} GITHUB_TOKEN 已设置"
else
    echo -e "${RED}✗${NC} GITHUB_TOKEN 未设置"
fi

if [ -n "$GITEE_TOKEN" ]; then
    echo -e "${GREEN}✓${NC} GITEE_TOKEN 已设置"
else
    echo -e "${RED}✗${NC} GITEE_TOKEN 未设置"
fi

# 检查手动同步脚本
echo ""
echo -e "${BLUE}[同步脚本]${NC}"
if [ -f ".claude/sync.sh" ]; then
    echo -e "${GREEN}✓${NC} sync.sh 已就绪（手动执行：bash .claude/sync.sh）"
else
    echo -e "${RED}✗${NC} sync.sh 不存在"
fi

# 检查连接
echo ""
echo -e "${BLUE}[连接测试]${NC}"
if ssh -T git@github.com -o ConnectTimeout=5 2>&1 | grep -q "successfully\|fies09"; then
    echo -e "${GREEN}✓${NC} GitHub SSH 连接正常"
else
    echo -e "${YELLOW}!${NC} GitHub SSH 未配置"
fi

if ssh -T git@gitee.com -o ConnectTimeout=5 2>&1 | grep -q "successfully\|fies09\|Welcome"; then
    echo -e "${GREEN}✓${NC} Gitee SSH 连接正常"
else
    echo -e "${YELLOW}!${NC} Gitee SSH 未配置"
fi

# 显示帮助
echo ""
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""
