#!/bin/bash
# common.sh — 多层防御共享工具函数
# 被 bash-firewall.sh / file-guard.sh / audit-log.sh source

PROTECTED_REPOS=(
  "$HOME/projects/UMES3"
  "$HOME/projects/fa56-php"
  "$HOME/projects/CeLiangBen"
  "$HOME/projects/udimc_store"
  "$HOME/projects/claude-config"
  "$HOME/dev/MAF-Hub"
  "$HOME/cc-stack"
)

get_repo_root() {
  local file="$1"
  [ -z "$file" ] && return 1
  git -C "$(dirname "$file")" rev-parse --show-toplevel 2>/dev/null || true
}

is_protected_repo() {
  local path="$1"
  local abs
  abs=$(realpath "$path" 2>/dev/null || echo "$path")
  for repo in "${PROTECTED_REPOS[@]}"; do
    case "$abs" in
      "$repo"|"$repo/"*) return 0 ;;
    esac
  done
  return 1
}

is_in_worktree() {
  local path="$1"
  local abs
  abs=$(realpath "$path" 2>/dev/null || echo "$path")
  case "$abs" in
    "$HOME/wt/"*) return 0 ;;
  esac
  case "$abs" in
    *"/.claude/worktrees/"*) return 0 ;;
  esac
  return 1
}

resolve_relative_path() {
  local path="$1" cwd="${2:-$PWD}"
  # 包含 & 后跟数字或 - 的不是合法文件路径（fd 复制残留）
  case "$path" in
    *'&'[0-9]* | *'&-'*) return 1 ;;
  esac
  case "$path" in
    /*) echo "$path" ;;
    ~*) echo "${HOME}${path:1}" ;;
    *) echo "${cwd%/}/${path}" ;;
  esac
}

# 从 Bash 命令中提取目标文件路径（启发式）
# 返回换行分隔的路径列表
extract_target_files() {
  local cmd="$1"
  local results=()

  # 先清掉 fd 复制/关闭（2>&1、>&2、2>&-），这些不涉及文件
  local clean_cmd
  clean_cmd=$(echo "$cmd" | sed -E 's/[12]?>&[0-9]+//g; s/[12]?>&-//g')
  # 重定向 > file, >> file, &> file, 1> file, 2> file
  # 用 grep -o 提取 > 后的第一个非空白 token
  local redirects
  redirects=$(echo "$clean_cmd" | grep -oP '[12&]?>>?(?:\s*\S+)' 2>/dev/null || true)
  if [ -n "$redirects" ]; then
    while IFS= read -r token; do
      local file
      file=$(echo "$token" | sed -E 's/^[12&]?>>?\s*//; s/\s.*$//')
      # 防御：如果剥离后仍残留 fd 引用（&N、&-），跳过
      case "$file" in
        '&'[0-9]* | '&-') continue ;;
      esac
      [ -n "$file" ] && results+=("$file")
    done <<< "$redirects"
  fi

  # tee file, tee -a file
  local tee_targets
  tee_targets=$(echo "$cmd" | grep -oP 'tee\s+(?:-a\s+)?(\S+)' 2>/dev/null || true)
  if [ -n "$tee_targets" ]; then
    while IFS= read -r token; do
      local file
      file=$(echo "$token" | sed -E 's/^tee\s+(-a\s+)?//; s/\s.*$//')
      [ -n "$file" ] && [ "$file" != "|" ] && results+=("$file")
    done <<< "$tee_targets"
  fi

  # sed -i file, awk -i inplace file, perl -i file
  local inplace
  inplace=$(echo "$cmd" | grep -oP '(?:sed|awk|perl)\s+.*-i[^;|&]*\s+(\S+)' 2>/dev/null || true)
  if [ -n "$inplace" ]; then
    local file
    file=$(echo "$inplace" | awk '{print $NF}')
    [ -n "$file" ] && results+=("$file")
  fi

  # cp src dst, mv src dst → 提取最后一个参数
  if echo "$cmd" | grep -qP '(?:^|[|;&])\s*cp\s'; then
    local dst
    dst=$(echo "$cmd" | awk '{print $NF}')
    [ -n "$dst" ] && results+=("$dst")
  fi
  if echo "$cmd" | grep -qP '(?:^|[|;&])\s*mv\s'; then
    local dst
    dst=$(echo "$cmd" | awk '{print $NF}')
    [ -n "$dst" ] && results+=("$dst")
  fi

  # dd of=file
  local dd_targets
  dd_targets=$(echo "$cmd" | grep -oP 'dd\s+.*of=(\S+)' 2>/dev/null || true)
  if [ -n "$dd_targets" ]; then
    local file
    file=$(echo "$dd_targets" | sed -E 's/.*of=//; s/\s.*$//')
    [ -n "$file" ] && results+=("$file")
  fi

  printf '%s\n' "${results[@]}"
}
