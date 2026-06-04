<h1 align="center">洁癖.skill</h1>

<p align="center">让 AI Agent 少留垃圾文件，留下的每一个都有归属、有生命周期、能被安全清理。</p>

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

AI Agent 写文件前，经常缺一个判断：这东西该不该存在，应该放哪，多久以后可以清掉。

洁癖.skill 给 Agent 一套文件产物治理规则，并提供本地审计脚本，专门处理 `plan.md`、`todo.md`、`summary.md`、`report.md` 这类会话遗留物。

---

## 前后对比

| Before | After |
|---|---|
| `plan.md`、`todo.md`、`final_report.md` 堆在项目根目录 | 计划和总结默认留在聊天里 |
| 用户要求的审计报告和临时笔记混在一起 | 报告进 `.agent_reports/`，临时文件进 `.agent_tmp/` |
| Agent 清理时不知道哪些文件能删 | 文件有分类、归属和默认生命周期 |

---

## 核心卖点

| 卖点 | 具体价值 |
|---|---|
| **CC Switch Ready** | 使用 `skills/tidy-skill/SKILL.md` 标准布局，更容易被 skill 扫描器识别 |
| **默认不落盘** | 计划、TODO、进度、总结默认留在聊天里，不污染项目根目录 |
| **分级治理** | `.agent_tmp/` 放临时文件，`.agent_reports/` 放用户要求的报告，`docs/` 放正式文档 |
| **本地离线** | 审计脚本不联网、不上传、不读取 token、数据库或私密日志 |
| **跨平台基础检查** | `score_repo_hygiene.py` 和 `audit_agent_artifacts.py` 提供无依赖 Python 入口 |
| **Windows 深度审计** | PowerShell 脚本覆盖 WSL、Docker、Node、Python、Go、AI 模型缓存等 Windows 开发环境细节 |

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

---

## 快速使用

### 通用仓库评分，优先用 Python

```powershell
python .\skills\tidy-skill\scripts\score_repo_hygiene.py --root . --report-path .\.agent_reports\repo_hygiene.md
```

### Windows / PowerShell 仓库评分

```powershell
.\skills\tidy-skill\scripts\score-repo-hygiene.ps1 -Root . -ReportPath .\.agent_reports\repo_hygiene.md
```

### 通用 Agent 产物审计，优先用 Python

```powershell
python .\skills\tidy-skill\scripts\audit_agent_artifacts.py --root . --report-path .\.agent_reports\agent_artifacts.md
```

### Windows / PowerShell Agent 产物审计

```powershell
.\skills\tidy-skill\scripts\audit-agent-artifacts.ps1 -Root . -ReportPath .\.agent_reports\agent_artifacts.md
```

### 审计一组项目

```powershell
.\skills\tidy-skill\scripts\audit-workspace-hygiene.ps1 -Root "D:\Projects" -ReportPath .\.agent_reports\workspace_hygiene.md
```

### 审计开发环境缓存

```powershell
.\skills\tidy-skill\scripts\audit-dev-environment.ps1 -Roots "D:\Projects" -ReportPath .\.agent_reports\dev_environment.md
```

### 预览清理动作

```powershell
.\skills\tidy-skill\scripts\clean-agent-artifacts.ps1 -Root . -DryRun
```

默认只预览，不删除。真正清理需要显式确认。

---

## 为什么既有 Python，也有 PowerShell

主流 skill 仓库常用 Python，是因为它跨平台、无 shell 方言问题，也更容易被 Agent 复用。所以洁癖.skill 已经提供 `score_repo_hygiene.py` 作为通用仓库评分入口。

PowerShell 仍然保留，因为这个 skill 的一部分价值来自 Windows 开发环境治理：WSL `.vhdx`、Docker、用户缓存、Node/Python/Go 工具链、AI 模型缓存等都更适合用 Windows 原生命令和 PowerShell 查询。后续会逐步把可跨平台的能力迁移到 Python，Windows 专项能力继续保留 PowerShell。

---

## 脚本一览

| 脚本 | 用途 | 默认行为 |
|---|---|---|
| `score_repo_hygiene.py` | 通用仓库洁癖评分 | Python，无依赖，只读 |
| `audit_agent_artifacts.py` | 通用 Agent 产物审计 | Python，无依赖，只读 |
| `score-repo-hygiene.ps1` | Windows 版仓库评分 | 只读 |
| `audit-agent-artifacts.ps1` | 列出仓库里的可疑 Agent 产物 | 只读 |
| `audit-workspace-hygiene.ps1` | 批量扫描多个 Git 仓库 | 只读，必须指定根目录 |
| `audit-dev-environment.ps1` | 审计 Node/Python/Go/Docker/WSL/AI 缓存位置 | 只读，必须指定扫描范围 |
| `clean-agent-artifacts.ps1` | 清理过期 `.agent_tmp/` 和 `.agent_reports/` | DryRun 优先 |

更详细的脚本说明见 [script-usage.md](skills/tidy-skill/references/script-usage.md)。

---

## 安全边界

- 不上传数据，不联网。
- 审计脚本只读取文件路径、名称、大小和修改时间。
- 不读取 token、认证文件、数据库、会话状态或私密日志。
- 不修改注册表、系统设置、环境变量或计划任务。
- 不默认全盘扫描，必须由用户指定扫描范围。
- 不自动删除正式文档、源码、工具状态目录或 Git-tracked 文件。
- 清理脚本默认 DryRun，删除动作需要显式确认。

---

## 规则模板

可以把模板复制到目标项目，让不同 Agent 共享同一套文件治理规则：

| 目标 | 模板 |
|---|---|
| Claude Code | [templates/CLAUDE.md](skills/tidy-skill/templates/CLAUDE.md) |
| Codex / 通用 Agent | [templates/AGENTS.md](skills/tidy-skill/templates/AGENTS.md) |
| Cursor | [templates/cursor-rule.mdc](skills/tidy-skill/templates/cursor-rule.mdc) |

---

## 项目治理

- 贡献指南：[CONTRIBUTING.md](CONTRIBUTING.md)
- 安全边界与问题报告：[SECURITY.md](SECURITY.md)
- CI 校验：见 [.github/workflows/validate.yml](.github/workflows/validate.yml)

---

## 路线图

- [ ] 将更多通用审计能力迁移到 Python
- [ ] Git hook 或 pre-commit 集成
- [ ] GitHub Actions 洁癖检查
- [ ] 可配置评分权重
- [ ] 实时 MCP 产物治理

---

## 开源协议

MIT License，见 [LICENSE](LICENSE)。
