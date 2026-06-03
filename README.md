# 洁癖.skill / Tidy Skill

Stop AI agents from littering your repo with `plan.md`, `todo.md`, `summary.md`, and throwaway artifacts.

> A repo and workspace hygiene skill for people who like their AI agent outputs clean, intentional, and disposable when needed.

[中文版](README.zh-CN.md)

---

## What is Tidy Skill?

Tidy Skill is an **AI agent artifact governance toolkit** for developers who care about code environment cleanliness. It does three things:

1. **Teaches agents** to think before creating files — is this necessary? Where should it go? When should it be deleted?
2. **Audits and scores** your repo hygiene — how clean is your project root? Are agent artifacts properly placed?
3. **Safely cleans** what should be disposable — temporary files, expired reports — while **never** touching your formal documentation.

---

## Why This Exists

AI coding agents are productive. They are also messy.

A single conversation produces `plan.md`, `todo.md`, `progress.md`, `summary.md`, `final_report.md`... Soon your project root is a landfill of single-use files no one asked for and no one maintains.

Worse, different agents (Claude Code, Codex, Cursor) all write their own detritus. The problem is not Markdown. The problem is **no ownership, no lifecycle, no reusable value.**

Tidy Skill does not ban files. It gives every artifact a purpose, a place, and a lifetime.

---

## What It Does

| Capability | Description |
|---|---|
| **Artifact Intent Check** | Forces agents to justify every file before creation |
| **File generation rules** | Prevents generic Markdown from landing in project root |
| **Repo hygiene scoring** | Scores your repo 0–100 across 6 dimensions |
| **Workspace hygiene audit** | Scans multiple repos (with permission) for agent artifacts |
| **Conservative cleanup** | DryRun-first; only cleans `.agent_tmp/` and `.agent_reports/` by default |
| **Agent rules templates** | AGENTS.md, CLAUDE.md, Cursor Rules — drop-in and use |

---

## Core Idea

A file is not garbage because it is Markdown. It becomes garbage when it has **no intent, no owner, no reader, no lifecycle, and no reusable value.**

> 不治理 Markdown，治理无归属、无生命周期、无复用价值的 Agent 产物。

---

## Quick Start

### 1. Audit a repo

```powershell
cd scripts/
.\audit-agent-artifacts.ps1 -Root "C:\path\to\your\project"
```

This produces a Markdown report. No files are modified.

### 2. Score repo hygiene

```powershell
.\score-repo-hygiene.ps1 -Root "C:\path\to\your\project"
```

Gets a 0–100 hygiene score with breakdown.

### 3. Dry-run cleanup

```powershell
.\clean-agent-artifacts.ps1 -Root "C:\path\to\your\project"
```

Preview what would be cleaned. Nothing is deleted.

### 4. Add agent rules to your project

```bash
cp templates/AGENTS.md /path/to/project/AGENTS.md
cp templates/cursor-rule.mdc /path/to/project/.cursor/rules/agent-tidy.mdc
```

---

## Install as a Skill

If your agent platform supports Skills (`.skill` directories), link or copy this directory:

```bash
# Link as a skill (macOS/Linux)
ln -s /path/to/tidy-skill ~/.your-agent/skills/tidy-skill

# Copy as a skill
cp -r /path/to/tidy-skill ~/.your-agent/skills/tidy-skill
```

---

## Manual Install Paths

### Claude Code

```bash
cp templates/CLAUDE.md /path/to/your/project/CLAUDE.md
```

### Cursor

```bash
cp templates/cursor-rule.mdc /path/to/your/project/.cursor/rules/agent-tidy.mdc
```

### Any Agent

```bash
cp templates/AGENTS.md /path/to/your/project/AGENTS.md
```

### Full Policy

```bash
cp templates/artifact-governance-policy.md /path/to/your/project/docs/
```

---

## Use in Your Repo

Recommended `.gitignore` entries:

```gitignore
.agent_tmp/
.agent_reports/
```

Recommended project layout:

```
project/
├─ AGENTS.md
├─ .agent_tmp/          # temporary agent files — auto-cleanable
├─ .agent_reports/      # user-requested reports — 30-day retention
├─ README.md
├─ docs/                # formal documentation — protected
└─ src/
```

---

## Artifact Intent Check

Before creating any file, every agent must run this check:

```
Artifact Intent Check
─────────────────────
1. User requested a file?           yes / no
2. Purpose:
3. Reader:
4. Expected lifetime:               session / days / persistent / formal-doc
5. Destination path:
6. Why a chat response is not enough:
7. Class:                           temporary / persistent / formal-documentation
8. Should this be in .gitignore?    yes / no
```

If any field cannot be answered confidently, **do not create the file.**

---

## Repo Hygiene Score

Tidy Skill can score your repository on a 0–100 scale across six dimensions:

| Dimension | Weight | What it measures |
|---|---|---|
| Root cleanliness | 25% | Are generic plan/todo/summary files littering the root? |
| Artifact placement | 20% | Are temp files in `.agent_tmp/`? Reports in `.agent_reports/`? |
| Protected docs clarity | 15% | Are README, LICENSE, docs/ well-structured? |
| Git hygiene | 15% | Are artifact dirs gitignored? |
| Agent state isolation | 15% | Are tool state dirs separate from project files? |
| Cleanup readiness | 10% | Is there a clear cleanup path? |

| Score | Rating |
|---|---|
| 90–100 | Clean |
| 70–89 | Mostly clean |
| 50–69 | Needs tidy-up |
| 0–49 | Artifact landfill |

---

## Workspace Hygiene Audit

For multi-repo setups, `audit-workspace-hygiene.ps1` scans a user-specified directory:

```powershell
.\audit-workspace-hygiene.ps1 -Root "E:\1_Code\Projects"
```

What it reports:
- Hygiene score per repo
- Top 10 messiest repos
- Most common suspicious filenames
- `.agent_tmp` / `.agent_reports` adoption
- Global optimization suggestions

**Privacy:** The root must be explicitly specified. The script never defaults to `C:\` or `$HOME`. No file contents are read. No data is uploaded.

---

## Safe Cleanup

Every cleanup script follows these rules:

1. **DryRun first.** Preview what would be deleted. Nothing happens without confirmation.
2. **Default scope.** Only `.agent_tmp/` (7+ days old) and `.agent_reports/` (30+ days old).
3. **Root-level suspicious files?** Reported, not deleted. Use `-ConfirmClean` to include them.
4. **Protected files?** Never touched. See the full list below.

---

## What It Will Never Delete by Default

```
README.md, README.*.md
CHANGELOG.md
LICENSE, LICENSE.*
CONTRIBUTING.md
CODE_OF_CONDUCT.md
SECURITY.md
Everything under docs/
Any Git-tracked file outside .agent_tmp/ or .agent_reports/
Source code (src/, lib/, app/)
Tool state (.claude/, .cursor/, .codex/, .vscode/, *.sqlite)
```

---

## Examples

See [examples/bad-artifacts.md](examples/bad-artifacts.md) and [examples/good-artifacts.md](examples/good-artifacts.md) for detailed walkthroughs.

### Bad artifacts

```
./plan.md                 → generic, no lifecycle, should have been chat
./summary.md              → self-congratulatory, no reader
./final_report.md         → ditto
./implementation_plan.md  → misclassified, no home
```

### Good artifacts

```
.agent_reports/migration_plan_2026-06-03.md  → user asked, scoped, dated
docs/deployment.md                            → formal doc, correct location
.agent_tmp/refactor_steps_2026-06-03.md       → temporary, will be cleaned
```

---

## Scripts

| Script | Purpose | Safety |
|---|---|---|
| `audit-agent-artifacts.ps1` | Read-only repo audit | Never modifies files |
| `score-repo-hygiene.ps1` | Repo hygiene score (0–100) | Read-only |
| `audit-workspace-hygiene.ps1` | Multi-repo workspace scan | Read-only, explicit root |
| `clean-agent-artifacts.ps1` | Conservative cleanup | Defaults to DryRun |
| `clean-agent-artifacts.bat` | Windows double-click wrapper | DryRun by default |

All scripts are PowerShell-based, require no dependencies, work offline, and never upload data.

---

## Recommended Project Layout

```
project/
├─ AGENTS.md
├─ .agent_tmp/          # agent temp files — gitignored, auto-cleanable
├─ .agent_reports/      # user-requested reports — gitignored, 30-day retention
├─ README.md
├─ docs/                # formal documentation — versioned, protected
└─ src/
```

---

## FAQ

**Q: Will this delete my team's documentation?**  
No. Everything under `docs/`, plus `README.md`, `CHANGELOG.md`, `LICENSE`, etc., is protected.

**Q: What if I want to keep a report permanently?**  
Move it from `.agent_reports/` to `docs/` or remove it from `.gitignore`.

**Q: Does this work outside my project root?**  
Yes. `audit-workspace-hygiene.ps1` can scan multiple repos. You must specify the root path. It never scans `C:\` or `$HOME` without explicit instruction.

**Q: Does this work on Mac/Linux?**  
Yes. PowerShell 7+ runs on macOS and Linux. All scripts are cross-platform compatible.

**Q: Can I run this automatically every week?**  
The scripts are safe for scheduling. You can configure Windows Task Scheduler or cron manually — Tidy Skill will **never** register one for you.

**Q: Why PowerShell and not Python?**  
Zero dependencies. PowerShell ships with Windows. PowerShell 7 is cross-platform. No `pip install`, no virtualenv, no runtime configuration.

---

## Roadmap

- **Pre-commit hook integration** — auto-audit before commits
- **CI/CD pipeline integration** — hygiene checks in GitHub Actions
- **Bash/Python script ports** — for non-PowerShell environments
- **Custom scoring weights** — user-configurable hygiene dimensions
- **Plugin ecosystem** — MCP server for real-time agent governance

---

## License

MIT — see [LICENSE](LICENSE).

Copyright (c) 2026 Tidy Skill contributors
