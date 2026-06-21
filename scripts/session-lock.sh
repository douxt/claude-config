#!/bin/bash
# session-lock.sh — 跨会话锁 registry，防止多会话并发编辑同一仓库
# VS Code 扩展模式使用（CLI 端用 wrapper 自动 worktree 隔离）
# 用法:
#   session-lock.sh start     # SessionStart: 注册 + 检测冲突
#   session-lock.sh stop      # SessionStop:  清理本会话锁
#   session-lock.sh list      # 列出当前活跃会话

LOCK_DIR="$HOME/.claude/session-locks"
STALE_HOURS=3
mkdir -p "$LOCK_DIR"

get_repo_root() {
    git rev-parse --show-toplevel 2>/dev/null || echo ""
}

lock_filename() {
    local repo="$1"
    local hash
    hash=$(echo "$repo" | md5sum 2>/dev/null | cut -c1-8 || echo "norepo")
    # 用随机串 + $$ 做唯一标识，即使同一进程多次 start 也不重复
    echo "${hash}-$$-$(date +%s)-${RANDOM}.lock"
}

clean_stale() {
    local count=0 now
    now=$(date +%s)
    for f in "$LOCK_DIR"/*.lock; do
        [[ -f "$f" ]] || continue
        # 锁文件超过 STALE_HOURS 小时即视为僵死
        local mtime
        mtime=$(stat -c %Y "$f" 2>/dev/null || echo "0")
        if [[ $((now - mtime)) -gt $((STALE_HOURS * 3600)) ]]; then
            rm -f "$f"; count=$((count + 1))
        fi
    done
    [[ $count -gt 0 ]] && echo "  清理 ${count} 个过期锁"
}

main() {
    local repo repo_name action
    repo=$(get_repo_root)
    repo_name=$(basename "$repo" 2>/dev/null || echo "unknown")
    action="${1:-}"

    case "$action" in
        start)
            if [[ -z "$repo" ]]; then
                echo "不在 git 仓库中，跳过锁检查"; return 0
            fi

            local lock_file
            lock_file="$LOCK_DIR/$(lock_filename "$repo")"
            echo "$$" > "$lock_file"
            echo "$PWD" >> "$lock_file"
            date -u +%Y-%m-%dT%H:%M:%SZ >> "$lock_file"
            clean_stale

            # 检查同一仓库的其他锁
            local my_hash active=0
            my_hash=$(basename "$lock_file" | cut -d- -f1)
            for f in "$LOCK_DIR"/*.lock; do
                [[ -f "$f" ]] || continue
                [[ "$f" == "$lock_file" ]] && continue
                local other_hash
                other_hash=$(basename "$f" | cut -d- -f1)
                [[ "$other_hash" != "$my_hash" ]] && continue
                active=$((active + 1))
            done

            if [[ $active -gt 0 ]]; then
                # 桌面弹窗（Linux notify-send → WSL PowerShell toast）
                local title msg
                msg="[session-lock] ${active} 个其他会话正在编辑 ${repo_name}，注意冲突"
                if command -v notify-send &>/dev/null; then
                    notify-send -u critical "⚠️ 会话冲突" "$msg" 2>/dev/null || true
                elif command -v powershell.exe &>/dev/null; then
                    # WSL → Windows 10/11 toast 通知
                    powershell.exe -NoProfile -Command "
                      Add-Type -AssemblyName System.Windows.Forms;
                      \$n = New-Object System.Windows.Forms.NotifyIcon;
                      \$n.Icon = [System.Drawing.SystemIcons]::Warning;
                      \$n.BalloonTipTitle = '⚠️ Claude Code 会话冲突';
                      \$n.BalloonTipText = '${active} 个其他会话正在编辑 ${repo_name}';
                      \$n.Visible = \$true;
                      \$n.ShowBalloonTip(10000);
                      Start-Sleep 3;
                      \$n.Visible = \$false
                    " 2>/dev/null || true
                fi

                # 视觉强提醒（用多个换行和符号放大可见性）
                echo ""
                echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                echo "!!!   ⚠️  冲 突 检 测  ⚠️"
                echo "!!!"
                echo "!!!   检测到 ${active} 个其他活跃锁在同一仓库"
                echo "!!!   仓库: ${repo_name}"
                echo "!!!   路径: ${repo}"
                echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                for f in "$LOCK_DIR"/*.lock; do
                    [[ -f "$f" ]] || continue
                    [[ "$f" == "$lock_file" ]] && continue
                    other_hash=$(basename "$f" | cut -d- -f1)
                    [[ "$other_hash" != "$my_hash" ]] && continue
                    local cwd started
                    cwd=$(sed -n '2p' "$f" 2>/dev/null || echo "?")
                    started=$(sed -n '3p' "$f" 2>/dev/null || echo "?")
                    echo "!!!   其他会话: cwd=${cwd}  started=${started}"
                done
                echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                echo ""
                echo "请先确认没有其他人在同时编辑本仓库，否则提交会相互覆盖。"
                echo ""
            else
                echo "会话锁注册成功（无冲突）"
            fi
            ;;

        stop)
            local pid count=0
            pid=$$
            for f in "$LOCK_DIR"/*.lock; do
                [[ -f "$f" ]] || continue
                local fpid
                fpid=$(head -1 "$f" 2>/dev/null | tr -d ' \n')
                [[ "$fpid" == "$pid" ]] && { rm -f "$f"; count=$((count + 1)); }
            done
            echo "会话锁已清理 (${count} 个)"
            ;;

        list)
            clean_stale
            local count pid cwd started
            count=$(ls "$LOCK_DIR"/*.lock 2>/dev/null | wc -l)
            echo "当前活跃会话: ${count}"
            for f in "$LOCK_DIR"/*.lock; do
                [[ -f "$f" ]] || continue
                pid=$(head -1 "$f" 2>/dev/null | tr -d ' \n')
                cwd=$(sed -n '2p' "$f" 2>/dev/null || echo "?")
                started=$(sed -n '3p' "$f" 2>/dev/null || echo "?")
                echo "   PID ${pid}  started: ${started}  cwd: ${cwd}"
            done
            ;;

        *)
            echo "用法: session-lock.sh {start|stop|list}"
            return 1
            ;;
    esac
}

main "$@"
