<h1 align="center">洁癖.skill / Tidy Skill</h1>

<p align="center">让 AI Agent 少留痕，留下的都有用。</p>

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="license">
  <img src="https://img.shields.io/badge/Agent_Skills-compatible-blueviolet.svg" alt="agent skills">
  <img src="https://img.shields.io/badge/Standard_Skills-compatible-success.svg" alt="standard skills">
  <img src="https://img.shields.io/badge/skills.sh-runtime-orange.svg" alt="skills.sh runtime">
</p>

---

洁癖.skill 是一个给代码环境洁癖用户使用的 Agent 产物治理 Skill。它让 Agent 在写文件前先判断：该不该生成、该放哪里、什么时候清理。

它不是 Markdown 删除器，而是让计划、报告、总结和临时文件拥有明确的目的、归属和生命周期。

它还可以在你明确授权后，分析当前仓库、代码工作区，甚至整台电脑上的开发环境分布，包括 NPM、Python、Go、Docker、WSL、MCP、Agent 配置和 AI 模型缓存，让你知道哪些环境可控，哪些缓存失控，哪些路径正在污染系统盘。

[English Edition](README.en.md)

---

## 📖 目录
* [🎯 产品定位](#-产品定位)
* [⚡ 效果示例](#-效果示例)
* [📦 安装与配置](#-安装与配置)
* [🛡️ 洁癖审计与安全原则](#-洁癖审计与安全原则)
* [🛠️ 脚本说明](#-脚本说明)
* [🗺️ 路线图](#-路线图)
* [📄 开源协议](#-开源协议)

---

## 🎯 产品定位

### 第一层：仓库级 Agent 产物治理
专门解决 AI Agent（如 Claude Code、Cursor 等）在项目根目录下乱写临时文件的问题（如 `plan.md`、`todo.md` 等）。
* **核心原则**：
  * **默认不写文件**。计划、TODO、总结、进度等信息默认留在聊天上下文里。
  * 确实需要作为上下文持续引用的临时文件，统一放入 `.agent_tmp/`。
  * 用户明确要求保存的报告或交付物，放入 `.agent_reports/`。
  * 正式文档放入 `docs/`，并且必须有明确的用户意图。
  * 根目录绝不堆放泛名过程 Markdown 文件。

### 第二层：代码环境洁癖审计
分析开发环境分布，发现失控的缓存和磁盘占用风险。
* **审计范围**（需用户显式授权）：
  * **Node/NPM**：npm/npx 缓存、pnpm store、yarn cache、Volta/NVM 等。
  * **Python**：pip 缓存、uv 缓存/工具链/工具目录、pipx、conda、poetry、venv 等。
  * **Go**：GOPATH、GOMODCACHE、GOCACHE、GOBIN。
  * **Rust**：cargo/rustup 缓存（CARGO_HOME/RUSTUP_HOME）、项目 target 大目录。
  * **Java**：Maven `.m2`、Gradle `.gradle` 缓存。
  * **Docker/WSL**：wsl .vhdx 虚拟磁盘大小及位置、Docker 镜像与数据路径。
  * **AI Agents/IDE**：Claude、Codex、Cursor、VS Code 缓存与配置位置（不读取 Token 敏感信息）。
  * **AI 模型缓存**：Hugging Face、Ollama、Torch、LM Studio 模型存储路径与体积。
  * **Playwright/Puppeteer**：可重建的浏览器运行时缓存。

---

## ⚡ 效果示例

### 1. 代码环境洁癖审计 (Dev Environment Hygiene Audit)
运行 `audit-dev-environment.ps1` 可以清晰掌握全盘开发缓存占用和环境健康度：

```
Tidy Skill — Dev Environment Audit
Scoring: D:\3_Code_Projects

Score: 78 / 100 — Mostly controlled (基本可控)
Report: D:\3_Code_Projects\.agent_reports\dev_environment_hygiene_2026-06-03_224512.md

Summary Breakdown:
- C-Drive Footprint        : 10.2 GB (Score: 10/20) - npm-cache, pip-cache
- Active Runtimes          : Go v1.21, Python 3.10, Node v18 (Score: 20/20)
- Cache Isolation          : Ollama models found on C:\Users\...\.ollama (Score: 10/20)
- Agent State Cleanliness  : VS Code & Cursor cache: 1.5 GB (Score: 20/20)
- Virtualization Footprint : WSL ext4.vhdx size: 8.5 GB (Score: 18/20)
```

### 2. 仓库洁癖评分 (Repo Hygiene Score)
评估单个 Git 仓库的整洁度评分：
```
Score: 71 / 100 — Mostly clean (基本干净)
Report: D:\3_Code_Projects\Tidy_Skill\.agent_reports\hygiene_score_2026-06-03_222912.md

Dimensions Checked:
- Root cleanliness       : 18 / 25
- Artifact placement     : 15 / 20
- Protected docs clarity : 12 / 15
- Git hygiene            : 11 / 15
- Agent state isolation  : 15 / 15
- Cleanup readiness      : 0 / 10
```

---

## 📦 安装与配置

推荐的使用路径如下：

### 1. 安装 Skill 规则
* **自动加载**：将本项目链接或复制到兼容 Agent Skills 的 AI 终端中：
  ```bash
  ln -s /path/to/tidy-skill ~/.your-agent/skills/tidy-skill
  ```
* **手动加载**：将规则模板复制到对应项目中：
  * **Claude Code**: 复制 `templates/CLAUDE.md` 到项目根目录。
  * **Cursor**: 复制 `templates/cursor-rule.mdc` 到 `.cursor/rules/agent-tidy.mdc`。
  * **通用 Agent**: 复制 `templates/AGENTS.md` 到项目根目录。

### 2. 进行仓库洁癖评分
分析当前 Git 仓库的 Agent 产物和文件健康程度：
```powershell
.\scripts\score-repo-hygiene.ps1 -Root . -ReportPath .\repo_hygiene_report.md
```

### 3. 用户授权运行工作区或环境审计
扫描指定目录下的所有 Git 仓库的洁癖情况：
```powershell
.\scripts\audit-workspace-hygiene.ps1 -Root "E:\1_Code\Projects" -ReportPath .\workspace_hygiene_report.md
```

在明确授权后，审计整个开发环境分布与 AI 缓存占用（必须指定 Roots 路径，不进行默认全盘扫描）：
```powershell
# 仅扫描指定的代码盘开发环境
.\scripts\audit-dev-environment.ps1 -Roots "E:\1_Code" -ReportPath .\dev_environment_hygiene_report.md

# 显式授权扫描用户目录（包含 VS Code、Ollama 等默认缓存）
.\scripts\audit-dev-environment.ps1 -Roots "E:\1_Code","D:\Projects" -IncludeUserProfile -ReportPath .\dev_environment_hygiene_report.md
```

### 4. 清理临时产物
* **预览要清理的文件**（默认 DryRun，不删除任何内容）：
  ```powershell
  .\scripts\clean-agent-artifacts.ps1 -Root . -DryRun
  ```
* **确认清理**（删除超过 7 天的 `.agent_tmp` 与超过 30 天的 `.agent_reports` 临时文件）：
  ```powershell
  .\scripts\clean-agent-artifacts.ps1 -Root . -ConfirmClean
  ```

---

## 🛡️ 洁癖审计与安全原则

为了确保系统与数据安全，项目内的所有工具和脚本遵循以下最严格的原则：
* **本地与隐私优先**：所有脚本完全离线运行，绝对不上传任何报告、日志或路径信息。
* **只读优先**：审计与打分脚本只读取文件路径、名称、大小和修改时间，绝对不读取 token、认证密钥、数据库文件等敏感内容。
* **默认 DryRun**：清理脚本在不传入特定参数时默认进入预览模式，不会强行删除任何文件。
* **安全底线**：脚本绝不会修改系统环境变量、绝不会修改注册表、绝不会自动删除系统关键目录，也绝不会注册后台计划任务。
* **控制扫描范围**：拒绝进行盲目的全盘扫描，用户必须通过参数明确指定扫描的根目录或盘符范围。

---

## 🛠️ 脚本说明

| 脚本 | 作用 | 安全性 | 示例命令 |
|---|---|---|---|
| `score-repo-hygiene.ps1` | 给单个仓库的整洁度打分 | 只读 | `.\score-repo-hygiene.ps1 -Root .` |
| `audit-agent-artifacts.ps1` | 只读审计单个仓库中的 Agent 产物 | 只读 | `.\audit-agent-artifacts.ps1 -Root .` |
| `audit-workspace-hygiene.ps1` | 批量扫描并打分工作区内的多个仓库 | 只读 | `.\audit-workspace-hygiene.ps1 -Root "E:\1_Code"` |
| `audit-dev-environment.ps1` | 用户授权后，审计多语言开发环境及 AI 模型缓存 | 只读，需指定范围 | `.\audit-dev-environment.ps1 -Roots "E:\1_Code" -IncludeUserProfile` |
| `clean-agent-artifacts.ps1` | 按照规则和生命周期清理过期的临时文件 | 默认 DryRun，需确认 | `.\clean-agent-artifacts.ps1 -Root . -ConfirmClean` |

---

## 🗺️ 路线图

- [ ] **Pre-commit 集成**：在代码 commit 前自动进行洁癖审计。
- [ ] **CI/CD 集成**：GitHub Actions 中自动进行仓库整洁度卫生检查。
- [ ] **多语言脚本移植**：提供原生 Bash / Python 版本的脚本，免去 PowerShell 依赖。
- [ ] **自定义权重**：允许用户自定义各个洁癖维度的扣分和计分权重。
- [ ] **实时 MCP 插件**：开发 MCP server，实现 Agent 的实时产物治理。

---

## 📄 开源协议

MIT License — 详见 [LICENSE](LICENSE) 文件。

Copyright (c) 2026 Tidy Skill Contributors.
