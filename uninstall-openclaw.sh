#!/usr/bin/env bash
# ============================================================
#  OpenClaw 一键卸载脚本
#  适用系统：Linux / macOS / Windows（Git Bash 或 WSL）
#  参考文档：https://docs.openclaw.ai/install/uninstall
#
#  用法：
#    bash uninstall-openclaw.sh             # 交互模式（推荐）
#    bash uninstall-openclaw.sh --yes       # 跳过确认提示
#    bash uninstall-openclaw.sh --dry-run   # 预览模式（不实际删除）
# ============================================================

# 不使用 set -e，防止探测命令失败时意外中断脚本
set -uo pipefail

# ── 日志文件（启动时确定路径）────────────────────────────────
LOG_FILE="${HOME:-/tmp}/openclaw-uninstall-$(date +%Y%m%d-%H%M%S).log"

# 向日志文件写一行纯文本（静默失败，不影响主流程）
_log() { printf "%s\n" "$*" >> "$LOG_FILE" 2>/dev/null || true; }

# ── 颜色（非 TTY 时自动关闭）────────────────────────────────
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
fi

# ── 日志函数（终端彩色输出 + 文件纯文本双写）────────────────
info()    { printf "${CYAN}[INFO]${NC}  %s\n" "$*";  _log "[INFO]  $*"; }
ok()      { printf "${GREEN}[ OK ]${NC}  %s\n" "$*"; _log "[ OK ]  $*"; }
warn()    { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; _log "[WARN]  $*"; }
err()     { printf "${RED}[ERR ]${NC}  %s\n" "$*" >&2; _log "[ERR ]  $*"; }
step()    { printf "\n${BOLD}${BLUE}══ %s${NC}\n" "$*"; _log ""; _log "══ $*"; }
divider() {
    printf "${BLUE}%s${NC}\n" "────────────────────────────────────────────────────"
    _log        "────────────────────────────────────────────────────"
}

# ── 全局状态追踪（用于结尾摘要）─────────────────────────────
REMOVED_ITEMS=()
SKIPPED_ITEMS=()
WARNED_ITEMS=()

# ── 参数解析 ─────────────────────────────────────────────────
AUTO_YES=false
DRY_RUN=false
for arg in "${@:-}"; do
    case "$arg" in
        --yes|-y)     AUTO_YES=true ;;
        --dry-run|-n) DRY_RUN=true  ;;
    esac
done

# ── 执行命令并将输出同步写入日志（终端 + 日志双写）──────────
# 用法：run_logged CMD [ARGS...]
# 返回值：CMD 本身的退出码（通过 PIPESTATUS 穿透 tee）
run_logged() {
    "$@" 2>&1 | tee -a "$LOG_FILE"
    return "${PIPESTATUS[0]}"
}

# ── 文件/目录删除封装（支持 dry-run 和摘要追踪）─────────────
remove_path() {
    local target="$1"
    local label="${2:-$1}"
    if [ "$DRY_RUN" = true ]; then
        info "  [DRY RUN] 将删除：${target}"
        REMOVED_ITEMS+=("${label}")
        return 0
    fi
    rm -rf "$target"
    ok "  已删除：${target}"
    REMOVED_ITEMS+=("${label}")
}

# ── 确认函数 ─────────────────────────────────────────────────
confirm() {
    if [ "$AUTO_YES" = true ] || [ "$DRY_RUN" = true ]; then
        return 0
    fi
    # stdin 不是终端说明处于管道场景（如 curl | bash）
    # read 会立即读到 EOF，无法真实取得用户确认，主动拒绝
    if [ ! -t 0 ]; then
        err "检测到非交互模式（stdin 非终端）。"
        err "为防止误操作，拒绝自动执行。"
        err "请先下载脚本，再在终端直接运行；或加 --yes 参数明确授权。"
        exit 1
    fi
    local prompt="$1"
    printf "${YELLOW}%s${NC} [y/N] " "$prompt"
    read -r ans
    case "${ans:-}" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# ── 检测操作系统 ──────────────────────────────────────────────
detect_os() {
    case "$(uname -s 2>/dev/null || echo unknown)" in
        Linux*)
            # /proc/version 含 "microsoft" 字样时为 WSL
            if grep -qi microsoft /proc/version 2>/dev/null; then
                OS="wsl"
            else
                OS="linux"
            fi
            ;;
        Darwin*)               OS="macos"   ;;
        MINGW*|CYGWIN*|MSYS*)  OS="gitbash" ;;
        *)                     OS="unknown" ;;
    esac
}

# ── Root 安全检查 ─────────────────────────────────────────────
check_not_root() {
    local uid_val
    uid_val="${EUID:-$(id -u 2>/dev/null || echo 1)}"
    if [ "$uid_val" -eq 0 ]; then
        warn "检测到以 root 身份运行。注意："
        warn "  · 脚本将在 /root 而非普通用户主目录下查找 .openclaw"
        warn "  · npm/pnpm/bun 的全局包路径可能与普通用户安装时不同"
        warn "建议切换到安装 OpenClaw 时使用的普通用户再执行。"
        echo ""
        if ! confirm "仍要以 root 继续？"; then
            _log "用户以 root 身份运行，确认取消。"
            echo "已取消。"
            exit 0
        fi
        _log "用户以 root 身份运行，已确认继续。"
    fi
}

# ── 检测 CLI 安装的包管理器 ──────────────────────────────────
detect_cli_pkg_manager() {
    CLI_PKG=""
    # 阶段一：精确检测哪个包管理器实际持有 openclaw
    if command -v npm &>/dev/null 2>&1 && npm list -g openclaw --depth=0 &>/dev/null 2>&1; then
        CLI_PKG="npm"
    elif command -v pnpm &>/dev/null 2>&1 && pnpm list -g openclaw --depth=0 &>/dev/null 2>&1; then
        CLI_PKG="pnpm"
    elif command -v bun &>/dev/null 2>&1 && bun pm ls -g 2>/dev/null | grep -q "openclaw"; then
        CLI_PKG="bun"
    fi
    # 阶段二：精确检测失败，退而求其次用第一个可用的包管理器
    if [ -z "$CLI_PKG" ]; then
        for pm in npm pnpm bun; do
            command -v "$pm" &>/dev/null 2>&1 && CLI_PKG="$pm" && break
        done
    fi
}

# ════════════════════════════════════════════════════════════
# 步骤 1：CLI 内置卸载（优先路径）
# ════════════════════════════════════════════════════════════
step_cli_uninstall() {
    step "步骤 1/5  尝试 CLI 内置卸载命令"
    if ! command -v openclaw &>/dev/null 2>&1; then
        info "未找到 openclaw CLI，进入手动清理模式..."
        SKIPPED_ITEMS+=("CLI 内置卸载（CLI 不存在）")
        return
    fi

    info "检测到 openclaw CLI，执行内置卸载..."

    if [ "$DRY_RUN" = true ]; then
        info "  [DRY RUN] 将执行：openclaw uninstall --all --yes --non-interactive"
        REMOVED_ITEMS+=("openclaw CLI 内置卸载")
        return
    fi

    # run_logged：命令输出同步写入日志（不压制 stderr）
    if run_logged openclaw uninstall --all --yes --non-interactive; then
        ok "CLI 内置卸载完毕，继续清理残留..."
        REMOVED_ITEMS+=("openclaw CLI 内置卸载")
    else
        warn "CLI 内置卸载返回非零，切换手动清理模式继续..."
        WARNED_ITEMS+=("openclaw CLI 内置卸载（返回非零）")
    fi
}

# ════════════════════════════════════════════════════════════
# 步骤 2：系统服务清理
# ════════════════════════════════════════════════════════════
step_remove_service() {
    step "步骤 2/5  停止并移除系统服务"

    case "$OS" in
        linux)
            _remove_linux_services
            ;;
        macos)
            _remove_macos_services
            ;;
        wsl)
            # WSL 需同时处理两侧：
            # ① Windows 计划任务（始终处理）
            # ② Linux systemd 用户服务（仅当 WSL 中启用了 systemd 时）
            _remove_windows_tasks
            if systemctl --user status &>/dev/null 2>&1; then
                info "检测到 WSL 内 systemd 已启用，同步清理 Linux 用户服务..."
                _remove_linux_services
            fi
            ;;
        gitbash)
            _remove_windows_tasks
            ;;
        *)
            warn "未知操作系统（${OS}），跳过服务移除步骤"
            WARNED_ITEMS+=("系统服务（未知 OS：${OS}）")
            ;;
    esac
}

# ── Linux systemd 用户服务清理（支持多 profile）─────────────
_remove_linux_services() {
    local found=false
    local svc_dir="$HOME/.config/systemd/user"
    local units=("openclaw-gateway.service")

    # 扫描所有 profile 变体（如 openclaw-gateway-work.service）
    if [ -d "$svc_dir" ]; then
        while IFS= read -r -d '' f; do
            local base; base="$(basename "$f")"
            [[ "$base" == "openclaw-gateway.service" ]] && continue
            units+=("$base")
        done < <(find "$svc_dir" -maxdepth 1 \
            -name "openclaw-gateway*.service" -print0 2>/dev/null)
    fi

    for svc in "${units[@]}"; do
        local svc_file="${svc_dir}/${svc}"
        # 只处理确实存在的服务（运行中 / 已启用 / 有服务文件）
        if systemctl --user is-active  "$svc" &>/dev/null 2>&1 || \
           systemctl --user is-enabled "$svc" &>/dev/null 2>&1 || \
           [ -f "$svc_file" ]; then
            found=true
            info "处理服务：${svc}"
            if [ "$DRY_RUN" = true ]; then
                info "  [DRY RUN] 将执行：systemctl --user disable --now ${svc}"
                [ -f "$svc_file" ] && info "  [DRY RUN] 将删除：${svc_file}"
                REMOVED_ITEMS+=("systemd 服务：${svc}")
                continue
            fi
            systemctl --user disable --now "$svc" 2>/dev/null \
                && ok "  已停止并禁用：${svc}" \
                || warn "  停止/禁用失败（可能已停止）：${svc}"
            if [ -f "$svc_file" ]; then
                rm -f "$svc_file"
                ok "  已删除服务文件：${svc_file}"
                REMOVED_ITEMS+=("systemd 服务文件：${svc_file}")
            fi
        fi
    done

    if [ "$found" = true ]; then
        [ "$DRY_RUN" = false ] && {
            systemctl --user daemon-reload 2>/dev/null \
                && ok "systemd daemon 已重载" \
                || warn "daemon-reload 失败，可忽略"
        }
    else
        info "未发现任何 openclaw systemd 服务，跳过"
        SKIPPED_ITEMS+=("systemd 服务（未找到）")
    fi
}

# ── macOS launchd LaunchAgent 清理（支持多 profile 及旧版命名）
_remove_macos_services() {
    local launch_dir="$HOME/Library/LaunchAgents"
    local found=false
    local plists=()

    # 同时匹配新版 ai.openclaw.* 和旧版 com.openclaw.* 两种命名规范
    while IFS= read -r -d '' f; do
        plists+=("$f")
    done < <(find "$launch_dir" -maxdepth 1 \
        \( -name "ai.openclaw.*.plist" -o -name "com.openclaw.*.plist" \) \
        -print0 2>/dev/null)

    for plist in "${plists[@]}"; do
        found=true
        local label; label="$(basename "$plist" .plist)"
        info "处理 launchd 服务：${label}"
        if [ "$DRY_RUN" = true ]; then
            info "  [DRY RUN] 将执行：launchctl bootout gui/$UID/${label}"
            info "  [DRY RUN] 将删除：${plist}"
            REMOVED_ITEMS+=("launchd 服务：${label}")
            continue
        fi
        # bootout 是 macOS 10.10+ 推荐方式，失败时回退到 unload
        launchctl bootout "gui/$UID/${label}" 2>/dev/null \
            || launchctl unload "$plist" 2>/dev/null \
            || warn "  bootout/unload 失败（可能未运行）：${label}"
        rm -f "$plist"
        ok "  已删除 plist：${plist}"
        REMOVED_ITEMS+=("launchd plist：${plist}")
    done

    if [ "$found" = false ]; then
        info "未发现任何 openclaw launchd 服务，跳过"
        SKIPPED_ITEMS+=("launchd 服务（未找到）")
    fi
}

# ── Windows 计划任务清理（通过 WSL 或 Git Bash 调用 schtasks.exe）
_remove_windows_tasks() {
    if ! command -v schtasks.exe &>/dev/null 2>&1; then
        warn "未找到 schtasks.exe，跳过 Windows 计划任务清理"
        warn "请在 WSL 或 Git Bash 环境下运行，或手动删除任务"
        WARNED_ITEMS+=("Windows 计划任务（schtasks.exe 不可用）")
        return
    fi

    # 初始任务 + 扫描 profile 变体
    local tasks=("OpenClaw Gateway")
    while IFS= read -r line; do
        local tname; tname="$(echo "$line" | sed 's/TaskName:[[:space:]]*//')"
        [[ "$tname" =~ "OpenClaw Gateway" ]] || continue
        tasks+=("$tname")
    done < <(schtasks.exe /Query /FO LIST 2>/dev/null | grep "TaskName:" || true)

    # 去重后逐一删除
    local seen=()
    for t in "${tasks[@]}"; do
        [[ " ${seen[*]:-} " == *" $t "* ]] && continue
        seen+=("$t")
        info "删除计划任务：${t}"
        if [ "$DRY_RUN" = true ]; then
            info "  [DRY RUN] 将执行：schtasks.exe /Delete /F /TN \"${t}\""
            REMOVED_ITEMS+=("Windows 计划任务：${t}")
            continue
        fi
        if schtasks.exe /Delete /F /TN "${t}" 2>/dev/null; then
            ok "  已删除任务：${t}"
            REMOVED_ITEMS+=("Windows 计划任务：${t}")
        else
            warn "  任务不存在或删除失败：${t}"
            WARNED_ITEMS+=("Windows 计划任务：${t}")
        fi
    done

    # 删除 Windows 侧的 gateway.cmd（WSL 中需路径转换）
    local win_home
    win_home="$(cmd.exe /c echo %USERPROFILE% 2>/dev/null | tr -d '\r')" || win_home=""
    if [ -n "$win_home" ] && command -v wslpath &>/dev/null 2>&1; then
        local linux_home; linux_home="$(wslpath "$win_home" 2>/dev/null)" || linux_home=""
        if [ -n "$linux_home" ] && [ -f "${linux_home}/.openclaw/gateway.cmd" ]; then
            remove_path "${linux_home}/.openclaw/gateway.cmd" "gateway.cmd"
        fi
    fi
}

# ════════════════════════════════════════════════════════════
# 步骤 3：状态目录与配置文件
# ════════════════════════════════════════════════════════════
step_remove_state_dirs() {
    step "步骤 3/5  删除状态目录与配置文件"

    # 主状态目录（尊重自定义环境变量）
    local state_dir="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
    if [ -d "$state_dir" ]; then
        remove_path "$state_dir" "主状态目录 ${state_dir}"
    else
        info "主状态目录不存在，跳过：${state_dir}"
        SKIPPED_ITEMS+=("主状态目录（不存在）")
    fi

    # workspace（若主目录已删则此处自然跳过）
    local ws_dir="$HOME/.openclaw/workspace"
    if [ -d "$ws_dir" ]; then
        remove_path "$ws_dir" "workspace 目录"
    fi

    # profile 独立目录：~/.openclaw-<profile名>
    local found_profiles=false
    for dir in "$HOME"/.openclaw-*/; do
        [ -d "$dir" ] || continue
        found_profiles=true
        warn "发现 profile 目录：${dir}"
        remove_path "$dir" "profile 目录 ${dir}"
    done
    if [ "$found_profiles" = false ]; then
        info "未发现额外 profile 目录"
        SKIPPED_ITEMS+=("profile 目录（未找到）")
    fi

    # 自定义配置文件（若用户设置了 OPENCLAW_CONFIG_PATH）
    local custom_cfg="${OPENCLAW_CONFIG_PATH:-}"
    if [ -n "$custom_cfg" ] && [ -f "$custom_cfg" ]; then
        remove_path "$custom_cfg" "自定义配置 ${custom_cfg}"
    fi
}

# ════════════════════════════════════════════════════════════
# 步骤 4：卸载 CLI 本体
# ════════════════════════════════════════════════════════════
step_remove_cli() {
    step "步骤 4/5  卸载 CLI 本体"
    detect_cli_pkg_manager

    if [ -z "${CLI_PKG:-}" ]; then
        info "未检测到 npm / pnpm / bun，跳过 CLI 卸载"
        SKIPPED_ITEMS+=("CLI 卸载（包管理器未找到）")
        return
    fi

    info "使用 ${CLI_PKG} 卸载 openclaw..."

    if [ "$DRY_RUN" = true ]; then
        case "$CLI_PKG" in
            npm)  info "  [DRY RUN] 将执行：npm rm -g openclaw" ;;
            pnpm) info "  [DRY RUN] 将执行：pnpm remove -g openclaw" ;;
            bun)  info "  [DRY RUN] 将执行：bun remove -g openclaw" ;;
        esac
        REMOVED_ITEMS+=("CLI（${CLI_PKG}）")
        return
    fi

    # run_logged：输出同时写入日志（stderr 不压制）
    case "$CLI_PKG" in
        npm)
            if run_logged npm rm -g openclaw; then
                ok "npm 全局包已卸载"
                REMOVED_ITEMS+=("CLI（npm）")
            else
                warn "npm 卸载失败，请手动执行：npm rm -g openclaw"
                WARNED_ITEMS+=("CLI npm 卸载")
            fi
            ;;
        pnpm)
            if run_logged pnpm remove -g openclaw; then
                ok "pnpm 全局包已卸载"
                REMOVED_ITEMS+=("CLI（pnpm）")
            else
                warn "pnpm 卸载失败，请手动执行：pnpm remove -g openclaw"
                WARNED_ITEMS+=("CLI pnpm 卸载")
            fi
            ;;
        bun)
            if run_logged bun remove -g openclaw; then
                ok "bun 全局包已卸载"
                REMOVED_ITEMS+=("CLI（bun）")
            else
                warn "bun 卸载失败，请手动执行：bun remove -g openclaw"
                WARNED_ITEMS+=("CLI bun 卸载")
            fi
            ;;
    esac
}

# ════════════════════════════════════════════════════════════
# 步骤 5：macOS 桌面版
# ════════════════════════════════════════════════════════════
step_remove_macos_app() {
    step "步骤 5/5  清理 macOS 桌面版（如有）"
    if [ "$OS" != "macos" ]; then
        info "非 macOS 系统，跳过"
        SKIPPED_ITEMS+=("macOS 桌面版（非 macOS 系统）")
        return
    fi
    local app="/Applications/OpenClaw.app"
    if [ -d "$app" ]; then
        remove_path "$app" "macOS 桌面版 App"
    else
        info "未发现 macOS 桌面版，跳过"
        SKIPPED_ITEMS+=("macOS 桌面版（未找到）")
    fi
}

# ════════════════════════════════════════════════════════════
# 结尾摘要（终端 + 日志双写）
# ════════════════════════════════════════════════════════════
print_summary() {
    local r_count="${#REMOVED_ITEMS[@]}"
    local w_count="${#WARNED_ITEMS[@]}"
    local s_count="${#SKIPPED_ITEMS[@]}"
    local end_time; end_time="$(date '+%Y-%m-%d %H:%M:%S')"

    echo ""
    _log ""
    divider

    if [ "$DRY_RUN" = true ]; then
        printf "${BOLD}${YELLOW}  预览摘要（--dry-run，未实际执行）${NC}\n"
        _log "  预览摘要（--dry-run，未实际执行）"
    else
        printf "${BOLD}${GREEN}  卸载完成摘要${NC}\n"
        _log "  卸载完成摘要"
    fi
    divider

    # ── 已处理项目 ────────────────────────────────────────────
    if [ "$r_count" -gt 0 ]; then
        printf "${GREEN}已处理 %d 项：${NC}\n" "$r_count"
        _log "已处理 ${r_count} 项："
        for item in "${REMOVED_ITEMS[@]}"; do
            printf "  ${GREEN}✓${NC} %s\n" "$item"
            _log "  ✓ $item"
        done
    fi

    # ── 有警告项目 ────────────────────────────────────────────
    if [ "$w_count" -gt 0 ]; then
        echo ""
        _log ""
        printf "${YELLOW}有警告 %d 项（可能需要手动处理）：${NC}\n" "$w_count"
        _log "有警告 ${w_count} 项（可能需要手动处理）："
        for item in "${WARNED_ITEMS[@]}"; do
            printf "  ${YELLOW}!${NC} %s\n" "$item"
            _log "  ! $item"
        done
    fi

    # ── 已跳过项目 ────────────────────────────────────────────
    if [ "$s_count" -gt 0 ]; then
        echo ""
        _log ""
        printf "${CYAN}已跳过 %d 项（原本不存在或不适用）：${NC}\n" "$s_count"
        _log "已跳过 ${s_count} 项（原本不存在或不适用）："
        for item in "${SKIPPED_ITEMS[@]}"; do
            printf "  ${CYAN}-${NC} %s\n" "$item"
            _log "  - $item"
        done
    fi

    # ── 结论 ──────────────────────────────────────────────────
    echo ""
    _log ""
    if [ "$DRY_RUN" = true ]; then
        printf "${YELLOW}以上为预览结果。去掉 --dry-run 参数即可正式执行。${NC}\n"
        _log "以上为预览结果。去掉 --dry-run 参数即可正式执行。"
    else
        printf "${GREEN}${BOLD}  OpenClaw 已从本机彻底移除。${NC}\n"
        _log "  OpenClaw 已从本机彻底移除。"
    fi
    divider

    # ── 日志页脚 ──────────────────────────────────────────────
    _log ""
    _log "脚本结束时间：${end_time}"
    _log "════════════════════════════════════════════════════"

    # 告知用户日志位置
    printf "\n${CYAN}运行日志已保存至：${NC}${BOLD}%s${NC}\n\n" "$LOG_FILE"
}

# ════════════════════════════════════════════════════════════
# 主流程
# ════════════════════════════════════════════════════════════
main() {
    local start_time; start_time="$(date '+%Y-%m-%d %H:%M:%S')"

    # ── 日志页眉 ──────────────────────────────────────────────
    _log "════════════════════════════════════════════════════"
    _log "OpenClaw 卸载日志"
    _log "脚本启动时间：${start_time}"
    _log "操作用户：${USER:-$(id -un 2>/dev/null || echo unknown)}"
    _log "用户主目录：${HOME:-unknown}"
    [ "$DRY_RUN" = true ] && _log "运行模式：预览（--dry-run）" || _log "运行模式：正式执行"
    _log "════════════════════════════════════════════════════"

    # ── 欢迎信息 ──────────────────────────────────────────────
    divider
    printf "${BOLD}${CYAN}  OpenClaw 一键卸载脚本${NC}\n"
    printf "  参考文档：https://docs.openclaw.ai/install/uninstall\n"
    _log "  OpenClaw 一键卸载脚本"
    [ "$DRY_RUN" = true ] && {
        printf "${YELLOW}  模式：预览（--dry-run，不实际删除）${NC}\n"
        _log "  模式：预览（--dry-run，不实际删除）"
    }
    divider

    detect_os
    check_not_root
    info "当前操作系统：${OS}"
    info "当前用户主目录：${HOME}"
    echo ""

    # ── 安全确认 ──────────────────────────────────────────────
    if [ "$DRY_RUN" = false ]; then
        printf "${YELLOW}警告：${NC}本脚本将完全卸载 OpenClaw，\n"
        printf "      包括网关服务、CLI 工具及所有配置文件，${RED}操作不可撤销。${NC}\n\n"
        _log "[WARN]  本脚本将完全卸载 OpenClaw（网关服务 / CLI / 配置文件），操作不可撤销。"
        if ! confirm "确认要卸载 OpenClaw 吗？"; then
            _log "用户取消，未做任何更改。"
            echo "已取消，未做任何更改。"
            exit 0
        fi
        _log "用户已确认，开始卸载。"
    fi
    echo ""

    step_cli_uninstall
    step_remove_service
    step_remove_state_dirs
    step_remove_cli
    step_remove_macos_app

    print_summary
}

main "$@"
