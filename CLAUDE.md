# 全局强制规则
- 全程简洁中文，无寒暄、无客套、无多余开场与结尾。
- 不复述需求、不重复上下文，回答直击重点，杜绝冗余。

## 代码输出
- 代码精简干净，去除空行、废话注释、冗余样板内容。
- 仅复杂逻辑加必要注释，常规逻辑不写注释，排版朴素无特殊格式。

## 操作边界
- 严格限定修改范围，不擅自扩范围、不私自重构、不额外加功能。
- 关键逻辑存在疑问时，主动向用户确认；细小细节按最小改动原则处理，不擅自脑补。

## 代码修改安全（跨项目全局规则）

**基本原则：** 改前备份，改完即提交，改后验证，永不 `checkout --`。

### 1. 每次改动前
- 备份文件：`cp file.php file.php.bak`

### 2. 每完成一个逻辑改动
- 立即提交：`git add <file>` + `git commit -m "说明"`
- 不攒多个改动一起提交，不等到"功能完整"才提交

### 3. 恢复/回退
- **绝对禁止** `git checkout -- <file>`（无条件丢弃，不可逆）
- 改用 `git stash push -m "备份说明"`
- 或从 `.bak` 文件恢复

### 4. 全局替换（replace_all）安全流程
全局替换风险最高，必须按以下步骤操作：

```
① 替换前：grep -n "搜索词" file.php    # 列出所有匹配行
② 确认所有匹配都在预期范围内（无函数外误伤）
③ 执行替换
④ 替换后：grep -n "新词" file.php       # 列出所有改动行
⑤ 对比前后清单，看有无多出来的、不该改的地方
⑥ API 测试验证，确认不报错
```

### 5. 每次恢复/重试后
- `git diff --stat` 确认改动量符合预期
- `grep` 关键字符串确认改动存在
- 跑一次真实 API 测试验证功能正常

## 工具使用
- 搜索/网页抓取：优先用内置 `WebSearch` 和 `WebFetch`，多次失效后 fallback 到 `tavily_search`、`tavily_extract`、`web_search_exa` 等备选

## 踩坑自省机制
- 遇到踩坑（报错、回退、字段猜错等），先搜索网络最佳实践，再记录到当前项目的 `memory/` 目录
- 记录格式：根因 → 解决方法 → 如何预防
- 同时在 `MEMORY.md` 加索引，跨会话可查

## 长会话适配
- 全程保持规则一致，长对话不弱化约束，保留关键约定。

## 开发方法灵活选择

实施步骤前，根据破坏风险选择方法：

| 方法 | 做法 | 适用 |
|------|------|------|
| A：直接执行 | 按 plan 直接写代码 | 独立新文件，不碰已有代码 |
| B：Plan Mode | 先进 Plan Mode 出变更方案，确认后执行 | 修改已有代码，有破坏风险 |
| C：自审 | 写完用"严格审查这段实现"让 Claude 自审 | 复杂核心逻辑（多轮循环/状态机）|

**决策流程：**
- 修改已有代码？→ 方法 B
- 新文件但逻辑复杂？→ 方法 A + 方法 C
- 新文件且简单？→ 方法 A

### 计划内置 worktree 步骤（硬性）

制定任何涉及代码改动的计划时，**计划本身必须包含 worktree 创建步骤**，作为第一个实施动作：

- 单仓库项目：计划首步写 `wt create <任务名>`
- 多仓库项目：计划首步写 `bash ~/bin/wt create <任务名>`
- 仅文档/配置修改（不改代码）→ 豁免

> 这样执行计划时，worktree 自然不会被遗漏。评审计划时 rubric 也会检查此项。

## Worktree 开发安全准则（Claude Code CLI 模式）

### 核心原则
- 所有开发在 worktree 中隔离进行，**禁止在原始仓库目录下直接编辑代码**
- 一个 worktree 对应一个逻辑改动，合并后立即清理
- 统一用 `wt create` 创建 worktree
- PreToolUse hook 拦截原始仓库下的 Edit/Write，强制先进 worktree

### 硬性禁令
| 禁令 | 正确做法 |
|------|---------|
| 禁止 `rm -rf` worktree 目录 | 用 `git worktree remove` 或工具清理 |
| 禁止在原始仓库下直接编辑代码 | 先 wt create |
| 禁止 `cd <path> && git` | 用 `git -C <path> <command>` 避免沙箱弹窗 |
| 禁止 `git checkout -- <file>` | 用 `git stash` 或 `.bak` 恢复 |
| 禁止跨 worktree 直接复制文件 | 共享代码通过 git 对象库自然共享 |

### 基准分支策略
- 默认值 `origin/master`
- **CeLiangBen 项目**：长期在 `old` 分支开发，`wt` 的基准分支设为 `"head"`（基于本地当前分支），合入目标为 `old`

### 工作流
1. 用户提出改动需求
2. Claude 尝试 Edit/Write → `PreToolUse` hook 检测到在原始仓库下 → **拒绝并提示先进 worktree**
3. Claude 收到拦截 → 调用 `wt create` 创建隔离 worktree
4. 在 worktree 内完成开发、测试、提交
5. worktree 外不直接编辑代码

### 完结流程（合入 master 前必经检测）

Worktree 开发完毕合入 master 前，按以下步骤执行。**各步骤的具体命令由各项目 CLAUDE.md 定义，本流程仅列骨架。**

```
① 状态检查     → git status                    确认改动完整、无漏提交
② 编译/语法检查 → 按项目配置跑检查命令          JS 跑 babel，PHP 跑 php -l，等
③ 差异审查     → git diff master...HEAD         肉眼审查改动内容是否准确
④ 功能验证     → 本地跑 API 测试或手动验证       确保改动有效
⑤ Rebase       → git pull --rebase origin master 基于最新代码解决冲突
⑥ 合并到 master → git checkout master && merge   合入主线
⑦ 推送         → git push origin master         远程同步
⑧ 清理         → 删 worktree、删本地/远程分支    不留垃圾
```

> **注意：** ①②③④ 在步骤 ⑤ 之前执行，因为 rebase 前要确保当前代码是正确的。
> 如果 rebase 有冲突，解决后重复 ②③④ 再合并。

## Worktree 内仍适用原有安全规则
进入 worktree 后，以下规则不变：
- 改前 `cp file.php file.php.bak`
- 改完即提交，不攒批
- 全局替换走 `grep -n` 流程
- 恢复后 `git diff --stat` + `grep` + API 验证

### 已知限制
- **子代理可绕过 hook**：`PreToolUse` 钩子在子代理中不可靠，不依赖它作唯一防线
- **记忆碎片化**：不同 worktree 路径下 `~/.claude/projects/` 会分裂记忆和会话历史。
  关键决策、踩坑记录必须写 CLAUDE.md 或本项目 `memory/` 目录，确保跨 worktree 可查
- **多 worktree 并发**：同时运行 3-5 个 worktree 时，注意 Docker 服务、端口等共享资源冲突

## 文件写入多层防御

所有文件写入经过三层防线：

1. **file-guard**（Edit/Write 工具）— 路径白名单 + chmod 444 兜底 + 自保护（禁止修改 settings.json、hooks/、.git-hooks/）
2. **bash-firewall**（Bash 工具）— 命令模式匹配，拦截非 worktree 路径的重定向/sed -i/heredoc/tee/cp/mv
3. **audit-log**（PostToolUse）— 事后审计所有文件修改，日志在 `~/.claude/logs/file-audit.jsonl`

### 子代理约束
- ⚠️ **子代理不继承 PreToolUse 钩子**（已知限制 Issue #43772），file-guard 和 bash-firewall 在子代理中不生效
- 唯一约束手段：CLAUDE.md 行为规则 + audit-log 事后审计发现违规
- 禁止在子代理中用 Bash 重定向/heredoc 绕过 Edit/Write 拦截（违规会被 audit-log 记录）
- 如钩子拦截，改用 worktree 路径，不得尝试绕过

## 多仓库开发（wt）

跨前后端仓库（UMES3 + fa56-php）同时修改时使用 `wt` 工具：

- 创建新任务：`bash ~/bin/wt create <任务名>`
- 提交两边改动：`bash ~/bin/wt commit <任务名> "消息"`
- 查看两仓库状态：`bash ~/bin/wt status <任务名>`
- 清理：`bash ~/bin/wt cleanup <任务名>`

## 提交流程（全局硬性规则）

所有仓库已配置全局 pre-commit hook（`~/.git-hooks/pre-commit`），**禁止直接 `git commit`**。
检测到 `git commit` 失败时，必须按以下规则执行：

- 单仓库小改动 → 用 `bash ~/bin/wt commit <任务名> "消息"` 代替
- 双仓库改动（UMES3 + fa56-php） → 先 `bash ~/bin/wt create <任务名>` 再提交

@RTK.md

<!-- CODEGRAPH_START -->
## CodeGraph

This project has a CodeGraph MCP server (`codegraph_*` tools) configured. CodeGraph is a tree-sitter-parsed knowledge graph of every symbol, edge, and file. Reads are sub-millisecond and return structural information grep cannot.

### When to prefer codegraph over native search

Use codegraph for **structural** questions — what calls what, what would break, where is X defined, what is X's signature. Use native grep/read only for **literal text** queries (string contents, comments, log messages) or after you already have a specific file open.

| Question | Tool |
|---|---|
| "Where is X defined?" / "Find symbol named X" | `codegraph_search` |
| "What calls function Y?" | `codegraph_callers` |
| "What does Y call?" | `codegraph_callees` |
| "How does X reach/become Y? / trace the flow from X to Y" | `codegraph_trace` (one call = the whole path, incl. callback/React/JSX dynamic hops) |
| "What would break if I changed Z?" | `codegraph_impact` |
| "Show me Y's signature / source / docstring" | `codegraph_node` |
| "Give me focused context for a task/area" | `codegraph_context` |
| "See several related symbols' source at once" | `codegraph_explore` |
| "What files exist under path/" | `codegraph_files` |
| "Is the index healthy?" | `codegraph_status` |

### Rules of thumb

- **Answer directly — don't delegate exploration.** For "how does X work" / architecture questions, answer with 2-3 codegraph calls: `codegraph_context` first, then ONE `codegraph_explore` for the source of the symbols it surfaces. For a specific **flow** ("how does X reach Y") start with `codegraph_trace` from→to — one call returns the whole path with dynamic hops bridged — then ONE `codegraph_explore` for the bodies; don't rebuild the path with `codegraph_search` + `codegraph_callers`. Codegraph IS the pre-built index, so spawning a separate file-reading sub-task/agent — or running a grep + read loop — repeats work codegraph already did and costs more for the same answer.
- **Trust codegraph results.** They come from a full AST parse. Do NOT re-verify them with grep — that's slower, less accurate, and wastes context.
- **Don't grep first** when looking up a symbol by name. `codegraph_search` is faster and returns kind + location + signature in one call.
- **Don't chain `codegraph_search` + `codegraph_node`** when you just want context — `codegraph_context` is one call.
- **Don't loop `codegraph_node` over many symbols** — one `codegraph_explore` call returns several symbols' source grouped in a single capped call, while each separate node/Read call re-reads the whole context and costs far more.
- **Index lag — check the staleness banner, don't guess a wait.** When a codegraph response starts with "⚠️ Some files referenced below were edited since the last index sync…", the listed files are pending re-index — Read those specific files for accurate content. Files NOT in that banner are fresh and codegraph is authoritative for them. `codegraph_status` also lists pending files under "Pending sync".

### If `.codegraph/` doesn't exist

The MCP server returns "not initialized." Ask the user: *"I notice this project doesn't have CodeGraph initialized. Want me to run `codegraph init -i` to build the index?"*
<!-- CODEGRAPH_END -->
