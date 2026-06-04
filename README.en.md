<h1 align="center">洁癖.skill</h1>

<p align="center">An AI agent artifact governance skill. Create fewer throwaway files, and make every remaining file intentional, scoped, and cleanable.</p>

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

AI agents often miss one decision before creating files: should this exist, where should it live, and when can it be cleaned up?

洁癖.skill gives agents a file-artifact governance policy and local audit scripts for session leftovers such as `plan.md`, `todo.md`, `summary.md`, and `report.md`.

---

## Highlights

| Highlight | Value |
|---|---|
| **CC Switch Ready** | Uses the scanner-friendly `skills/tidy-skill/SKILL.md` layout |
| **No-file default** | Plans, TODOs, progress notes, and summaries stay in chat by default |
| **Artifact classes** | `.agent_tmp/` for temporary files, `.agent_reports/` for requested reports, `docs/` for formal docs |
| **Local and offline** | No network calls, uploads, token reads, database reads, or private log reads |
| **Portable baseline** | `score_repo_hygiene.py` provides a dependency-free Python repo scoring entrypoint |
| **Windows deep audit** | PowerShell scripts inspect WSL, Docker, Node, Python, Go, and AI model cache locations |

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

---

## Quick Use

### Portable repo scoring, prefer Python

```powershell
python .\skills\tidy-skill\scripts\score_repo_hygiene.py --root . --report-path .\.agent_reports\repo_hygiene.md
```

### Windows / PowerShell repo scoring

```powershell
.\skills\tidy-skill\scripts\score-repo-hygiene.ps1 -Root . -ReportPath .\.agent_reports\repo_hygiene.md
```

### Audit agent artifacts in one repository

```powershell
.\skills\tidy-skill\scripts\audit-agent-artifacts.ps1 -Root . -ReportPath .\.agent_reports\agent_artifacts.md
```

### Audit a workspace

```powershell
.\skills\tidy-skill\scripts\audit-workspace-hygiene.ps1 -Root "D:\Projects" -ReportPath .\.agent_reports\workspace_hygiene.md
```

### Audit development environment caches

```powershell
.\skills\tidy-skill\scripts\audit-dev-environment.ps1 -Roots "D:\Projects" -ReportPath .\.agent_reports\dev_environment.md
```

### Preview cleanup

```powershell
.\skills\tidy-skill\scripts\clean-agent-artifacts.ps1 -Root . -DryRun
```

Cleanup previews by default. Actual deletion requires explicit confirmation.

---

## Why Both Python and PowerShell

Many skill repositories use Python because it is portable, dependency-light, and easier for agents to reuse. 洁癖.skill now provides `score_repo_hygiene.py` as the general-purpose repository scoring entrypoint.

PowerShell remains useful because part of this skill is Windows development-environment hygiene: WSL `.vhdx` files, Docker, user caches, Node/Python/Go toolchains, and AI model caches are easier to inspect with Windows-native commands. Future work should move portable checks into Python while keeping Windows-specific checks in PowerShell.

---

## Scripts

| Script | Purpose | Default Behavior |
|---|---|---|
| `score_repo_hygiene.py` | Portable repo hygiene scoring | Python, dependency-free, read-only |
| `score-repo-hygiene.ps1` | Windows repo hygiene scoring | Read-only |
| `audit-agent-artifacts.ps1` | Lists suspicious agent artifacts | Read-only |
| `audit-workspace-hygiene.ps1` | Scans multiple Git repositories | Read-only, explicit root required |
| `audit-dev-environment.ps1` | Audits Node/Python/Go/Docker/WSL/AI cache locations | Read-only, scoped |
| `clean-agent-artifacts.ps1` | Cleans expired `.agent_tmp/` and `.agent_reports/` files | DryRun first |

See [scripts/README.md](skills/tidy-skill/scripts/README.md) for details.

---

## Safety Boundaries

- No uploads, no network calls.
- Audit scripts read file paths, names, sizes, and modified times only.
- No token, credential, database, session, or private log reads.
- No registry, system setting, environment variable, or scheduled task changes.
- No default full-disk scan. Users must specify the scan scope.
- No automatic deletion of formal docs, source code, tool state, or Git-tracked files.
- Cleanup defaults to DryRun and requires explicit confirmation for deletion.

---

## Rule Templates

Copy these templates into target projects when you want multiple agents to share the same file hygiene rules:

| Target | Template |
|---|---|
| Claude Code | [templates/CLAUDE.md](skills/tidy-skill/templates/CLAUDE.md) |
| Codex / General Agents | [templates/AGENTS.md](skills/tidy-skill/templates/AGENTS.md) |
| Cursor | [templates/cursor-rule.mdc](skills/tidy-skill/templates/cursor-rule.mdc) |

---

## Roadmap

- [ ] Move more portable audit checks to Python
- [ ] Git hook or pre-commit integration
- [ ] GitHub Actions hygiene checks
- [ ] Configurable scoring weights
- [ ] Real-time MCP artifact governance

---

## License

MIT License. See [LICENSE](LICENSE).
