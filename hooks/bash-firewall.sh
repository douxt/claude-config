#!/bin/bash
# bash-firewall.sh — PreToolUse 钩子，拦截 Bash 中的非 worktree 文件写入
# matcher: Bash，排在 rtk 之后
set -euo pipefail

source /home/dou/.claude/hooks/common.sh

# 一次性读取 stdin（$() 子 shell 会消耗 stdin，不能多次 jq）
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || true)
[ -z "$CMD" ] && exit 0

CWD=$(echo "$INPUT" | jq -r '.tool_input.cwd // ""' 2>/dev/null || true)
[ -z "$CWD" ] && CWD="$PWD"

# 快速豁免：纯查询命令（无文件写入可能）
case "$CMD" in
  git\ status*|git\ log*|git\ diff*|git\ branch*|git\ stash\ list*|git\ remote*)
    exit 0 ;;
  ls*|find*|grep*|head\ *|tail\ *|less*|wc*)
    exit 0 ;;
  cd*|pwd*|which*|type*|whoami*)
    exit 0 ;;
  docker\ ps*|docker\ images*|docker\ logs*)
    exit 0 ;;
  npm\ run\ dev*|npm\ test*)
    exit 0 ;;
esac

# 提取目标文件
TARGETS=$(extract_target_files "$CMD")
[ -z "$TARGETS" ] && exit 0

BLOCKED=()
while IFS= read -r target; do
  [ -z "$target" ] && continue
  abs=$(resolve_relative_path "$target" "$CWD")

  # 豁免路径
  case "$abs" in
    /tmp/*|/dev/stdout|/dev/stderr|/dev/fd/*|/dev/*|/proc/*|/sys/*) continue ;;
    "$HOME/.claude/logs"*) continue ;;
    /run/*|/var/run/*) continue ;;
  esac

  if is_protected_repo "$abs" && ! is_in_worktree "$abs"; then
    BLOCKED+=("$abs")
  fi
done <<< "$TARGETS"

if [ ${#BLOCKED[@]} -gt 0 ]; then
  >&2 echo ""
  >&2 echo "╔══════════════════════════════════════════════════╗"
  >&2 echo "║  bash-firewall：拦截非 worktree 文件写入         ║"
  >&2 echo "╠══════════════════════════════════════════════════╣"
  for f in "${BLOCKED[@]}"; do
    >&2 echo "║  ▸ $f"
  done
  >&2 echo "╠══════════════════════════════════════════════════╣"
  >&2 echo "║  请先 wt create 创建隔离分支                      ║"
  >&2 echo "╚══════════════════════════════════════════════════╝"
  exit 2
fi

exit 0
