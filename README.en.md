<h1 align="center">洁癖.skill / Tidy Skill</h1>

<p align="center">Leave fewer agent traces. Keep the useful ones.</p>

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="license">
  <img src="https://img.shields.io/badge/Agent_Skills-compatible-blueviolet.svg" alt="agent skills">
  <img src="https://img.shields.io/badge/Standard_Skills-compatible-success.svg" alt="standard skills">
  <img src="https://img.shields.io/badge/skills.sh-runtime-orange.svg" alt="skills.sh runtime">
</p>

---

Tidy Skill is an agent artifact governance skill for developers who like clean repos and controlled workspaces. It helps agents decide whether a file should exist, where it belongs, and when it should expire.

It is not a Markdown deleter. It gives plans, reports, summaries, and temporary files a clear purpose, place, and lifecycle.

With explicit user permission, Tidy Skill can also audit your current repo, your code workspace, or selected development directories to map where Node.js, Python, Go, Docker, WSL, MCP servers, AI agents, and model caches live. It lets you know which environments are controlled, which caches are out of bounds, and which paths are polluting your system drive.

[中文版](README.md)

---

## 📖 Table of Contents
* [🎯 Product Positioning](#-product-positioning)
* [⚡ Effect Examples](#-effect-examples)
* [📦 Installation & Configuration](#-installation--configuration)
* [🛡️ Hygiene Audit & Safety Principles](#-hygiene-audit--safety-principles)
* [🛠️ Script Description](#-script-description)
* [🗺️ Roadmap](#-roadmap)
* [📄 License](#-license)

---

## 🎯 Product Positioning

### Tier 1: Repo-Level Agent Artifact Governance
Specifically solves the problem of AI agents (like Claude Code, Cursor, etc.) writing temporary files (such as `plan.md`, `todo.md`) all over the project root.
* **Core Principles**:
  * **Default to no file creation**. Plans, TODOs, summaries, and progress updates stay in the chat context by default.
  * Temporary files that must be referenced as context are isolated under `.agent_tmp/`.
  * User-requested reports or deliverables are stored in `.agent_reports/`.
  * Formal documentation belongs in `docs/` and must be supported by explicit user intent.
  * No generic process Markdown files cluttering the project root.

### Tier 2: Coding Environment Hygiene Audit
Analyzes your developer environment setup to map cache footprints and disk usage risks.
* **Audit Scope** (requires explicit user authorization):
  * **Node/NPM**: npm/npx cache, pnpm store, yarn cache, Volta/NVM, etc.
  * **Python**: pip cache, uv cache/toolchains/tools, pipx, conda, poetry, venv.
  * **Go**: GOPATH, GOMODCACHE, GOCACHE, GOBIN.
  * **Rust**: cargo/rustup caches (CARGO_HOME/RUSTUP_HOME), target directories.
  * **Java**: Maven `.m2`, Gradle `.gradle` caches.
  * **Docker/WSL**: WSL `.vhdx` sizes and paths, Docker images and data volumes.
  * **AI Agents/IDE**: Claude, Codex, Cursor, VS Code cache and configuration locations (never reads tokens).
  * **AI Model Caches**: Hugging Face, Ollama, Torch, LM Studio model storage paths and sizes.
  * **Playwright/Puppeteer**: Rebuildable browser runtime binaries and caches.

---

## ⚡ Effect Examples

### 1. Dev Environment Hygiene Audit
Running `audit-dev-environment.ps1` maps your developer tools, caches, and system drive footprint:

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

### 2. Repo Hygiene Score
Evaluates a single repository's cleanliness:
```
Score: 71 / 100 — Mostly clean
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

## 📦 Installation & Configuration

Recommended workflow:

### 1. Install Skill Rules
* **Automatic**: Link or copy this project to a skills-compatible AI agent CLI:
  ```bash
  ln -s /path/to/tidy-skill ~/.your-agent/skills/tidy-skill
  ```
* **Manual**: Copy rule templates directly to your project:
  * **Claude Code**: Copy `templates/CLAUDE.md` to your project root.
  * **Cursor**: Copy `templates/cursor-rule.mdc` to `.cursor/rules/agent-tidy.mdc`.
  * **Any Agent**: Copy `templates/AGENTS.md` to your project root.

### 2. Run Repo Hygiene Scoring
Audits the current Git repository's Agent artifacts and hygiene score:
```powershell
.\scripts\score-repo-hygiene.ps1 -Root . -ReportPath .\repo_hygiene_report.md
```

### 3. Run Workspace or Environment Audits (User Authorized)
Audits multiple Git repositories under a specified root:
```powershell
.\scripts\audit-workspace-hygiene.ps1 -Root "E:\1_Code\Projects" -ReportPath .\workspace_hygiene_report.md
```

Audits developer environment setups and AI caches (must specify Roots; no automatic full-disk scans):
```powershell
# Scan only specific developer directories
.\scripts\audit-dev-environment.ps1 -Roots "E:\1_Code" -ReportPath .\dev_environment_hygiene_report.md

# Scan dev directories and include user profile (for VS Code, Ollama, etc. cache paths)
.\scripts\audit-dev-environment.ps1 -Roots "E:\1_Code","D:\Projects" -IncludeUserProfile -ReportPath .\dev_environment_hygiene_report.md
```

### 4. Clean Temporary Artifacts
* **Preview what would be cleaned** (DryRun, does not delete files):
  ```powershell
  .\scripts\clean-agent-artifacts.ps1 -Root . -DryRun
  ```
* **Confirm cleanup** (removes expired `.agent_tmp` and `.agent_reports` files):
  ```powershell
  .\scripts\clean-agent-artifacts.ps1 -Root . -ConfirmClean
  ```

---

## 🛡️ Hygiene Audit & Safety Principles

All scripts and tooling strictly comply with the following safety and privacy standards:
* **Local & Privacy First**: All scripts run offline; no reports, paths, or environment data are uploaded.
* **Read-only Audits**: Scoring and environment scripts read metadata (file paths, names, sizes, modified times) only. They never read sensitive tokens, credentials, databases, or private data.
* **Default DryRun**: The cleanup script defaults to DryRun mode and will never delete files unless explicitly instructed.
* **No Side-Effects**: Scripts will never rewrite registry keys, modify environment variables, change system configurations, or register scheduled background tasks.
* **Controlled Scan Range**: No blind full-disk scans are performed. The user must explicitly specify roots or drives to scan.

---

## 🛠️ Script Description

| Script | Purpose | Safety | Example Command |
|---|---|---|---|
| `score-repo-hygiene.ps1` | Scores a single repo's cleanliness | Read-only | `.\score-repo-hygiene.ps1 -Root .` |
| `audit-agent-artifacts.ps1` | Audits agent artifacts in a repository | Read-only | `.\audit-agent-artifacts.ps1 -Root .` |
| `audit-workspace-hygiene.ps1` | Audits multiple repos in a workspace | Read-only | `.\audit-workspace-hygiene.ps1 -Root "E:\1_Code"` |
| `audit-dev-environment.ps1` | Audits runtimes, tools, virtualization, and AI models | Read-only, scoped | `.\audit-dev-environment.ps1 -Roots "E:\1_Code" -IncludeUserProfile` |
| `clean-agent-artifacts.ps1` | Cleans up expired temporary files | DryRun by default | `.\clean-agent-artifacts.ps1 -Root . -ConfirmClean` |

---

## 🗺️ Roadmap

- [ ] **Pre-commit Integration**: Automatically perform cleanliness auditing before code commit.
- [ ] **CI/CD Integration**: Automatically check repository cleanliness in GitHub Actions pipelines.
- [ ] **Multi-language Script Porting**: Provide native Bash / Python scripts to remove PowerShell dependency.
- [ ] **Custom Weights**: Allow users to customize weights and scoring thresholds for hygiene dimensions.
- [ ] **Real-time MCP Plugin**: Develop an MCP server for real-time Agent artifact governance.

---

## 📄 License

MIT License — see the [LICENSE](LICENSE) file.

Copyright (c) 2026 Tidy Skill Contributors.
