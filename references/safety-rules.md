# 安全规则参考

本文件包含 /minimal 模式下的安全确认流程。仅在涉及文件删除或包下载时参考。

---

## 文件删除确认

涉及 `rm`、`rm -rf`、`unlink`、`rmdir`、`os.remove()`、`shutil.rmtree()` 等操作时：

**输出格式：**
```
待删除文件：
✅ /path/to/temp.log - 临时日志
⚠️ /path/to/config.bak - 备份文件，请确认
❌ /path/to/data.db - 数据库文件，建议保留

确认删除 ✅ 标记的文件？⚠️ 文件需逐个确认。
```

**规则：**
- 列出完整路径
- 用 ✅/⚠️/❌ 标注风险级别
- 等待用户确认后执行
- 数据库文件、配置文件默认标记为 ❌

---

## 下载与安装

涉及包管理、文件下载、模型下载、镜像拉取（`pip install`、`npm install`、`apt-get`、
`brew install`、`wget`、`curl` 下载、`git clone`、huggingface 权重、`docker pull`）时：

1. **先在沙箱内直接执行**，不预先询问用户 —— 多数情况一次成功。
2. 失败且属沙箱/环境限制 → 交由用户手动执行，按全局规则
   `~/.claude/rules/install-handoff.md` 的固定格式给出命令 + 验证命令，等用户回复；
   同一安装命令不重试。
3. 涉及删除本地文件 → 按上方删除确认流程逐项列出并等确认。
