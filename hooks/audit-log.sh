#!/bin/bash
# audit-log.sh — PostToolUse 钩子，记录所有文件修改事件
# matcher: Edit|Write|Bash
set -euo pipefail

LOG_FILE="$HOME/.claude/logs/file-audit.jsonl"
MAX_SIZE=$((10 * 1024 * 1024))  # 10MB

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null || true)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || true)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || true)
SESSION="${CLAUDE_CODE_SESSION_ID:-unknown}"

# 提取仓库和 worktree 信息
REPO=""
WT=""
if [ -n "$FILE" ]; then
  REPO=$(git -C "$(dirname "$FILE")" rev-parse --show-toplevel 2>/dev/null || true)
  [ -n "$REPO" ] && REPO=$(basename "$REPO")
  case "$FILE" in
    */wt/*) WT=$(echo "$FILE" | sed -E 's|.*/wt/([^/]+/[^/]+)/.*|\1|') ;;
    */.claude/worktrees/*) WT=$(echo "$FILE" | sed -E 's|.*/\.claude/worktrees/([^/]+)/.*|\1|') ;;
  esac
elif [ -n "$CMD" ]; then
  # Bash 命令，提取可能的目标路径
  REPO=$(git rev-parse --show-toplevel 2>/dev/null || true)
  [ -n "$REPO" ] && REPO=$(basename "$REPO")
  case "$PWD" in
    */wt/*) WT=$(echo "$PWD" | sed -E 's|.*/wt/([^/]+/[^/]+)/.*|\1|') ;;
    */.claude/worktrees/*) WT=$(echo "$PWD" | sed -E 's|.*/\.claude/worktrees/([^/]+)/.*|\1|') ;;
  esac
fi

# 无文件操作则跳过
[ -z "$FILE" ] && [ -z "$CMD" ] && exit 0

mkdir -p "$(dirname "$LOG_FILE")"

# 轮转：超过 MAX_SIZE 时保留最近 5000 行
if [ -f "$LOG_FILE" ]; then
  sz=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
  if [ "$sz" -gt "$MAX_SIZE" ]; then
    tail -n 5000 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
  fi
fi

jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
       --arg tool "$TOOL" \
       --arg file "$FILE" \
       --arg cmd "$CMD" \
       --arg repo "${REPO:-}" \
       --arg wt "${WT:-}" \
       --arg session "$SESSION" \
  '{ts: $ts, tool: $tool, file: $file, cmd: $cmd, repo: $repo, wt: $wt, session: $session}' \
  >> "$LOG_FILE"

exit 0
