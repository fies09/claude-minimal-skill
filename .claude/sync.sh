#!/bin/bash
# 手动同步脚本 - 把当前工作目录的 git 仓库提交并推送到 GitHub / Gitee
#
# 手动调用：cd <目标项目> && bash /Users/fanyong/.claude/skills/minimal/.claude/sync.sh
#
# 原先由 skill-stop 钩子自动触发，但 Claude Code 没有 skill-stop / skill-start
# 事件，skill 目录的 .claude/settings.json 也不是有效作用域 —— 该钩子从不触发，
# 自动推送链已废弃。本脚本改为纯手动入口。

# 使用当前工作目录（skill-stop 钩子自动设置为用户项目目录）
PROJECT_PATH="$(pwd)"

# 检查是否为 git 仓库
if [ ! -d "$PROJECT_PATH/.git" ]; then
    exit 0
fi

cd "$PROJECT_PATH" || exit 1

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Git 用户信息
GIT_NAME="fies09"
GIT_EMAIL="fanyong109@163.com"
GITHUB_USER="fies09"
GITEE_USER="fies09"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
GITEE_TOKEN="${GITEE_TOKEN:-}"

# 获取项目名称（当前目录名）
REPO_NAME=$(basename "$PWD")

echo ""
echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    自动同步项目: ${REPO_NAME}${NC}"
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

# 提交前检查待提交文件是否含敏感文件，命中则中止（不动暂存区、不改远端配置）
CANDIDATE_FILES=$( { git ls-files --others --exclude-standard; git diff --name-only; git diff --staged --name-only; } | sort -u )
SECRET_PATTERN='(^|/)\.env$|(^|/)\.env\.local$|(^|/)\.env\..*\.local$|(^|/)\.pem$|(^|/)\.p12$|(^|/)\.key$|(^|/)\.npmrc$|(^|/)\.netrc$|(^|/)id_rsa|(^|/)credentials[^/]*\.json$'
if echo "$CANDIDATE_FILES" | grep -Eq "$SECRET_PATTERN"; then
    echo -e "${RED}✗ 待提交文件含疑似敏感文件，已中止同步:${NC}"
    echo "$CANDIDATE_FILES" | grep -E "$SECRET_PATTERN" | sed 's/^/    /'
    echo -e "${YELLOW}  请先把这些文件加入 .gitignore，或改用 git add 指定文件后再手动提交${NC}"
    exit 1
fi

# 检查远程仓库是否存在并自动创建（默认私有，避免把项目内容公开发布）
check_and_create_github() {
    local repo="$1"
    local resp
    resp=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $GITHUB_TOKEN" \
        "https://api.github.com/repos/$GITHUB_USER/$repo" 2>/dev/null)

    if [ "$resp" != "200" ] && [ -n "$GITHUB_TOKEN" ]; then
        echo "[→] GitHub 仓库不存在，正在创建..."
        local code
        code=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Authorization: Bearer $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3+json" \
            -d "{\"name\":\"$repo\",\"private\":true}" \
            "https://api.github.com/user/repos")
        if [ "$code" = "201" ]; then
            echo "[✓] GitHub 仓库已创建"
        else
            echo "[!] GitHub 仓库创建失败（HTTP $code），请手动创建后重试"
        fi
    fi
}

check_and_create_gitee() {
    local repo="$1"
    local resp
    resp=$(curl -s -o /dev/null -w "%{http_code}" \
        "https://gitee.com/api/v5/repos/$GITEE_USER/$repo?access_token=$GITEE_TOKEN" 2>/dev/null)

    if [ "$resp" != "200" ] && [ -n "$GITEE_TOKEN" ]; then
        echo "[→] Gitee 仓库不存在，正在创建..."
        local code
        code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "https://gitee.com/api/v5/user/repos" \
            -H "Content-Type: application/json" \
            -d "{\"access_token\":\"$GITEE_TOKEN\",\"name\":\"$repo\",\"private\":true}")
        if [ "$code" = "201" ]; then
            echo "[✓] Gitee 仓库已创建"
        else
            echo "[!] Gitee 仓库创建失败（HTTP $code），请手动创建后重试"
        fi
    fi
}

# 检查/创建 GitHub 仓库（走 SSH，不把 token 写进 .git/config）
if ! git remote | grep -q "github"; then
    check_and_create_github "$REPO_NAME"
    git remote add github "git@github.com:$GITHUB_USER/$REPO_NAME.git" 2>/dev/null || \
    git remote set-url github "git@github.com:$GITHUB_USER/$REPO_NAME.git"
fi

# 检查/创建 Gitee 仓库（走 https + Keychain 凭据助手，不把 token 写进 .git/config）
if ! git remote | grep -q "gitee"; then
    check_and_create_gitee "$REPO_NAME"
    git remote add gitee "https://gitee.com/$GITEE_USER/$REPO_NAME.git" 2>/dev/null || \
    git remote set-url gitee "https://gitee.com/$GITEE_USER/$REPO_NAME.git"
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
