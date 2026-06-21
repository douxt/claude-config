# Claude Code 配置仓库 / Claude Code Config

个人 [Claude Code](https://claude.com/claude-code) 全局配置，一键部署到 `~/.claude/`。

Personal global configuration for [Claude Code](https://claude.com/claude-code), one-command deployment to `~/.claude/`.

## 安装 / Install

```bash
git clone https://github.com/douxt/claude-config.git ~/projects/claude-config
cd ~/projects/claude-config
bash install.sh
```

`install.sh` 将文件 symlink 到 `~/.claude/`，并自动创建缺失的项目 `.wtrepos`。

`install.sh` symlinks all files into `~/.claude/` and auto-creates missing `.wtrepos` files.

## 包含内容 / What's Inside

| 目录 / Dir | 说明 / Description |
|-----------|-------------------|
| `CLAUDE.md` | 全局行为规则 / Global behavior rules（中文） |
| `RTK.md` | RTK 工具指令 / RTK tool instructions |
| `settings.json` | 公开配置（hooks、权限、插件）/ Public config（hooks, permissions, plugins） |
| `hooks/` | PreToolUse 钩子，多层防御 / PreToolUse hooks, multi-layer defense |
| `review-rubrics/` | 代码评审标准（6 个维度）/ Code review rubrics（6 dimensions） |
| `scripts/` | 会话启动安全规则 / Session-start safety rules |
| `skills/` | 内置技能 / Bundled skills |
| `docs/` | 使用文档 / Documentation |

### 钩子体系 / Hook System

| 钩子 / Hook | 功能 / Function |
|-------------|----------------|
| `bash-firewall.sh` | 拦截非 worktree 的重定向/sed -i/heredoc 写入 |
| `file-guard.sh` | 拦截非 worktree 的 Edit/Write 操作 |
| `block-enter-worktree.sh` | 禁用 EnterWorktree，统一走 `wt create` |
| `audit-log.sh` | 事后审计所有文件修改 |
| `common.sh` | 共享工具函数 / Shared utility functions |

### 评审标准 / Review Rubrics

| 标准 / Rubric | 适用对象 / Applies To |
|---------------|---------------------|
| `default.md` | 通用代码 / General code |
| `plan.md` | 方案/计划 / Plans |
| `security.md` | 安全相关代码 / Auth & security |
| `testing.md` | 测试代码 / Tests |
| `config.md` | 配置文件 / Config files |
| `performance.md` | 性能敏感代码 / Performance |

## 私密配置 / Secrets

API key 等私密配置放在 `~/.claude/settings.local.json`，**不提交** 到仓库。

Put secrets (API keys, tokens) in `~/.claude/settings.local.json` — **never commit** to this repo.

```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "sk-xxxx",
    "ANTHROPIC_MODEL": "deepseek-v4-pro[1m]"
  }
}
```

详见 / See [docs/settings-local-json.md](docs/settings-local-json.md)。

## 许可 / License

MIT
