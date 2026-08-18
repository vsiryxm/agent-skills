#!/usr/bin/env bash
#
# sync.sh — 日常同步官方更新
#
# 功能：fetch upstream → merge 到 main → push origin main
#       → checkout my-skills → merge main → push origin my-skills
# 用法：在仓库根目录执行 ./sync.sh
#
set -euo pipefail

# 颜色输出
red()    { printf "\033[31m%s\033[0m\n" "$1"; }
green()  { printf "\033[32m%s\033[0m\n" "$1"; }
yellow() { printf "\033[33m%s\033[0m\n" "$1"; }
info()   { printf "\033[36m%s\033[0m\n" "$1"; }

# ── 前置检查 ─────────────────────────────────────────────────────────
# 确认在 git 仓库内
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    red "当前目录不在 git 仓库内"
    exit 1
fi

# 确认有 upstream remote
if ! git remote get-url upstream >/dev/null 2>&1; then
    red "未找到 upstream remote"
    echo "  请先运行 ./setup.sh 完成初始化"
    exit 1
fi

# 确认有 my-skills 分支
if ! git show-ref --verify --quiet refs/heads/my-skills; then
    red "未找到 my-skills 分支"
    echo "  请先运行 ./setup.sh 完成初始化"
    exit 1
fi

echo ""
info "=== agent-skills 日常同步 ==="
echo ""

# ── 1. 切到 main，拉取官方更新 ──────────────────────────────────────
info "[1/4] 同步 main 分支（fetch upstream）..."
git checkout main

git fetch upstream

git merge upstream/main
green "  main 已合并官方更新"

git push origin main
green "  main 已推送到 origin"

# ── 2. 切到 my-skills，合并 main ────────────────────────────────────
info "[2/4] 合并官方更新到 my-skills..."
git checkout my-skills

git merge main
green "  my-skills 已合并 main"

git push origin my-skills
green "  my-skills 已推送到 origin"

echo ""
green "=== 同步完成 ==="
echo ""
info "提示："
echo "  - 如更新了自定义 skill，需手动同步到 TeleAgent："
echo "    cp -r skills/<skill-name>/ ~/.config/TeleAgent/skills/<skill-name>/"
echo "    或用软链接（一劳永逸）："
echo "    ln -s $(pwd)/skills/<skill-name> ~/.config/TeleAgent/skills/<skill-name>"
echo ""
