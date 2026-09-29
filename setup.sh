#!/usr/bin/env bash
#
# setup.sh — 新机器初始化 agent-skills 仓库
#
# 功能：clone fork → 配置 upstream → 创建 my-skills 分支 → 检查就绪
# 用法：在当前仓库根目录执行 ./setup.sh
#       （脚本已在 git 仓库内则直接复用该仓库，不会重复 clone）
# author: simon
#

set -euo pipefail

# ============================================================================
# 配置区（按需修改）
# ============================================================================
GITHUB_USER="vsiryxm"
REPO_NAME="agent-skills"
UPSTREAM_URL="https://github.com/addyosmani/agent-skills.git"
INSTALL_DIR="$HOME/workspace/ai-project"
# ============================================================================

ORIGIN_URL="git@github.com:${GITHUB_USER}/${REPO_NAME}.git"

# TARGET_DIR 解析：脚本自身若已在 git 仓库内，直接复用该目录；
# 否则按 INSTALL_DIR/REPO_NAME 定位（新机器首次 clone 的场景）。
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -d "${SCRIPT_DIR}/.git" ]; then
    TARGET_DIR="${SCRIPT_DIR}"
else
    TARGET_DIR="${INSTALL_DIR}/${REPO_NAME}"
fi

# 颜色输出
red()    { printf "\033[31m%s\033[0m\n" "$1"; }
green()  { printf "\033[32m%s\033[0m\n" "$1"; }
yellow() { printf "\033[33m%s\033[0m\n" "$1"; }
info()   { printf "\033[36m%s\033[0m\n" "$1"; }

echo ""
info "=== agent-skills 新机器初始化 ==="
echo ""

# ── 1. 检查 SSH 连通性 ──────────────────────────────────────────────
info "[1/5] 检查 GitHub SSH 连通性..."

# 注意：认证成功时 ssh -T 的退出码仍为 1（GitHub 不提供 shell access），
# 而脚本开了 pipefail，若写成 `cmd | grep -q KEY` 会取走 ssh 的 1 导致误判。
# 因此这里先捕获输出（`|| true` 防止 set -e 中断），再对文本做匹配。
SSH_OUT="$(ssh -T -o BatchMode=yes -o StrictHostKeyChecking=accept-new git@github.com 2>&1 || true)"
if ! printf '%s\n' "${SSH_OUT}" | grep -q "successfully authenticated"; then
    red "  SSH 认证失败。请先配置 GitHub SSH key："
    echo "    1. 生成 key:  ssh-keygen -t ed25519 -C 'your_email@example.com'"
    echo "    2. 添加到 ssh-agent: eval \"\$(ssh-agent -s)\" && ssh-add ~/.ssh/id_ed25519"
    echo "    3. 复制公钥:  pbcopy < ~/.ssh/id_ed25519.pub"
    echo "    4. 添加到 GitHub: Settings → SSH and GPG keys → New SSH key"
    echo "    5. 测试连接:  ssh -T git@github.com"
    echo ""
    echo "  ssh 实际返回:"
    printf '%s\n' "${SSH_OUT}" | sed 's/^/    /'
    exit 1
fi
green "  SSH 认证通过"

# ── 2. 检查目标目录 ─────────────────────────────────────────────────
info "[2/5] 检查安装目录..."
if [ -d "$TARGET_DIR" ]; then
    green "  目标目录已存在: ${TARGET_DIR}"
elif [ -d "$INSTALL_DIR" ]; then
    green "  父目录已存在: ${INSTALL_DIR}"
    yellow "  目标目录待 clone: ${TARGET_DIR}"
else
    mkdir -p "$INSTALL_DIR"
    yellow "  已创建目录: ${INSTALL_DIR}"
fi

# ── 3. 检查是否已 clone ──────────────────────────────────────────────
info "[3/5] Clone fork 仓库..."
if [ -d "${TARGET_DIR}/.git" ]; then
    yellow "  仓库已存在: ${TARGET_DIR}（跳过 clone）"
elif [ -e "$TARGET_DIR" ]; then
    red "  目标目录已存在但不是 git 仓库: ${TARGET_DIR}"
    echo "  请先移走该目录，或修正 INSTALL_DIR 后重试。"
    exit 1
else
    git clone "$ORIGIN_URL" "$TARGET_DIR"
    green "  Clone 完成: ${TARGET_DIR}"
fi

cd "$TARGET_DIR"

# ── 4. 配置 upstream remote ──────────────────────────────────────────
info "[4/5] 配置 upstream remote..."
if git remote get-url upstream >/dev/null 2>&1; then
    CURRENT=$(git remote get-url upstream)
    if [ "$CURRENT" = "$UPSTREAM_URL" ]; then
        green "  upstream 已存在且正确: $UPSTREAM_URL"
    else
        yellow "  upstream 存在但地址不同，更新中..."
        git remote set-url upstream "$UPSTREAM_URL"
        green "  upstream 已更新: $UPSTREAM_URL"
    fi
else
    git remote add upstream "$UPSTREAM_URL"
    green "  upstream 已添加: $UPSTREAM_URL"
fi

# ── 5. 检查 my-skills 分支 ───────────────────────────────────────────
info "[5/5] 检查 my-skills 分支..."
if git show-ref --verify --quiet refs/heads/my-skills; then
    git checkout my-skills >/dev/null 2>&1
    green "  已切换到 my-skills 分支"
else
    # fork 远程有 my-skills 分支
    if git show-ref --verify --quiet refs/remotes/origin/my-skills; then
        git checkout my-skills >/dev/null 2>&1
        green "  已从远程检出 my-skills 分支"
    else
        # 新 fork，还没有 my-skills 分支
        git checkout -b my-skills
        yellow "  已创建 my-skills 分支（记得提交自定义 skill 后推送）"
    fi
fi

echo ""
green "=== 初始化完成 ==="
echo ""
echo "仓库路径:   $TARGET_DIR"
echo "origin:     $ORIGIN_URL"
echo "upstream:   $UPSTREAM_URL"
echo "当前分支:   $(git branch --show-current)"
echo ""
info "下一步："
echo "  1. 日常同步官方更新:  ./sync.sh"
echo "  2. 指示各ai agent安装"

