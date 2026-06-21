# 适配 settings.local.json

## 背景

`settings.json` 原先包含 `env`（密钥、模型等私密配置），导致 push 公开仓库时泄露。

现已分离：
- `settings.json` — 提交到 git（hooks、权限、插件等公共配置）
- `settings.local.json` — 不提交，直接放在 `~/.claude/`，`.gitignore` 已排除

Claude Code 启动时自动合并两者（后者覆盖前者）。

## 适配脚本

### 改之前

脚本直接写 `settings.json`：

```bash
# 旧：切换模型
jq '.env.ANTHROPIC_MODEL = "new-model"' ~/projects/claude-config/settings.json | sponge
# 或 tmpfile：
tmp=$(mktemp)
jq '.env.ANTHROPIC_MODEL = "new-model"' ~/projects/claude-config/settings.json > "$tmp"
mv "$tmp" ~/projects/claude-config/settings.json
```

### 改之后

目标改为 `~/.claude/settings.local.json`：

```bash
# 新：切换模型
tmp=$(mktemp)
jq '.env.ANTHROPIC_MODEL = "new-model"' ~/.claude/settings.local.json > "$tmp"
mv "$tmp" ~/.claude/settings.local.json
```

### 新增 env 变量同理

```bash
# 旧
jq '.env.DEBUG = "true"' settings.json > tmp && mv tmp settings.json

# 新
jq '.env.DEBUG = "true"' ~/.claude/settings.local.json > tmp && mv tmp ~/.claude/settings.local.json
```

## 需要改的目标

| 原来写 | 现在写 |
|--------|--------|
| `~/projects/claude-config/settings.json` | `~/.claude/settings.local.json` |
| `~/.claude/settings.json`（symlink 同源） | `~/.claude/settings.local.json` |

## 注意

- `settings.local.json` 没有 symlink，是纯本地文件
- 不存在时需先创建 `{}` 再 `jq` 写入
- 不要提交到 git（`.gitignore` 已保护）
- 重载 VSCode 窗口后生效

## 示例：模型切换脚本

```bash
#!/bin/bash
# ~/bin/switch-model.sh

MODEL="${1:-sonnet}"
FILE="$HOME/.claude/settings.local.json"

[ -f "$FILE" ] || echo '{}' > "$FILE"

tmp=$(mktemp)
jq --arg m "$MODEL" '
  .env.ANTHROPIC_MODEL = $m |
  .env.ANTHROPIC_DEFAULT_OPUS_MODEL = $m |
  .env.ANTHROPIC_DEFAULT_SONNET_MODEL = $m
' "$FILE" > "$tmp" && mv "$tmp" "$FILE"

echo "模型已切换为 $MODEL（settings.local.json）"
```
