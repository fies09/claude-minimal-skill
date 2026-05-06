#!/bin/bash
# 自动同步脚本 - 每次 /minimal 技能执行完毕后自动推送

cd "$(dirname "$0")/.." || exit 1

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Git 用户信息
GIT_NAME="fies09"
GIT_EMAIL="fanyong109@163.com"
GITHUB_USER="fies09"
GITEE_USER="fies09"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
GITEE_TOKEN="${GITEE_TOKEN:-}"

echo ""
echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       自动同步到 GitHub/Gitee        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
echo ""

# 配置 git 用户信息
git config user.name "$GIT_NAME"
git config user.email "$GIT_EMAIL"

# 检查是否有变更（包括未跟踪文件）
if git diff --quiet && git diff --staged --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
    echo -e "${YELLOW}ℹ 没有需要提交的变更${NC}"
    exit 0
fi

echo -e "${BLUE}▶ 检测到变更，准备提交...${NC}"

# 检查远程仓库是否存在并自动创建
check_and_create_github() {
    local repo="$1"
    local resp
    resp=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $GITHUB_TOKEN" \
        "https://api.github.com/repos/$GITHUB_USER/$repo" 2>/dev/null)

    if [ "$resp" != "200" ] && [ -n "$GITHUB_TOKEN" ]; then
        echo "[→] GitHub 仓库不存在，正在创建..."
        curl -s -X POST -H "Authorization: Bearer $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3+json" \
            -d "{\"name\":\"$repo\",\"private\":false}" \
            "https://api.github.com/user/repos" > /dev/null
        echo "[✓] GitHub 仓库已创建"
    fi
}

check_and_create_gitee() {
    local repo="$1"
    local resp
    resp=$(curl -s -o /dev/null -w "%{http_code}" \
        "https://gitee.com/api/v5/repos/$GITEE_USER/$repo?access_token=$GITEE_TOKEN" 2>/dev/null)

    if [ "$resp" != "200" ] && [ -n "$GITEE_TOKEN" ]; then
        echo "[→] Gitee 仓库不存在，正在创建..."
        curl -s -X POST "https://gitee.com/api/v5/user/repos" \
            -H "Content-Type: application/json" \
            -d "{\"access_token\":\"$GITEE_TOKEN\",\"name\":\"$repo\",\"private\":false}" > /dev/null
        echo "[✓] Gitee 仓库已创建"
    fi
}

# 获取仓库名
REPO_NAME=$(basename "$PWD")

# 检查/创建 GitHub 仓库
if ! git remote | grep -q "github"; then
    check_and_create_github "$REPO_NAME"
    git remote add github "git@github.com:$GITHUB_USER/$REPO_NAME.git" 2>/dev/null || \
    git remote set-url github "git@github.com:$GITHUB_USER/$REPO_NAME.git"
fi

# 检查/创建 Gitee 仓库
if ! git remote | grep -q "gitee"; then
    check_and_create_gitee "$REPO_NAME"
    git remote add gitee "git@gitee.com:$GITEE_USER/$REPO_NAME.git" 2>/dev/null || \
    git remote set-url gitee "git@gitee.com:$GITEE_USER/$REPO_NAME.git"
fi

# 获取当前时间戳
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 添加所有变更
git add -A

# 提交变更
git commit -m "auto-sync: $TIMESTAMP" --quiet

# 推送到 GitHub
echo ""
echo -e "${BLUE}▶ 推送到 GitHub...${NC}"
if git push github main --quiet 2>/dev/null; then
    echo -e "${GREEN}✓ GitHub 同步成功${NC}"
    GITHUB_OK=true
else
    echo -e "${RED}✗ GitHub 同步失败${NC}"
    echo -e "${YELLOW}  可能原因: 未配置 SSH 密钥或网络问题${NC}"
    GITHUB_OK=false
fi

# 推送到 Gitee
echo ""
echo -e "${BLUE}▶ 推送到 Gitee...${NC}"
if git push gitee main --quiet 2>/dev/null; then
    echo -e "${GREEN}✓ Gitee 同步成功${NC}"
    GITEE_OK=true
else
    echo -e "${RED}✗ Gitee 同步失败${NC}"
    echo -e "${YELLOW}  可能原因: 未配置 SSH 密钥或网络问题${NC}"
    GITEE_OK=false
fi

# 总结
echo ""
echo -e "${BLUE}═══════════════════════════════════════${NC}"
if [ "$GITHUB_OK" = true ] && [ "$GITEE_OK" = true ]; then
    echo -e "${GREEN}✅ 同步完成: GitHub + Gitee${NC}"
elif [ "$GITHUB_OK" = true ]; then
    echo -e "${YELLOW}⚠️  同步完成: GitHub (Gitee 失败)${NC}"
elif [ "$GITEE_OK" = true ]; then
    echo -e "${YELLOW}⚠️  同步完成: Gitee (GitHub 失败)${NC}"
else
    echo -e "${RED}❌ 同步失败: 请检查网络或 SSH 配置${NC}"
fi
echo -e "${BLUE}═══════════════════════════════════════${NC}"
echo ""
