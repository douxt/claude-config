#!/bin/bash
# 封堵 EnterWorktree，统一走 wt create
>&2 echo ""
>&2 echo "╔══════════════════════════════════════════════════╗"
>&2 echo "║  EnterWorktree 已禁用                            ║"
>&2 echo "║  请用 wt create 创建隔离 worktree                ║"
>&2 echo "╚══════════════════════════════════════════════════╝"
exit 2
