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

## 下载操作确认

涉及以下操作时需先询问：
- 包管理：pip install、npm install、apt-get、brew install
- 文件下载：wget、curl、git clone
- 模型下载：huggingface、预训练权重
- 镜像拉取：docker pull

**流程：**
1. 询问：自动下载 or 手动下载？
2. 自动下载：直接执行
3. 手动下载：展示命令，等待"已完成"

**手动下载输出格式：**
```
需手动执行：
pip install torch torchvision
npm install react react-dom

完成后回复"已完成"
```
