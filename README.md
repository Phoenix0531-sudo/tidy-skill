# Agent Tidy Skill

Stop AI agents from littering your repo with `plan.md`, `todo.md`, `summary.md`, and other throwaway artifacts.

**This is not a Markdown deleter.** It governs agent-generated artifacts that have **no ownership, no lifecycle, and no reusable value**.

[中文版](README.zh-CN.md)

---

## Why Agent Artifact Governance?

AI coding agents love to leave traces. A conversation produces a `plan.md`, a `todo.md`, a `progress.md`, a `summary.md`, a `final_report.md`... Soon your project root is a landfill of single-use files no one asked for and no one maintains.

This project does not ban Markdown. It establishes a framework for agents to decide:

1. Should this file exist?
2. What class does it belong to?
3. Where should it live?
4. How long should it stay?
5. When should it be deleted?

## What it solves

- Agents dumping generic Markdown in the project root.
- No distinction between temporary working files and formal documentation.
- No lifecycle for process artifacts.
- No audit trail for what an agent left behind.
- Cross-agent pollution (Claude + Codex + Cursor all writing their own files).

## What it does NOT solve

- Deleting formal documentation.
- Cleaning source code.
- Managing tool state (`.claude/`, `.cursor/`, `.vscode/`, `*.sqlite`, etc.).
- Replacing version control, issue trackers, or real documentation workflows.
- Full-disk or personal-folder file cleanup.

---

## Quick start

### 1. Copy the agent rules into your project

```bash
# Generic agent rules (works with any agent)
cp templates/AGENTS.md /path/to/your/project/AGENTS.md

# Claude Code specific
cp templates/CLAUDE.md /path/to/your/project/CLAUDE.md

# Cursor rules
cp templates/cursor-rule.mdc /path/to/your/project/.cursor/rules/agent-tidy.mdc
```

### 2. Run an audit

```powershell
powershell -ExecutionPolicy Bypass -File scripts/audit-agent-artifacts.ps1 -Root "C:\path\to\your\project"
```

This produces a Markdown report. No files are modified.

### 3. Run a dry-run cleanup

```powershell
# See what would be cleaned without deleting anything
powershell -ExecutionPolicy Bypass -File scripts/clean-agent-artifacts.ps1 -Root "C:\path\to\your\project" -DryRun
```

### 4. Apply the `.gitignore` entries

Add to your project's `.gitignore`:

```gitignore
.agent_tmp/
.agent_reports/
```

---

## File classification

| Class | Examples | Where it lives | Lifecycle | Can auto-delete? |
|---|---|---|---|---|
| **Formal Documentation** | `README.md`, `docs/`, `LICENSE` | Project docs structure | Permanent | Never |
| **User-requested Deliverables** | audit report, migration plan | `.agent_reports/` | 30 days (configurable) | After retention |
| **Temporary Working Artifacts** | plan, todo, notes, progress | `.agent_tmp/` | 7 days (configurable) | After retention |
| **Agent Self-congratulatory** | summary, final_report, work_summary | **Do not create** | N/A | N/A |
| **Tool State** | `.claude/`, `.cursor/`, `*.sqlite` | Tool's own dir | N/A | Never |

See [references/artifact-classification.md](references/artifact-classification.md) for the full taxonomy.

---

## Recommended project structure

```
project/
├─ AGENTS.md
├─ .agent_tmp/          # temporary agent files — auto-cleanable, gitignored
├─ .agent_reports/      # user-requested reports — 30-day retention, gitignored
├─ README.md
├─ docs/                # formal documentation — protected
└─ src/                 # source code
```

---

## Safety principles

1. **DryRun first.** All cleanup scripts default to read-only mode.
2. **No auto-delete of formal docs.** `README.md`, `CHANGELOG.md`, `LICENSE`, `CONTRIBUTING.md`, and `docs/` are protected.
3. **Root-level suspicious files are reported, not deleted.** The user decides.
4. **No system modifications.** No scheduled tasks, no registry changes, no admin rights required.
5. **No network.** Cleanup scripts work entirely offline.
6. **No uploads.** No telemetry, no log shipping, no environment capture.
7. **No dependencies.** Pure PowerShell and Batch — zero npm/pip installs.

---

## FAQ

**Q: Will this delete my team's documentation?**  
No. Formal documentation (anything under `docs/`, plus `README.md`, `CHANGELOG.md`, `LICENSE`, etc.) is protected.

**Q: What if I want to keep a report permanently?**  
Move it from `.agent_reports/` to `docs/` or outside `.gitignore`.

**Q: Does this work for non-Markdown agent artifacts?**  
The classification system and Artifact Intent Check apply to any file type. The audit script focuses on Markdown because that's the most common form of agent litter.

**Q: Can I run the cleanup automatically every week?**  
The scripts are designed to be safe for scheduled use. If you want to set up a Windows Task Scheduler entry, you can — but this project will **not** register one for you. See [scripts/README.md](scripts/README.md).

**Q: Does this work for Mac/Linux?**  
The audit and cleanup scripts are PowerShell-based and compatible with PowerShell 7+ on macOS and Linux. For pure shell alternatives, contributions are welcome.

**Q: Why PowerShell instead of Python?**  
No dependencies. PowerShell ships with Windows, and PowerShell 7 is cross-platform. No pip install, no virtualenv, no runtime setup.

---

## License

MIT — see [LICENSE](LICENSE).

Copyright (c) 2026 Agent Tidy Skill contributors
