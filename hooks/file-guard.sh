#!/bin/bash
# file-guard.sh — PreToolUse 钩子，拦截非 worktree 的 Edit/Write 操作
# matcher: Edit|Write，替换 check-worktree.sh
set -euo pipefail

source /home/dou/.claude/hooks/common.sh

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || true)

# 豁免：无文件路径
[ -z "$FILE" ] && exit 0

# 豁免：安全路径
case "$FILE" in
  $HOME/.claude/*|*/CLAUDE.md|*.md|/tmp/*) exit 0 ;;
esac

# ── 自保护：禁止修改安全配置 ──
case "$FILE" in
  $HOME/.claude/settings.json|\
  $HOME/.claude/settings.local.json|\
  $HOME/.claude/hooks/*|\
  $HOME/.git-hooks/*)
    [ -f "$FILE" ] && chmod 444 "$FILE" 2>/dev/null || true
    >&2 echo ""
    >&2 echo "╔══════════════════════════════════════════════════╗"
    >&2 echo "║  file-guard：禁止修改安全配置                     ║"
    >&2 echo "║  ▸ $FILE"
    >&2 echo "║  此文件受自保护，不可通过 Claude Code 修改        ║"
    >&2 echo "╚══════════════════════════════════════════════════╝"
    exit 2
    ;;
esac

# ── 敏感文件保护 ──
case "$(basename "$FILE")" in
  .env|*.pem|*credentials*|*id_rsa*|*.key|*.secret)
    [ -f "$FILE" ] && chmod 444 "$FILE" 2>/dev/null || true
    >&2 echo ""
    >&2 echo "╔══════════════════════════════════════════════════╗"
    >&2 echo "║  file-guard：禁止修改敏感文件                     ║"
    >&2 echo "║  ▸ $FILE"
    >&2 echo "║  敏感文件不可通过 Claude Code 修改                ║"
    >&2 echo "╚══════════════════════════════════════════════════╝"
    exit 2
    ;;
esac

# ── 仓库检查 ──
REPO_ROOT=$(git -C "$(dirname "$FILE")" rev-parse --show-toplevel 2>/dev/null || true)

case "$REPO_ROOT" in
  $HOME/wt/*) exit 0 ;;
  */.claude/worktrees/*) exit 0 ;;
  $HOME/projects/UMES3|$HOME/projects/fa56-php|$HOME/projects/CeLiangBen|$HOME/projects/udimc_store|$HOME/projects/claude-config|$HOME/dev/MAF-Hub|$HOME/cc-stack)
    # 兜底：exit 2 对 Edit/Write 有时不生效，锁文件为只读
    [ -f "$FILE" ] && chmod 444 "$FILE" 2>/dev/null || true
    >&2 echo ""
    >&2 echo "╔══════════════════════════════════════════════════╗"
    >&2 echo "║  禁止在原始仓库直接编辑代码                       ║"
    >&2 echo "║  请先用 wt create 创建 worktree                  ║"
    >&2 echo "║  或 EnterWorktree 进入隔离分支后再编辑            ║"
    >&2 echo "╚══════════════════════════════════════════════════╝"
    exit 2
    ;;
esac

exit 0
