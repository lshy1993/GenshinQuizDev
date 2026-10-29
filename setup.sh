#!/bin/bash
# 用法：
#   ./setup.sh          克隆/更新主仓库与 repos 下所有子仓库（统一使用 main，没有则 master）
#   ./setup.sh --up     更新后执行 docker compose up -d --build 重启全部服务
#   ./setup.sh --up -s  同上，但使用 sudo 调用 docker（Synology SSH 常需要）

set -u

# 统一走 SSH：把所有 https://github.com/ 地址（含子模块、已有仓库的 origin）透明改写成 git@github.com:，
# 这样使用 SSH key 即可，不会再要求输入 GitHub 账号密码
export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new -o BatchMode=yes"
git() { command git -c "url.git@github.com:.insteadOf=https://github.com/" "$@"; }

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 格式：目录名|仓库地址
REPOS=(
    "frontend|https://github.com/lshy1993/genshin-quiz.git"
    "backend|https://github.com/lshy1993/genshin-quiz-backend.git"
    "MoeLink|https://github.com/lshy1993/MoeLink.git"
    "AlphaSoul_Js|https://github.com/lshy1993/AlphaSoul_Js.git"
    "node-api|https://github.com/lshy1993/node-api.git"
    "moelink-gateway|https://github.com/lshy1993/moelink-gateway.git"
)

FAILED=()

# 切换到主分支（优先 main，没有则 master）并快进更新；
# 有本地未提交改动或分支分叉时跳过，不会覆盖任何内容
update_repo() {
    local dir=$1
    local name=$2
    local branch

    if ! git -C "$dir" fetch --prune origin; then
        print_error "$name: fetch 失败"
        FAILED+=("$name")
        return
    fi

    if git -C "$dir" show-ref --verify --quiet refs/remotes/origin/main; then
        branch=main
    elif git -C "$dir" show-ref --verify --quiet refs/remotes/origin/master; then
        branch=master
    else
        print_error "$name: 远程没有 main/master 分支"
        FAILED+=("$name")
        return
    fi

    if [ -n "$(git -C "$dir" status --porcelain --untracked-files=no)" ]; then
        print_warning "$name: 存在本地未提交改动，跳过（请手动处理）"
        FAILED+=("$name")
        return
    fi

    if [ "$(git -C "$dir" rev-parse --abbrev-ref HEAD)" != "$branch" ]; then
        print_status "$name: 切换到 $branch"
        if ! git -C "$dir" checkout "$branch" 2>/dev/null \
            && ! git -C "$dir" checkout -b "$branch" --track "origin/$branch"; then
            print_error "$name: 无法切换到 $branch"
            FAILED+=("$name")
            return
        fi
    fi

    if git -C "$dir" pull --ff-only origin "$branch"; then
        if [ -f "$dir/.gitmodules" ]; then
            git -C "$dir" submodule update --init --recursive || print_warning "$name: 子模块更新失败"
        fi
        print_status "$name ($branch) 已更新到 $(git -C "$dir" rev-parse --short HEAD)"
    else
        print_error "$name: 无法快进合并（本地 $branch 可能已分叉）"
        FAILED+=("$name")
    fi
}

clone_or_update() {
    local name=$1
    local url=$2

    if [ -d "$name/.git" ]; then
        print_status "更新项目: $name"
        update_repo "$name" "$name"
    elif [ -d "$name" ]; then
        print_warning "$name 目录存在但不是 Git 仓库，跳过"
        FAILED+=("$name")
    else
        print_status "克隆项目: $name"
        if git clone "$url" "$name"; then
            update_repo "$name" "$name"
        else
            print_error "$name: 克隆失败"
            FAILED+=("$name")
        fi
    fi
}

main() {
    local do_up=0 use_sudo=0
    for arg in "$@"; do
        case "$arg" in
            --up) do_up=1 ;;
            -s|--sudo) use_sudo=1 ;;
            *) print_error "未知参数: $arg"; exit 1 ;;
        esac
    done

    cd "$(dirname "$0")" || exit 1

    print_status "🚀 更新主仓库"
    if [ -d .git ]; then
        update_repo . "GenshinQuizDev"
    fi

    mkdir -p repos
    cd repos || exit 1
    for repo in "${REPOS[@]}"; do
        IFS='|' read -r name url <<< "$repo"
        clone_or_update "$name" "$url"
    done
    cd ..

    if [ ${#FAILED[@]} -gt 0 ]; then
        print_warning "以下仓库未成功更新: ${FAILED[*]}"
    else
        print_status "✅ 所有仓库已是最新"
    fi

    if [ "$do_up" -eq 1 ]; then
        local docker_cmd="docker"
        [ "$use_sudo" -eq 1 ] && docker_cmd="sudo docker"
        print_status "🐳 重新构建并启动全部服务"
        $docker_cmd compose up -d --build || { print_error "docker compose 启动失败"; exit 1; }
        $docker_cmd compose ps
    fi

    [ ${#FAILED[@]} -eq 0 ]
}

main "$@"
