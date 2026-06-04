<h1 align="center">洁癖.skill</h1>

<p align="center">让 AI Agent 在一个干净、可解释、可回收的本地环境里工作。</p>

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="license">
  <img src="https://img.shields.io/badge/CC%20Switch-ready-success.svg" alt="CC Switch ready">
  <img src="https://img.shields.io/badge/layout-skills%2Ftidy--skill-success.svg" alt="skill layout">
  <img src="https://img.shields.io/badge/runtime-Python%20%2B%20PowerShell-5391FE.svg" alt="Python and PowerShell">
  <img src="https://img.shields.io/badge/network-offline-lightgrey.svg" alt="offline">
</p>

<p align="center">
  <a href="README.en.md">English</a>
</p>

---

## 一句话

洁癖.skill 不是 Markdown 删除器，也不只是仓库清理工具。它是一套本地 Agent 环境洁癖规则和审计工具，让 Agent 的文件、缓存、虚拟化环境和模型存储都能被解释、被归位、被安全回收。

---

## 三层洁癖模型

| 层级 | 管什么 | 典型问题 | 工具 |
|---|---|---|---|
| 仓库层 | Agent 产物 | `plan.md`、`todo.md`、`final_report.md` 堆在根目录 | `audit_agent_artifacts.py`、`score_repo_hygiene.py` |
| 工作区层 | 开发缓存 | 多个项目残留 `node_modules`、`.venv`、`target`、构建缓存 | `audit-workspace-hygiene.ps1` |
| 本机层 | 本地开发环境 | WSL2/Docker VHDX 膨胀、包管理器缓存、模型缓存、Agent/IDE 状态散落 | `audit-dev-environment.ps1` |

---

## Before / After

| Before | After |
|---|---|
| Agent 把计划、总结、报告都丢进项目根目录 | 计划默认留在聊天里，报告进 `.agent_reports/`，临时文件进 `.agent_tmp/` |
| C 盘里到处是 npm、pip、uv、Go、Rust、Playwright 缓存 | 本地审计报告列出路径、体积、风险和安全建议 |
| WSL2 / Docker Desktop 的虚拟磁盘越长越大，但不知道在哪 | 报告标出 WSL distro、`ext4.vhdx`、Docker WSL backend 和 `.wslconfig` 状态 |
| Agent 发现大文件就想删 | 先分成 `Findings`、`Safe Suggestions`、`Manual / Risky Operations`，不自动迁移、不自动压缩、不自动删除 |

---

## 核心卖点

| 卖点 | 具体价值 |
|---|---|
| **CC Switch Ready** | 使用 `skills/tidy-skill/SKILL.md` 标准布局，更容易被 skill 扫描器识别 |
| **本地 Agent 环境洁癖** | 把仓库产物、工作区缓存、本机环境放进同一套治理模型 |
| **WSL2 / Docker 重点审计** | 检查 WSL 状态、distro 版本、`.wslconfig`、Docker WSL backend、VHDX 体积 |
| **本地离线** | 审计脚本不联网、不上传、不读取 token、数据库或私密日志 |
| **只读优先** | 审计只读；清理默认 DryRun；迁移、压缩、改配置永远只是建议 |
| **Python + PowerShell 分工** | Python 做通用仓库审计；PowerShell 做 Windows/WSL/Docker 深度审计 |

---

## Skill 包结构

```text
skills/
└─ tidy-skill/
   ├─ SKILL.md
   ├─ agents/openai.yaml
   ├─ scripts/
   ├─ references/
   ├─ templates/
   └─ examples/
```

`tidy-skill` 是机器可识别的 skill 名称。`洁癖.skill` 是展示名。

---

## 安装

### CC Switch 导入

在 CC Switch 的 Skills 页面中添加这个仓库：

| 字段 | 填写 |
|---|---|
| Owner | 当前 GitHub 仓库 owner |
| Name | 当前 GitHub 仓库名 |
| Branch | `main` |
| Subdirectory | `skills` |

刷新后搜索 `tidy-skill` 或 `洁癖.skill`，安装即可。

安装后应能看到类似路径：

```text
~/.claude/skills/tidy-skill/SKILL.md
~/.codex/skills/tidy-skill/SKILL.md
```

### 手动安装

先自检：

```powershell
.\skills\tidy-skill\scripts\install-local.ps1 -SelfCheckOnly
```

Claude Code：

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\skills" | Out-Null
Copy-Item -Recurse -Force ".\skills\tidy-skill" "$env:USERPROFILE\.claude\skills\tidy-skill"
```

Codex：

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.codex\skills" | Out-Null
Copy-Item -Recurse -Force ".\skills\tidy-skill" "$env:USERPROFILE\.codex\skills\tidy-skill"
```

也可以使用安装脚本同时预览 Codex 和 Claude 安装：

```powershell
.\skills\tidy-skill\scripts\install-local.ps1
```

真正复制需要显式关闭 DryRun：

```powershell
.\skills\tidy-skill\scripts\install-local.ps1 -DryRun:$false -Force
```

---

## 快速使用

### 仓库洁癖评分，优先用 Python

```powershell
python .\skills\tidy-skill\scripts\score_repo_hygiene.py --root . --report-path .\.agent_reports\repo_hygiene.md
```

### Agent 产物审计，优先用 Python

```powershell
python .\skills\tidy-skill\scripts\audit_agent_artifacts.py --root . --report-path .\.agent_reports\agent_artifacts.md
```

### 工作区审计

```powershell
.\skills\tidy-skill\scripts\audit-workspace-hygiene.ps1 -Root "D:\Projects" -ReportPath .\.agent_reports\workspace_hygiene.md
```

### 本机开发环境审计，优先用 Python 做通用基线

```powershell
python .\skills\tidy-skill\scripts\audit_dev_environment.py --root "D:\Projects" --report-path .\.agent_reports\dev_environment.md
```

### Windows / WSL2 / Docker 深度审计

```powershell
.\skills\tidy-skill\scripts\audit-dev-environment.ps1 -Roots "D:\Projects" -IncludeUserProfile -ReportPath .\.agent_reports\dev_environment.md
```

### 清理预览

```powershell
.\skills\tidy-skill\scripts\clean-agent-artifacts.ps1 -Root . -DryRun
```

默认只预览，不删除。真正清理需要显式确认。

---

## 报告预览

```markdown
## Overview Cards

| Card | Status | Evidence | Next step |
|---|---|---|---|
| Environment hygiene | Watch | 82 / 100 - Mostly controlled | Review the Top 10 optimization plan before changing anything. |
| C-drive risk | Watch | 14.20 GB detected on C drive | Prioritize package and model cache owners before touching tool state. |
| WSL/Docker risk | Manual deep audit | 2 distros, 28.40 GB VHDX footprint | Treat migration, compaction, and Docker data moves as manual operations. |
| Model cache risk | Controlled | 2.10 GB total, 0 B on C drive | Move future models only through tool-supported settings. |

## Top 10 Optimization Plan

| # | Area | Size | Why it matters | Can touch? | Next step |
|---:|---|---:|---|---|---|
| 1 | WSL/Docker VHDX | 28.40 GB | Virtual disks can grow even after data is deleted inside WSL or Docker. | Manual | Use documented WSL/Docker maintenance steps; do not delete or move the VHDX file directly. |
| 2 | Browser runtimes | 5.30 GB | Playwright/Puppeteer browser binaries are often rebuildable but can be shared by tests. | Safe to review | Check active projects first, then use the browser tool's supported reinstall/cleanup flow. |
```

---

## WSL2 / Docker 立场

洁癖.skill 会审计 WSL2 和 Docker Desktop 的本地 footprint，但不会替你迁移 distro、压缩 VHDX、修改 `.wslconfig`、移动 Docker 数据盘。

报告只会告诉你：

- WSL 是否安装、默认版本是什么。
- 哪些 distro 在跑，是否是 WSL2。
- `.wslconfig` 是否存在，是否设置 memory / swap / processors。
- WSL 和 Docker Desktop 相关 VHDX 文件在哪里、体积多大。
- 哪些动作属于安全建议，哪些属于需要你手动确认的高风险操作。

更多细节见 [wsl2-docker-hygiene.md](skills/tidy-skill/references/wsl2-docker-hygiene.md)。

---

## 脚本一览

| 脚本 | 用途 | 默认行为 |
|---|---|---|
| `score_repo_hygiene.py` | 通用仓库洁癖评分 | Python，无依赖，只读 |
| `audit_agent_artifacts.py` | 通用 Agent 产物审计 | Python，无依赖，只读 |
| `audit_dev_environment.py` | 通用本机环境审计基线 | Python，无依赖，只读 |
| `score-repo-hygiene.ps1` | Windows 版仓库评分 | 只读 |
| `audit-agent-artifacts.ps1` | Windows 版 Agent 产物审计 | 只读 |
| `audit-workspace-hygiene.ps1` | 批量扫描多个 Git 仓库 | 只读，必须指定根目录 |
| `audit-dev-environment.ps1` | 审计 WSL2、Docker、包缓存、模型缓存、Agent/IDE 状态 | 只读，必须指定扫描范围 |
| `clean-agent-artifacts.ps1` | 清理过期 `.agent_tmp/` 和 `.agent_reports/` | DryRun 优先 |
| `install-local.ps1` | 安装到本地 Codex / Claude skill 目录并自检 | DryRun 优先 |
| `install-rule-template.ps1` | 安装 AGENTS / CLAUDE / Cursor 规则模板 | DryRun 优先 |

更详细的脚本说明见 [script-usage.md](skills/tidy-skill/references/script-usage.md)。

---

## 安全边界

- 不上传数据，不联网。
- 审计脚本只读取文件路径、名称、大小、修改时间和公开工具状态。
- 不读取 token、认证文件、数据库、会话状态或私密日志。
- 不修改注册表、系统设置、环境变量、WSL 配置或计划任务。
- 不默认全盘扫描，必须由用户指定扫描范围。
- 不自动删除正式文档、源码、工具状态目录或 Git-tracked 文件。
- 不自动移动 WSL distro、Docker 数据盘或 AI 模型缓存。
- 清理脚本默认 DryRun，删除动作需要显式确认。

---

## 规则模板

可以把模板安装到目标项目，让不同 Agent 共享同一套文件治理规则：

| 目标 | 模板 |
|---|---|
| Claude Code | [templates/CLAUDE.md](skills/tidy-skill/templates/CLAUDE.md) |
| Codex / 通用 Agent | [templates/AGENTS.md](skills/tidy-skill/templates/AGENTS.md) |
| Cursor | [templates/cursor-rule.mdc](skills/tidy-skill/templates/cursor-rule.mdc) |

```powershell
.\skills\tidy-skill\scripts\install-rule-template.ps1 -TargetRoot "D:\Projects\MyApp"
.\skills\tidy-skill\scripts\install-rule-template.ps1 -TargetRoot "D:\Projects\MyApp" -Template AGENTS -DryRun:$false
```

---

## 项目治理

- 贡献指南：[CONTRIBUTING.md](CONTRIBUTING.md)
- 安全边界与问题报告：[SECURITY.md](SECURITY.md)
- CI 校验：见 [.github/workflows/validate.yml](.github/workflows/validate.yml)

---

## 路线图

- [ ] 将更多通用审计能力迁移到 Python
- [ ] 增强 WSL2 / Docker 报告解释能力
- [ ] Git hook 或 pre-commit 集成
- [ ] 可配置评分权重
- [ ] 实时 MCP 产物治理

---

## 开源协议

MIT License，见 [LICENSE](LICENSE)。
