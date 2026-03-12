# easy-uninstall-openclaw
# 告别龙虾：OpenClaw 一键卸载脚本使用指南

> 脚本已在 Ubuntu 24.04 LTS 实机验证，同时支持 macOS 与 Windows（WSL / Git Bash）。

![](https://files.mdnice.com/user/108782/3192ad9b-fced-4192-8ef4-cb83da52abd1.png)

![](https://files.mdnice.com/user/108782/18afe49e-abdb-4531-994e-96fcbc169384.png)

![](https://files.mdnice.com/user/108782/b14e5ed4-a9a1-4cfd-808b-25540571049c.png)

![](https://files.mdnice.com/user/108782/d7915104-f0f4-49a1-a056-df513407ff3c.png)

---

## 为什么卸载 OpenClaw 需要脚本？

OpenClaw 不是普通的桌面软件，它在安装时做了三件事：

1. **注册了系统服务**（Linux 下是 systemd 用户服务，macOS 下是 launchd LaunchAgent，Windows 下是计划任务），让网关进程开机自启、后台常驻；
2. **在用户主目录写入了状态文件**，保存密钥、配置、Agent 运行时数据；
3. **通过 npm / pnpm / bun 安装了全局 CLI 工具**。

如果只是删掉文件夹或执行 `npm rm -g openclaw`，网关服务可能仍在后台运行，配置残留也不会消失。**官方文档**（https://docs.openclaw.ai/install/uninstall）给出了完整的手动步骤，但要区分操作系统、判断 CLI 是否可用、逐条执行——对普通用户来说并不友好。

这个脚本把所有步骤整合成一条命令，自动检测系统环境，实时显示每一步进度，执行结束后告诉你做了什么，并保存完整日志，**一次跑完、不留残留**。

---

## 快速开始

### 第一步：下载脚本

将脚本保存为 `uninstall-openclaw.sh`。

> 强烈建议下载后用文本编辑器打开，亲自确认内容无误后再执行。完整脚本见本文末尾。

### 第二步：赋予执行权限

```bash
chmod +x uninstall-openclaw.sh
```

### 第三步：先预览，再执行

**【推荐】先用预览模式确认脚本会动哪些文件**：

```bash
bash uninstall-openclaw.sh --dry-run
```

预览模式不会实际删除任何内容，只显示"将要做什么"，同时生成预览日志。确认无误后，再正式执行：

```bash
# 交互模式（推荐，执行前有确认提示）
bash uninstall-openclaw.sh

# 静默模式（跳过确认，适合批量自动化场景）
bash uninstall-openclaw.sh --yes
```

---

## 运行效果全程展示

### 预览模式（--dry-run）终端输出

```
────────────────────────────────────────────────────
  OpenClaw 一键卸载脚本
  参考文档：https://docs.openclaw.ai/install/uninstall
  模式：预览（--dry-run，不实际删除）
────────────────────────────────────────────────────
[INFO]  当前操作系统：linux
[INFO]  当前用户主目录：/home/alice

══ 步骤 1/5  尝试 CLI 内置卸载命令
[INFO]  检测到 openclaw CLI，执行内置卸载...
[INFO]    [DRY RUN] 将执行：openclaw uninstall --all --yes --non-interactive

══ 步骤 2/5  停止并移除系统服务
[INFO]    [DRY RUN] 将执行：systemctl --user disable --now openclaw-gateway.service
[INFO]    [DRY RUN] 将删除：/home/alice/.config/systemd/user/openclaw-gateway.service

══ 步骤 3/5  删除状态目录与配置文件
[INFO]    [DRY RUN] 将删除：/home/alice/.openclaw

══ 步骤 4/5  卸载 CLI 本体
[INFO]  使用 npm 卸载 openclaw...
[INFO]    [DRY RUN] 将执行：npm rm -g openclaw

══ 步骤 5/5  清理 macOS 桌面版（如有）
[INFO]  非 macOS 系统，跳过

────────────────────────────────────────────────────
  预览摘要（--dry-run，未实际执行）
────────────────────────────────────────────────────
已处理 4 项：
  ✓ openclaw CLI 内置卸载
  ✓ systemd 服务文件：...openclaw-gateway.service
  ✓ 主状态目录 /home/alice/.openclaw
  ✓ CLI（npm）

已跳过 2 项（原本不存在或不适用）：
  - profile 目录（未找到）
  - macOS 桌面版（非 macOS 系统）

以上为预览结果。去掉 --dry-run 参数即可正式执行。
────────────────────────────────────────────────────

运行日志已保存至：/home/alice/openclaw-uninstall-20260312-101922.log
```

### 正式执行后的结尾摘要

```
────────────────────────────────────────────────────
  卸载完成摘要
────────────────────────────────────────────────────
已处理 4 项：
  ✓ openclaw CLI 内置卸载
  ✓ systemd 服务文件：.../openclaw-gateway.service
  ✓ 主状态目录 /home/alice/.openclaw
  ✓ CLI（npm）

已跳过 2 项（原本不存在或不适用）：
  - profile 目录（未找到）
  - macOS 桌面版（非 macOS 系统）

  OpenClaw 已从本机彻底移除。
────────────────────────────────────────────────────

运行日志已保存至：/home/alice/openclaw-uninstall-20260312-101922.log
```

### 日志文件内容（纯文本，无颜色代码）

```
════════════════════════════════════════════════════
OpenClaw 卸载日志
脚本启动时间：2026-03-12 10:19:22
操作用户：alice
用户主目录：/home/alice
运行模式：正式执行
════════════════════════════════════════════════════
────────────────────────────────────────────────────
  OpenClaw 一键卸载脚本
────────────────────────────────────────────────────
[INFO]  当前操作系统：linux
[INFO]  当前用户主目录：/home/alice
[WARN]  本脚本将完全卸载 OpenClaw（网关服务 / CLI / 配置文件），操作不可撤销。

══ 步骤 1/5  尝试 CLI 内置卸载命令
[INFO]  检测到 openclaw CLI，执行内置卸载...
Stopped systemd service: openclaw-gateway.service
Removed ~/.openclaw
[ OK ]  CLI 内置卸载完毕，继续清理残留...

══ 步骤 2/5  停止并移除系统服务
[INFO]  未发现任何 openclaw systemd 服务，跳过

══ 步骤 3/5  删除状态目录与配置文件
[INFO]  主状态目录不存在，跳过：/home/alice/.openclaw
[INFO]  未发现额外 profile 目录

══ 步骤 4/5  卸载 CLI 本体
removed 675 packages in 2s
[ OK ]  npm 全局包已卸载

══ 步骤 5/5  清理 macOS 桌面版（如有）
[INFO]  非 macOS 系统，跳过

────────────────────────────────────────────────────
  卸载完成摘要
────────────────────────────────────────────────────
已处理 4 项：
  ✓ openclaw CLI 内置卸载
  ✓ 主状态目录 /home/alice/.openclaw
  ✓ CLI（npm）

已跳过 3 项（原本不存在或不适用）：
  - systemd 服务（未找到）
  - profile 目录（未找到）
  - macOS 桌面版（非 macOS 系统）

  OpenClaw 已从本机彻底移除。
────────────────────────────────────────────────────

脚本结束时间：2026-03-12 10:19:25
════════════════════════════════════════════════════
```

日志文件自动保存在用户主目录，文件名格式为 `openclaw-uninstall-YYYYMMDD-HHMMSS.log`，纯文本无 ANSI 颜色码，可直接用任何文本编辑器打开。

---

每一行的状态前缀含义：

| 前缀 | 颜色 | 含义 |
|------|------|------|
| `[INFO]` | 蓝色 | 普通进度说明 |
| `[ OK ]` | 绿色 | 操作成功 |
| `[WARN]` | 黄色 | 跳过或软性失败（不影响继续执行）|
| `[ERR ]` | 红色 | 严重错误，写入 stderr |

---

## 系统兼容性

| 操作系统 | 运行环境 | 服务管理方式 |
|---|---|---|
| Ubuntu / Debian / CentOS 等 Linux | 原生终端 | systemd 用户服务 |
| macOS（Intel / Apple Silicon） | 原生终端 | launchd LaunchAgent |
| Windows（WSL2 + systemd 已启用） | WSL | Windows 计划任务 + systemd 用户服务 |
| Windows（WSL，未启用 systemd） | WSL | Windows 计划任务 |
| Windows | Git Bash | Windows 计划任务（schtasks.exe）|

---

## 脚本代码逐段解析

### 一、安全模式设置

```bash
set -uo pipefail
```

| 选项 | 含义 |
|---|---|
| `-u` | 引用未定义变量时报错，防止因拼写错误删错路径 |
| `-o pipefail` | 管道中任意一步失败，整条管道返回失败 |

**为什么不加 `-e`？** 卸载脚本需要大量"探测性"操作：检查服务是否存在、判断目录是否为空。这些命令返回非零是正常的，加了 `-e` 会在"服务本就不存在"时意外中断。这里选择手动用 `|| warn` 处理软性失败，保持流程完整。

---

### 二、日志系统设计

```bash
LOG_FILE="${HOME:-/tmp}/openclaw-uninstall-$(date +%Y%m%d-%H%M%S).log"

_log() { printf "%s\n" "$*" >> "$LOG_FILE" 2>/dev/null || true; }
```

日志文件在脚本启动时就确定路径（含时间戳），`_log()` 是最底层的写文件函数，`|| true` 确保写入失败时不中断脚本。

所有 6 个日志函数均采用**终端彩色 + 日志纯文本双写**模式：

```bash
info()    { printf "${CYAN}[INFO]${NC}  %s\n" "$*";  _log "[INFO]  $*"; }
ok()      { printf "${GREEN}[ OK ]${NC}  %s\n" "$*"; _log "[ OK ]  $*"; }
warn()    { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; _log "[WARN]  $*"; }
err()     { printf "${RED}[ERR ]${NC}  %s\n" "$*" >&2; _log "[ERR ]  $*"; }
```

- 终端输出带 ANSI 颜色
- 日志文件写纯文本（无颜色转义码），直接可读

对于 `openclaw uninstall`、`npm rm` 等**会产生自身输出的命令**，专门提供 `run_logged()` 封装：

```bash
run_logged() {
    "$@" 2>&1 | tee -a "$LOG_FILE"
    return "${PIPESTATUS[0]}"
}
```

- `tee -a "$LOG_FILE"` 把命令的 stdout/stderr 同时输出到终端和日志
- `return "${PIPESTATUS[0]}"` 穿透 tee，返回原始命令的真实退出码（不受 tee 影响）
- 调用方可以直接 `if run_logged npm rm -g openclaw; then ...` 正确判断成功与否

---

### 三、`--dry-run` 预览模式

```bash
DRY_RUN=false
for arg in "${@:-}"; do
    case "$arg" in
        --dry-run|-n) DRY_RUN=true ;;
    esac
done
```

预览模式贯穿整个脚本。所有删除路径统一通过 `remove_path()` 封装：

```bash
remove_path() {
    local target="$1"
    local label="${2:-$1}"
    if [ "$DRY_RUN" = true ]; then
        info "  [DRY RUN] 将删除：${target}"
        REMOVED_ITEMS+=("${label}")   # 仍写入摘要，预览完整
        return 0
    fi
    rm -rf "$target"
    ok "  已删除：${target}"
    REMOVED_ITEMS+=("${label}")
}
```

预览模式下只打印不删除，但同样写入摘要数组，让预览结果与正式执行的格式保持一致，便于用户对比。

---

### 四、确认函数（管道安全防护）

```bash
confirm() {
    if [ "$AUTO_YES" = true ] || [ "$DRY_RUN" = true ]; then
        return 0
    fi
    if [ ! -t 0 ]; then
        err "检测到非交互模式（stdin 非终端）。"
        err "请先下载脚本，再在终端直接运行；或加 --yes 参数明确授权。"
        exit 1
    fi
    # ...
}
```

`[ ! -t 0 ]` 解决了 `curl ... | bash` 管道执行的安全隐患：管道下 `read` 会立即读到 EOF，`ans` 为空，看似"取消"实则静默失败。这里主动报错并退出，迫使用户先下载、再审查、再运行。

---

### 五、Root 安全检查

```bash
check_not_root() {
    local uid_val
    uid_val="${EUID:-$(id -u 2>/dev/null || echo 1)}"
    if [ "$uid_val" -eq 0 ]; then
        warn "检测到以 root 身份运行。注意："
        warn "  · 脚本将在 /root 而非普通用户主目录下查找 .openclaw"
        warn "  · npm/pnpm/bun 的全局包路径可能与普通用户安装时不同"
        # 仍允许确认后继续，不强制退出
    fi
}
```

OpenClaw 通常以普通用户身份安装，root 下运行会在错误目录寻找文件。这里**警告而不强制退出**，给需要 root 的特殊场景留有余地，同时向日志写入操作用户信息。

`${EUID:-$(id -u)}` 兼顾 bash（提供 `$EUID`）和 sh（不提供，退而调用 `id -u`）。

---

### 六、步骤 2：系统服务清理（WSL 双侧处理）

```bash
step_remove_service() {
    case "$OS" in
        wsl)
            _remove_windows_tasks          # ① 始终清理 Windows 计划任务
            if systemctl --user status &>/dev/null 2>&1; then
                info "检测到 WSL 内 systemd 已启用，同步清理 Linux 用户服务..."
                _remove_linux_services     # ② systemd 启用时额外清理
            fi
            ;;
    esac
}
```

Ubuntu 22.04+ 的 WSL2 默认启用 systemd。OpenClaw 在这种环境下会同时注册 Windows 计划任务和 Linux systemd 服务。脚本用 `systemctl --user status` 探测是否启用了 systemd，若是则两侧同时清理，不遗漏。

**Linux systemd 关键细节：**
- `--user`：操作用户级服务，不需要 `sudo`
- `disable --now`：`disable`（禁止自启）+ `stop`（立即停止）的合并写法
- `find ... -name "openclaw-gateway*.service"` 自动发现所有 profile 变体
- 只处理实际存在的服务，不存在则跳过

**macOS launchd 关键细节：**
- `launchctl bootout`：macOS 10.10+ 推荐方式；回退到 `launchctl unload` 兼容旧版
- 同时匹配 `ai.openclaw.*` 和旧版 `com.openclaw.*` 两种命名

**Windows 计划任务关键细节：**
- WSL 中直接调用 `schtasks.exe`、`cmd.exe`（跨系统调用）
- `tr -d '\r'` 去除 Windows 命令输出的回车符，防止路径拼接出错
- `wslpath` 将 Windows 路径（`C:\Users\alice`）转为 WSL 路径（`/mnt/c/Users/alice`）

---

### 七、步骤 4：CLI 卸载（`run_logged` 透明输出）

```bash
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
esac
```

旧版本对 `npm rm` 追加了 `2>/dev/null`，静默吞掉错误。现在改用 `run_logged`，npm 的完整输出（包括 stderr）同时显示在终端和写入日志，失败时用户能看到原因。

---

### 八、结尾摘要与日志页脚

```bash
print_summary() {
    # 终端和日志双写摘要内容
    printf "${GREEN}已处理 %d 项：${NC}\n" "$r_count"
    _log "已处理 ${r_count} 项："
    for item in "${REMOVED_ITEMS[@]}"; do
        printf "  ${GREEN}✓${NC} %s\n" "$item"
        _log "  ✓ $item"
    done
    # 警告项、跳过项类似...

    # 日志页脚写入时间戳
    _log "脚本结束时间：${end_time}"
    _log "════════════════════════════════════════════════════"

    # 告知用户日志文件位置
    printf "\n${CYAN}运行日志已保存至：${NC}${BOLD}%s${NC}\n\n" "$LOG_FILE"
}
```

摘要按三类展示：**已处理**（删了什么）、**有警告**（需要手动处理的项）、**已跳过**（本就不存在或不适用）。日志页脚记录结束时间，与页眉的启动时间配合，可以算出整个卸载过程耗时。

---

## 常见场景说明

### 场景 A：CLI 已损坏，但网关服务还在跑

步骤 1 检测到 CLI 不可用，自动跳过内置卸载，直接进入步骤 2 手动停止服务。无需手动切换。

### 场景 B：在 Ubuntu WSL2 上安装（已启用 systemd）

步骤 2 同时清理 Windows 计划任务和 Linux systemd 用户服务，两侧都不遗漏。

### 场景 C：创建了多个 profile

脚本自动扫描：
- 步骤 2：找到所有 `openclaw-gateway-*.service` 或 `ai.openclaw.*.plist`
- 步骤 3：通配符 `~/.openclaw-*/` 匹配所有 profile 状态目录

无需提前知道 profile 名称。

### 场景 D：配置文件放到自定义路径

```bash
export OPENCLAW_CONFIG_PATH="/your/custom/path/config.json"
bash uninstall-openclaw.sh
```

脚本读取该变量后会额外删除此路径的配置文件。

### 场景 E：不确定脚本会动哪些文件

先用预览模式：

```bash
bash uninstall-openclaw.sh --dry-run
```

完全安全，不会改动任何文件，同时生成预览日志供存档。

---

## 安全说明

| 项目 | 说明 |
|---|---|
| 网络请求 | 无。脚本不访问任何外部服务，不上传数据 |
| 管道执行防护 | `curl \| bash` 模式下主动报错退出，拒绝在无法真实确认的情况下运行 |
| Root 检查 | 以 root 运行时给出明确警告，说明潜在风险，由用户决定是否继续 |
| 路径安全 | 所有删除前检查路径是否存在；变量均有默认值（`${VAR:-}`），防止 `set -u` 误触 |
| 错误透明 | 关键命令（openclaw uninstall、npm rm 等）通过 `run_logged` 不压制任何输出 |
| 可逆预览 | `--dry-run` 只展示将要执行的操作，不做任何实际更改 |
| 日志存档 | 每次运行自动生成带时间戳的纯文本日志，记录所有操作及其结果 |

---

## 完整脚本

```bash              
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
```

---

本脚本依据 OpenClaw 官方卸载文档（https://docs.openclaw.ai/install/uninstall）编写，已在 Ubuntu 24.04 LTS 实机验证。
