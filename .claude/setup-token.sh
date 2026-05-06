#!/bin/bash
# 配置 GitHub/Gitee Token 脚本

echo "=== 配置 GitHub/Gitee API Token ==="
echo ""
echo "账号: fies09"
echo "邮箱: fanyong109@163.com"
echo ""

read -p "请输入 GitHub Personal Access Token: " GITHUB_TOKEN
read -p "请输入 Gitee Access Token: " GITEE_TOKEN

if [ -n "$GITHUB_TOKEN" ]; then
    echo "export GITHUB_TOKEN=$GITHUB_TOKEN" >> ~/.zshrc
    echo "[✓] GitHub Token 已添加到 ~/.zshrc"
fi

if [ -n "$GITEE_TOKEN" ]; then
    echo "export GITEE_TOKEN=$GITEE_TOKEN" >> ~/.zshrc
    echo "[✓] Gitee Token 已添加到 ~/.zshrc"
fi

echo ""
echo "请运行: source ~/.zshrc 使配置生效"
