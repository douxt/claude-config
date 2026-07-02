#!/bin/bash
FILE=$(jq -r '.tool_input.file_path // ""' 2>/dev/null || true)

# 豁免路径
case "$FILE" in
  $HOME/.claude/*|*/CLAUDE.md|*.md|/tmp/*) exit 0 ;;
esac

if [ -z "$FILE" ]; then
    GIT_DIR=$(git rev-parse --git-dir 2>/dev/null || true)
    [ -z "$GIT_DIR" ] && exit 0
    REPO_ROOT=$(cd "$(dirname "$GIT_DIR")" && pwd -P 2>/dev/null || true)
else
    REPO_ROOT=$(git -C "$(dirname "$FILE")" rev-parse --show-toplevel 2>/dev/null || true)
fi

case "$REPO_ROOT" in
  $HOME/wt/*) exit 0 ;;
  $HOME/projects/*|$HOME/project/*|$HOME/dev/*|$HOME/cc-stack)
    # 兜底：exit 2 对 Edit/Write 有时不生效（已知缺陷），锁文件为只读
    [ -n "$FILE" ] && [ -f "$FILE" ] && chmod 444 "$FILE" 2>/dev/null || true
    >&2 echo ""
    >&2 echo "╔══════════════════════════════════════════════════╗"
    >&2 echo "║  禁止在原始仓库直接编辑代码                       ║"
    >&2 echo "║  请先用 wt create（或 git worktree add）创建隔离分支                    ║"
    >&2 echo "╚══════════════════════════════════════════════════╝"
    exit 2
    ;;
esac
exit 0
