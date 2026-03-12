# 告别龙虾：OpenClaw 一键卸载脚本使用指南

> 脚本已在 Ubuntu 24.04 LTS 实机验证，同时支持 macOS 与 Windows（WSL / Git Bash）。

![](https://files.mdnice.com/user/108782/3192ad9b-fced-4192-8ef4-cb83da52abd1.png)

![](https://files.mdnice.com/user/108782/18afe49e-abdb-4531-994e-96fcbc169384.png)

![](https://files.mdnice.com/user/108782/b14e5ed4-a9a1-4cfd-808b-25540571049c.png)

![](https://files.mdnice.com/user/108782/d7915104-f0f4-49a1-a056-df513407ff3c.png)

---

OpenClaw 不像普通软件，拖进废纸篓就算完事。它装的时候在系统里留了三样东西：**后台常驻的网关服务**、**用户主目录里的配置和状态文件**、**通过包管理器安装的全局 CLI 工具**。三样东西要分别清理，漏掉任何一样，都算没卸干净。

官方给了手动卸载文档，但步骤繁琐，还要根据操作系统分支走不同的路。这个脚本把所有路径都整合进来，自动识别系统环境，**一条命令跑完，结束后告诉你做了什么，并保存运行日志**。

---

## 脚本地址

**GitHub 仓库：https://github.com/inwpu/easy-uninstall-openclaw**

---

## 使用方法

### 第一步：下载脚本

```bash
curl -fsSL https://raw.githubusercontent.com/inwpu/easy-uninstall-openclaw/main/uninstall-openclaw.sh -o uninstall-openclaw.sh
```

> 强烈建议下载后用文本编辑器打开，亲眼确认内容后再执行。

### 第二步：授予执行权限

```bash
chmod +x uninstall-openclaw.sh
```

### 第三步：先预览，再执行

这是最重要的一步。脚本支持 `--dry-run` 预览模式，**不会实际删除任何内容**，只告诉你"将要做什么"：

```bash
bash uninstall-openclaw.sh --dry-run
```

确认无误后，再正式执行：

```bash
# 交互模式（推荐）——执行前有确认提示
bash uninstall-openclaw.sh

# 静默模式——跳过确认，适合批量自动化
bash uninstall-openclaw.sh --yes
```

---

## 支持的操作系统

| 系统 | 运行环境 | 服务清理方式 |
|---|---|---|
| Ubuntu / Debian / CentOS 等 | 原生终端 | systemd 用户服务 |
| macOS（Intel / Apple Silicon） | 原生终端 | launchd LaunchAgent |
| Windows（WSL2 + systemd） | WSL | Windows 计划任务 + systemd 用户服务 |
| Windows（WSL，未启用 systemd） | WSL | Windows 计划任务 |
| Windows | Git Bash | Windows 计划任务 |

---

## 运行过程实录

脚本把卸载过程分为 **5 个步骤**，每一步实时输出进度。

```
────────────────────────────────────────────────────
  OpenClaw 一键卸载脚本
  参考文档：https://docs.openclaw.ai/install/uninstall
────────────────────────────────────────────────────
[INFO]  当前操作系统：linux
[INFO]  当前用户主目录：/home/alice

警告：本脚本将完全卸载 OpenClaw，
      包括网关服务、CLI 工具及所有配置文件，操作不可撤销。

确认要卸载 OpenClaw 吗？ [y/N] y

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
[INFO]  使用 npm 卸载 openclaw...
removed 675 packages in 2s
[ OK ]  npm 全局包已卸载

══ 步骤 5/5  清理 macOS 桌面版（如有）
[INFO]  非 macOS 系统，跳过
```

### 结束时的摘要

卸载完成后，脚本会输出本次操作的完整摘要，分三类清单告诉你都发生了什么：

```
────────────────────────────────────────────────────
  卸载完成摘要
────────────────────────────────────────────────────
已处理 3 项：
  ✓ openclaw CLI 内置卸载
  ✓ 主状态目录 /home/alice/.openclaw
  ✓ CLI（npm）

已跳过 4 项（原本不存在或不适用）：
  - systemd 服务（未找到）
  - profile 目录（未找到）
  - macOS 桌面版（非 macOS 系统）
  - workspace 目录（未找到）

  OpenClaw 已从本机彻底移除。
────────────────────────────────────────────────────

运行日志已保存至：/home/alice/openclaw-uninstall-20260312-101922.log
```

**三类清单的含义：**
- `✓ 已处理`：实际执行了删除/停止操作的项目
- `! 有警告`：操作失败，可能需要手动处理
- `- 已跳过`：本就不存在或不适用于当前系统，属于正常情况

---

## 运行日志

每次执行（包括 `--dry-run` 预览）都会在用户主目录自动生成一份日志：

```
/home/alice/openclaw-uninstall-20260312-101922.log
```

日志为纯文本格式，无 ANSI 颜色代码，可直接用任何编辑器打开。内容包含：

```
════════════════════════════════════════════════════
OpenClaw 卸载日志
脚本启动时间：2026-03-12 10:19:22
操作用户：alice
用户主目录：/home/alice
运行模式：正式执行
════════════════════════════════════════════════════
[INFO]  当前操作系统：linux
...（完整步骤输出）...
  ✓ openclaw CLI 内置卸载
  ✓ 主状态目录 /home/alice/.openclaw
  ✓ CLI（npm）

  OpenClaw 已从本机彻底移除。
────────────────────────────────────────────────────
脚本结束时间：2026-03-12 10:19:25
════════════════════════════════════════════════════
```

日志名称包含执行时间戳，多次执行不会互相覆盖，方便留存备查。

---

## 几个常见场景

**CLI 已损坏，但服务还在跑**
步骤 1 检测到 CLI 不可用，自动切换手动清理模式，步骤 2 接管停止服务。不需要手动操作。

**装了多个 profile**
脚本自动扫描所有 `openclaw-gateway-*.service` 服务文件和 `~/.openclaw-*` 目录，每个 profile 都不遗漏，不需要知道 profile 名称。

**在 Ubuntu WSL2 上使用（已启用 systemd）**
脚本同时处理 Windows 计划任务和 WSL 内的 Linux systemd 用户服务，两侧都清理。

**配置文件放在了自定义路径**

```bash
export OPENCLAW_CONFIG_PATH="/your/path/config.json"
bash uninstall-openclaw.sh
```

脚本读取该环境变量后会额外删除这个文件。

**不放心，想先确认**

```bash
bash uninstall-openclaw.sh --dry-run
```

完全安全，不改动任何文件。

---

## 安全说明

在把一个卸载脚本分享出去之前，有几件事必须说清楚：

**脚本不包含任何网络请求。** 它不访问外部服务，不上传任何数据，所有操作都在本地完成。

**拒绝 `curl | bash` 管道执行。** 很多脚本用 `curl https://... | bash` 一行命令安装或卸载，看上去方便，但这种方式下 `read` 命令会立即读到 EOF，无法真正取得用户确认，存在安全隐患。这个脚本检测到管道场景会主动报错退出，要求用户先下载、再审查、再运行。

**以 root 运行时给出明确警告。** OpenClaw 通常以普通用户身份安装，root 下运行会在错误的目录（`/root`）查找文件。脚本检测到 root 会列出潜在风险，由用户决定是否继续，不强制退出。

**失败不静默。** 关键命令（`openclaw uninstall`、`npm rm` 等）的输出完整保留，失败时用户能看到原因，同时写入日志，方便排查。

---

## 代码解析

下面对脚本的核心设计做逐段说明，方便有 Shell 基础的读者审阅。

### 安全模式

```bash
set -uo pipefail
```

- `-u`：引用未定义变量立即报错，防止因拼写错误操作了错误的路径
- `-o pipefail`：管道中任意一步失败，整条管道返回非零
- 故意不加 `-e`：卸载脚本需要大量探测性操作（检查服务是否存在等），这些命令返回非零是正常的，加了 `-e` 会在"服务本就不存在"时意外中断

### 日志系统：终端彩色 + 文件纯文本双写

```bash
LOG_FILE="${HOME:-/tmp}/openclaw-uninstall-$(date +%Y%m%d-%H%M%S).log"
_log() { printf "%s\n" "$*" >> "$LOG_FILE" 2>/dev/null || true; }

info() { printf "${CYAN}[INFO]${NC}  %s\n" "$*"; _log "[INFO]  $*"; }
ok()   { printf "${GREEN}[ OK ]${NC}  %s\n" "$*"; _log "[ OK ]  $*"; }
warn() { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; _log "[WARN]  $*"; }
err()  { printf "${RED}[ERR ]${NC}  %s\n" "$*" >&2; _log "[ERR ]  $*"; }
```

每个日志函数做两件事：终端用 `printf` 输出带 ANSI 颜色的文本，同时调用 `_log` 把纯文本追加写入日志文件。日志文件里没有颜色转义码，打开就能直接阅读。`|| true` 保证写入失败（磁盘满、权限问题）不中断脚本。

### `run_logged()`：命令输出同步写日志

```bash
run_logged() {
    "$@" 2>&1 | tee -a "$LOG_FILE"
    return "${PIPESTATUS[0]}"
}
```

`openclaw uninstall`、`npm rm` 这类命令会产生自己的输出。用 `tee -a "$LOG_FILE"` 把它们的 stdout 和 stderr 同时送到终端和日志文件。`return "${PIPESTATUS[0]}"` 穿透 tee，返回原始命令的真实退出码，让调用方的 `if run_logged npm rm ...; then` 能正确判断成功与否。

### 管道执行防护

```bash
confirm() {
    if [ ! -t 0 ]; then
        err "检测到非交互模式（stdin 非终端）。"
        err "请先下载脚本，再在终端直接运行；或加 --yes 参数明确授权。"
        exit 1
    fi
    # ...
}
```

`[ ! -t 0 ]` 检测标准输入是否为终端。`curl | bash` 管道执行时 stdin 是管道而不是终端，脚本检测到这一点后直接退出，而不是让 `read` 静默读到空字符串然后默认取消。

### `--dry-run` 预览模式

所有删除操作都通过 `remove_path()` 统一封装：

```bash
remove_path() {
    local target="$1" label="${2:-$1}"
    if [ "$DRY_RUN" = true ]; then
        info "  [DRY RUN] 将删除：${target}"
        REMOVED_ITEMS+=("${label}")    # 仍记入摘要，让预览结果完整可读
        return 0
    fi
    rm -rf "$target"
    ok "  已删除：${target}"
    REMOVED_ITEMS+=("${label}")
}
```

预览模式下只打印路径、不删除文件，但同样写入摘要数组，最终摘要格式与正式执行完全一致，便于对比。

### WSL 双侧服务清理

```bash
wsl)
    _remove_windows_tasks       # ① 始终处理 Windows 计划任务
    if systemctl --user status &>/dev/null 2>&1; then
        info "检测到 WSL 内 systemd 已启用，同步清理 Linux 用户服务..."
        _remove_linux_services  # ② systemd 可用时额外处理
    fi
    ;;
```

Ubuntu 22.04+ 的 WSL2 默认启用 systemd。在这种环境下，OpenClaw 会同时注册 Windows 计划任务（用于开机自启）和 Linux systemd 用户服务（管理实际进程）。脚本用 `systemctl --user status` 探测 systemd 是否可用，若是则两侧同时清理，不遗漏。

### 结尾摘要：三个追踪数组

```bash
REMOVED_ITEMS=()   # 已成功处理的项目
SKIPPED_ITEMS=()   # 跳过的项目（不存在或不适用）
WARNED_ITEMS=()    # 有警告的项目（可能需要手动处理）
```

整个脚本执行过程中，每个操作的结果都追加写入对应数组。执行结束后 `print_summary()` 读取这三个数组，分类展示，让用户一眼看清本次卸载的全貌。

---

## 项目地址

脚本开源在 GitHub，欢迎查看完整代码、提 Issue 或 PR：

**https://github.com/inwpu/easy-uninstall-openclaw**

---

参考：OpenClaw 官方卸载文档 https://docs.openclaw.ai/install/uninstall


