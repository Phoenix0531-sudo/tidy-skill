<h1 align="center">洁癖.skill</h1>

<p align="center">Let AI agents work inside a clean, explainable, recoverable local environment.</p>

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="license">
  <img src="https://img.shields.io/badge/CC%20Switch-ready-success.svg" alt="CC Switch ready">
  <img src="https://img.shields.io/badge/layout-skills%2Ftidy--skill-success.svg" alt="skill layout">
  <img src="https://img.shields.io/badge/runtime-Python%20%2B%20PowerShell-5391FE.svg" alt="Python and PowerShell">
  <img src="https://img.shields.io/badge/network-offline-lightgrey.svg" alt="offline">
</p>

<p align="center">
  <a href="README.md">中文</a>
</p>

---

## One Line

洁癖.skill is not a Markdown deleter and not only a repo cleanup tool. It is a local agent-environment hygiene policy and audit toolkit for keeping agent files, caches, virtualization footprints, and model storage explainable, placed, and safely recoverable.

---

## Three-Layer Hygiene Model

| Layer | Governs | Typical Problem | Tools |
|---|---|---|---|
| Repository | Agent artifacts | `plan.md`, `todo.md`, and `final_report.md` pile up in the repo root | `audit_agent_artifacts.py`, `score_repo_hygiene.py` |
| Workspace | Development caches | Many projects leave `node_modules`, `.venv`, `target`, and build caches behind | `audit-workspace-hygiene.ps1` |
| Local machine | Development environment | WSL2/Docker VHDX growth, package caches, model caches, scattered agent/IDE state | `audit-dev-environment.ps1` |

---

## Before / After

| Before | After |
|---|---|
| Agents drop plans, summaries, and reports into the repo root | Plans stay in chat; reports go to `.agent_reports/`; temp files go to `.agent_tmp/` |
| npm, pip, uv, Go, Rust, and Playwright caches sprawl across the system drive | Local audit reports list paths, sizes, risks, and safe suggestions |
| WSL2 / Docker Desktop virtual disks grow without a clear owner | Reports show WSL distros, `ext4.vhdx`, Docker WSL backend, and `.wslconfig` state |
| Agents see large files and try to delete them | Reports separate `Findings`, `Safe Suggestions`, and `Manual / Risky Operations` |

---

## Highlights

| Highlight | Value |
|---|---|
| **CC Switch Ready** | Uses the scanner-friendly `skills/tidy-skill/SKILL.md` layout |
| **Local agent environment hygiene** | Unifies repo artifacts, workspace caches, and local machine state |
| **WSL2 / Docker focus** | Checks WSL status, distro versions, `.wslconfig`, Docker WSL backend, and VHDX footprint |
| **Local and offline** | No network calls, uploads, token reads, database reads, or private log reads |
| **Read-only first** | Audits are read-only; cleanup defaults to DryRun; migration, compaction, and config changes are suggestions only |
| **Python + PowerShell split** | Python handles portable repo checks; PowerShell handles Windows/WSL/Docker deep audits |

---

## Skill Layout

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

`tidy-skill` is the machine-readable skill name. `洁癖.skill` is the display name.

---

## Installation

### CC Switch

In the CC Switch Skills page, add this repository:

| Field | Value |
|---|---|
| Owner | Current GitHub repository owner |
| Name | Current GitHub repository name |
| Branch | `main` |
| Subdirectory | `skills` |

Refresh, search for `tidy-skill` or `洁癖.skill`, then install.

After installation, the skill should appear at paths like:

```text
~/.claude/skills/tidy-skill/SKILL.md
~/.codex/skills/tidy-skill/SKILL.md
```

### Manual Install

Self-check first:

```powershell
.\skills\tidy-skill\scripts\install-local.ps1 -SelfCheckOnly
```

Claude Code:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\skills" | Out-Null
Copy-Item -Recurse -Force ".\skills\tidy-skill" "$env:USERPROFILE\.claude\skills\tidy-skill"
```

Codex:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.codex\skills" | Out-Null
Copy-Item -Recurse -Force ".\skills\tidy-skill" "$env:USERPROFILE\.codex\skills\tidy-skill"
```

You can also preview installation into both Codex and Claude:

```powershell
.\skills\tidy-skill\scripts\install-local.ps1
```

Actual copying requires explicitly disabling DryRun:

```powershell
.\skills\tidy-skill\scripts\install-local.ps1 -DryRun:$false -Force
```

---

## Quick Use

### Repo hygiene scoring, prefer Python

```powershell
python .\skills\tidy-skill\scripts\score_repo_hygiene.py --root . --report-path .\.agent_reports\repo_hygiene.md
```

### Agent artifact audit, prefer Python

```powershell
python .\skills\tidy-skill\scripts\audit_agent_artifacts.py --root . --report-path .\.agent_reports\agent_artifacts.md
```

### Workspace audit

```powershell
.\skills\tidy-skill\scripts\audit-workspace-hygiene.ps1 -Root "D:\Projects" -ReportPath .\.agent_reports\workspace_hygiene.md
```

### Local development environment audit, prefer Python for the portable baseline

```powershell
python .\skills\tidy-skill\scripts\audit_dev_environment.py --root "D:\Projects" --report-path .\.agent_reports\dev_environment.md
```

### Windows / WSL2 / Docker deep audit

```powershell
.\skills\tidy-skill\scripts\audit-dev-environment.ps1 -Roots "D:\Projects" -IncludeUserProfile -ReportPath .\.agent_reports\dev_environment.md
```

### Cleanup preview

```powershell
.\skills\tidy-skill\scripts\clean-agent-artifacts.ps1 -Root . -DryRun
```

Cleanup previews by default. Actual deletion requires explicit confirmation.

---

## Report Preview

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

## WSL2 / Docker Position

洁癖.skill audits the local footprint of WSL2 and Docker Desktop, but it does not migrate distros, compact VHDX files, modify `.wslconfig`, or move Docker data.

Reports show:

- Whether WSL is installed and what the default version is.
- Which distros exist and whether they use WSL2.
- Whether `.wslconfig` exists and whether memory / swap / processors are configured.
- Where WSL and Docker Desktop VHDX files live and how large they are.
- Which actions are safe suggestions and which are manual high-risk operations.

See [wsl2-docker-hygiene.md](skills/tidy-skill/references/wsl2-docker-hygiene.md) for details.

---

## Scripts

| Script | Purpose | Default Behavior |
|---|---|---|
| `score_repo_hygiene.py` | Portable repo hygiene scoring | Python, dependency-free, read-only |
| `audit_agent_artifacts.py` | Portable agent artifact audit | Python, dependency-free, read-only |
| `audit_dev_environment.py` | Portable local environment audit baseline | Python, dependency-free, read-only |
| `score-repo-hygiene.ps1` | Windows repo hygiene scoring | Read-only |
| `audit-agent-artifacts.ps1` | Windows agent artifact audit | Read-only |
| `audit-workspace-hygiene.ps1` | Scans multiple Git repositories | Read-only, explicit root required |
| `audit-dev-environment.ps1` | Audits WSL2, Docker, package caches, model caches, and agent/IDE state | Read-only, scoped |
| `clean-agent-artifacts.ps1` | Cleans expired `.agent_tmp/` and `.agent_reports/` files | DryRun first |
| `install-local.ps1` | Installs into local Codex / Claude skill directories and self-checks | DryRun first |
| `install-rule-template.ps1` | Installs AGENTS / CLAUDE / Cursor rule templates | DryRun first |

See [script-usage.md](skills/tidy-skill/references/script-usage.md) for details.

---

## Safety Boundaries

- No uploads, no network calls.
- Audit scripts read file paths, names, sizes, modified times, and public tool state only.
- No token, credential, database, session, or private log reads.
- No registry, system setting, environment variable, WSL config, or scheduled task changes.
- No default full-disk scan. Users must specify the scan scope.
- No automatic deletion of formal docs, source code, tool state, or Git-tracked files.
- No automatic movement of WSL distros, Docker data, or AI model caches.
- Cleanup defaults to DryRun and requires explicit confirmation for deletion.

---

## Rule Templates

Install these templates into target projects when you want multiple agents to share the same file hygiene rules:

| Target | Template |
|---|---|
| Claude Code | [templates/CLAUDE.md](skills/tidy-skill/templates/CLAUDE.md) |
| Codex / General Agents | [templates/AGENTS.md](skills/tidy-skill/templates/AGENTS.md) |
| Cursor | [templates/cursor-rule.mdc](skills/tidy-skill/templates/cursor-rule.mdc) |

```powershell
.\skills\tidy-skill\scripts\install-rule-template.ps1 -TargetRoot "D:\Projects\MyApp"
.\skills\tidy-skill\scripts\install-rule-template.ps1 -TargetRoot "D:\Projects\MyApp" -Template AGENTS -DryRun:$false
```

---

## Project Governance

- Contribution guide: [CONTRIBUTING.md](CONTRIBUTING.md)
- Security boundaries and reporting: [SECURITY.md](SECURITY.md)
- CI validation: [.github/workflows/validate.yml](.github/workflows/validate.yml)

---

## Roadmap

- [ ] Move more portable audit checks to Python
- [ ] Improve WSL2 / Docker report explanations
- [ ] Git hook or pre-commit integration
- [ ] Configurable scoring weights
- [ ] Real-time MCP artifact governance

---

## Acknowledgements

Thanks to the Linux.do community for the discussion, feedback, and support.

---

## License

MIT License. See [LICENSE](LICENSE).
