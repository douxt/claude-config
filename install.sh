#!/bin/bash
# 一键安装 Claude Code 配置文件到 ~/.claude/
# 用法: bash install.sh
set -e

SRC="$(cd "$(dirname "$0")" && pwd -P)"
TARGET="$HOME/.claude"

echo "=== Claude Code 配置安装 ==="
echo "源: $SRC"
echo "目标: $TARGET"
echo ""

ensure_wtrepos() {
  declare -A MAP=(
    ["UMES3"]="$HOME/projects/UMES3\n$HOME/projects/fa56-php"
    ["fa56-php"]="$HOME/projects/fa56-php"
    ["udimc_store"]="$HOME/projects/udimc_store\n$HOME/projects/fa56-php"
    ["MAF-Hub"]="$HOME/dev/MAF-Hub"
    ["cc-stack"]="$HOME/cc-stack"
    ["CeLiangBen"]="$HOME/projects/CeLiangBen\n$HOME/projects/fa56-php"
    ["claude-config"]="$HOME/projects/claude-config"
  )
  for name in "${!MAP[@]}"; do
    local target
    case "$name" in
      MAF-Hub) target="$HOME/dev/$name/.wtrepos" ;;
      cc-stack) target="$HOME/cc-stack/.wtrepos" ;;
      *) target="$HOME/projects/$name/.wtrepos" ;;
    esac
    [ -f "$target" ] && continue
    mkdir -p "$(dirname "$target")"
    printf '%b' "${MAP[$name]}" > "$target"
    echo "  ✅ .wtrepos → $target"
  done
}

link_file() {
  local rel="$1"
  local src="$SRC/$rel"
  local dst="$TARGET/$rel"

  if [ -L "$dst" ]; then
    local cur
    cur=$(readlink "$dst" 2>/dev/null || true)
    if [ "$cur" = "$src" ]; then
      echo "  ✅ $rel (已正确链接)"
      return
    fi
    echo "  ⚠️  $rel → 替换旧链接 $cur"
    rm -f "$dst"
  elif [ -e "$dst" ]; then
    echo "  📦 $rel → 备份为 $dst.bak"
    mv "$dst" "$dst.bak"
  fi

  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "  🔗 $rel"
}

# 根目录文件
link_file "CLAUDE.md"
link_file "RTK.md"
link_file "settings.json"
link_file "settings-review.json"

# Hooks
for f in "$SRC"/hooks/*.sh; do
  [ ! -f "$f" ] && continue
  name=$(basename "$f")
  link_file "hooks/$name"
done

# Scripts
for f in "$SRC"/scripts/*.sh; do
  [ ! -f "$f" ] && continue
  name=$(basename "$f")
  link_file "scripts/$name"
done

# Rubrics
for f in "$SRC"/review-rubrics/*.md; do
  [ ! -f "$f" ] && continue
  name=$(basename "$f")
  link_file "review-rubrics/$name"
done

# Skills
if [ -d "$SRC/skills" ]; then
  for dir in "$SRC"/skills/*/; do
    [ ! -d "$dir" ] && continue
    name=$(basename "$dir")
    link_file "skills/$name"
  done
fi

echo ""
echo "--- .wtrepos ---"
ensure_wtrepos
echo ""
echo "✅ 安装完成。重载 VSCode 窗口生效。"
