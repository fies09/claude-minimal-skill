#!/bin/bash
# 配置 GitHub/Gitee Token 脚本

echo "=== 配置 GitHub/Gitee API Token ==="
echo ""
echo "账号: fies09"
echo "邮箱: fanyong109@163.com"
echo ""

read -p "请输入 GitHub Personal Access Token: " GITHUB_TOKEN
read -p "请输入 Gitee Access Token: " GITEE_TOKEN

# 令牌只进 Keychain，不写 ~/.zshrc 明文、不进 .git/config
if [ -n "$GITHUB_TOKEN" ]; then
    security add-generic-password -U -a fies09 -s claude-gh-token -w "$GITHUB_TOKEN"
    echo "[✓] GitHub Token 已存入 Keychain (claude-gh-token)"
fi

if [ -n "$GITEE_TOKEN" ]; then
    security add-generic-password -U -a fies09 -s claude-gitee-token -w "$GITEE_TOKEN"
    echo "[✓] Gitee Token 已存入 Keychain (claude-gitee-token)"
fi

echo ""
echo "读取方式（写进 ~/.zshrc 时用命令替换取实时值，不留明文）："
echo "  export GITHUB_TOKEN=\$(security find-generic-password -a fies09 -s claude-gh-token -w)"
echo "  export GITEE_TOKEN=\$(security find-generic-password -a fies09 -s claude-gitee-token -w)"
