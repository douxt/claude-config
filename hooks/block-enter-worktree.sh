#!/bin/bash
# 动态判断：有 wt → 封堵，无 wt → 放行（NAS/Docker/CI）
if command -v wt &>/dev/null; then
  >&2 echo ""
  >&2 echo "╔══════════════════════════════════════════════════╗"
  >&2 echo "║  EnterWorktree 已禁用                            ║"
  >&2 echo "║  请用 wt create 创建隔离 worktree                ║"
  >&2 echo "╚══════════════════════════════════════════════════╝"
  exit 2
fi
exit 0
