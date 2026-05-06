#!/bin/bash
# Git 双平台自动同步配置向导

cd /Users/fanyong/.claude/skills/minimal

echo "=== GitHub + Gitee 双平台自动同步配置 ==="
echo ""

# 检查是否已配置远程仓库
if git remote | grep -q "github\|gitee"; then
    echo "[✓] 远程仓库已配置:"
    git remote -v
    exit 0
fi

read -p "请输入 GitHub 仓库地址 (如 git@github.com:用户名/minimal.git): " GITHUB_URL
read -p "请输入 Gitee 仓库地址 (如 git@gitee.com:用户名/minimal.git): " GITEE_URL

if [ -z "$GITHUB_URL" ] || [ -z "$GITEE_URL" ]; then
    echo "[✗] 地址不能为空"
    exit 1
fi

git remote add github "$GITHUB_URL"
git remote add gitee "$GITEE_URL"

echo ""
echo "[✓] 远程仓库已添加"
git remote -v

echo ""
echo "首次推送中..."
git push -u github main 2>/dev/null || echo "GitHub 推送失败，请检查 SSH 密钥"
git push -u gitee main 2>/dev/null || echo "Gitee 推送失败，请检查 SSH 密钥"

echo ""
echo "=== 配置完成 ==="
echo "每次 /minimal 技能处理完文件后将自动同步"
