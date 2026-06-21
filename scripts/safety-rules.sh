#!/usr/bin/env bash
# SessionStart hook: inject code safety rules
# These are MANDATORY rules that must be followed in every session.
cat << 'RULES'
## 代码修改安全规则（强制）

### 基本功
- 修改前先备份 `cp file.php file.php.bak`
- 改完一个逻辑点就提交，不攒批
- 永不 `git checkout --`，用 `git stash` 或 `.bak` 恢复

### 全局替换（最高风险）
1. 替换前 `grep -n` 列清单
2. 确认全部在预期范围内
3. 替换后再次 `grep -n` 对比
4. 跑 API 测试验证不报错

### 恢复后
- `git diff --stat` 检查改动量
- `grep` 关键字段确认存在
- API 测试确认功能正常

### Worktree 红线
- 禁止在 main 分支直接编辑/提交，所有工作走 worktree
- 禁止 `rm -rf worktree` 目录，用 `git worktree remove`
- 禁止 `cd <path> && git`，用 `git -C <path> <command>`
- 合前先 rebase，PR 合完即清理 worktree

### 文件写入安全（多层防御）
- Edit/Write → file-guard 拦截非 worktree 写入
- Bash 重定向/sed -i/heredoc → bash-firewall 拦截
- 所有文件修改 → audit-log 审计（~/.claude/logs/file-audit.jsonl）
- settings.json 和 hooks/ 受自保护，不可修改
- 绕过钩子视为违规操作，不得尝试
RULES
