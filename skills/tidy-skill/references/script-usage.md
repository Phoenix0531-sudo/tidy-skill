# 洁癖.skill Scripts

## Overview

| Script | Purpose | Safety |
|---|---|---|
| `score_repo_hygiene.py` | Portable repo hygiene score (0-100) | Python, dependency-free, read-only |
| `audit_agent_artifacts.py` | Portable agent artifact audit | Python, dependency-free, read-only |
| `audit-agent-artifacts.ps1` | Read-only repo audit | Never modifies files |
| `score-repo-hygiene.ps1` | Windows repo hygiene score (0-100) | Read-only |
| `audit-workspace-hygiene.ps1` | Multi-repo workspace scan | Read-only, explicit root |
| `audit-dev-environment.ps1` | Windows development environment audit | Read-only, explicit scope |
| `clean-agent-artifacts.ps1` | Conservative cleanup | Defaults to DryRun |
| `clean-agent-artifacts.bat` | Windows double-click wrapper | DryRun by default |

---

## score_repo_hygiene.py

Scores a repository on a 0-100 scale across six dimensions. Prefer this script for routine cross-platform repo checks.

```powershell
python score_repo_hygiene.py --root "C:\path\to\project" --report-path "C:\reports\repo_hygiene.md"
```

**Parameters:**

| Parameter | Required | Default | Description |
|---|---|---|---|
| `--root` | No | `.` | Project root path |
| `--report-path` | No | none | Optional Markdown report path |
| `--json` | No | false | Print JSON output |

---

## audit_agent_artifacts.py

Portable single-repository artifact audit. Prefer this script for cross-platform checks.

```powershell
python audit_agent_artifacts.py --root "C:\path\to\project" --report-path "C:\reports\agent_artifacts.md"
```

**Parameters:**

| Parameter | Required | Default | Description |
|---|---|---|---|
| `--root` | No | `.` | Project root path |
| `--report-path` | No | none | Optional Markdown report path |
| `--max-depth` | No | 3 | Maximum directory depth |
| `--json` | No | false | Print JSON output |

---

## audit-agent-artifacts.ps1

Scans a project directory and produces a Markdown audit report.

```powershell
powershell -ExecutionPolicy Bypass -File audit-agent-artifacts.ps1 -Root "C:\path\to\project"
```

**Parameters:**

| Parameter | Required | Default | Description |
|---|---|---|---|
| `-Root` | Yes | — | Project root path |
| `-ReportPath` | No | `.agent_reports/audit_<timestamp>.md` | Output report path |
| `-MaxDepth` | No | 3 | Maximum scan depth |

---

## score-repo-hygiene.ps1

Windows PowerShell version of repo scoring. Use it when Python is unavailable or when staying inside a PowerShell workflow.

```powershell
powershell -ExecutionPolicy Bypass -File score-repo-hygiene.ps1 -Root "C:\path\to\project"
```

See [hygiene-scoring-model.md](hygiene-scoring-model.md) for details.

---

## audit-workspace-hygiene.ps1

Scans multiple Git repositories under a workspace root. User must explicitly specify the root.

```powershell
powershell -ExecutionPolicy Bypass -File audit-workspace-hygiene.ps1 -Root "E:\1_Code\Projects"
```

**Privacy:** Never defaults to `C:\` or `$HOME`. Never reads file contents. No upload.

---

## audit-dev-environment.ps1

Audits selected development roots and optional user-profile cache locations for local agent-environment hygiene: runtimes, package caches, WSL2/Docker footprint, model caches, agent/IDE state, path-like cache environment variables, and project-level cache folders.

```powershell
powershell -ExecutionPolicy Bypass -File audit-dev-environment.ps1 -Roots "E:\1_Code" -ReportPath "C:\reports\dev_environment.md"
```

**Privacy:** Read-only and scoped. It does not upload data, modify environment variables, edit `.wslconfig`, compact VHDX files, move Docker data, or move caches.

**Report structure:**

- `Findings`: observed local facts.
- `Safe Suggestions`: low-risk next steps.
- `Manual / Risky Operations`: WSL export/import, VHDX compaction, Docker data relocation, `.wslconfig` edits, and model cache relocation.

---

## clean-agent-artifacts.ps1

Cleans temporary artifacts with safety guarantees.

```powershell
# DryRun (default) — preview only
powershell -ExecutionPolicy Bypass -File clean-agent-artifacts.ps1 -Root "C:\path\to\project"

# Actual cleanup
powershell -ExecutionPolicy Bypass -File clean-agent-artifacts.ps1 -Root "C:\path\to\project" -DryRun:$false
```

**Parameters:**

| Parameter | Required | Default | Description |
|---|---|---|---|
| `-Root` | Yes | — | Project root path |
| `-TmpRetentionDays` | No | 7 | Age limit for `.agent_tmp/` files |
| `-ReportRetentionDays` | No | 30 | Age limit for `.agent_reports/` files |
| `-DryRun` | No | `$true` | When `$true`, preview only |
| `-ConfirmClean` | No | `$false` | Also clean root-level suspicious files |

**What gets cleaned (with defaults):**
1. Files in `.agent_tmp/` older than 7 days.
2. Files in `.agent_reports/` older than 30 days.
3. (With `-ConfirmClean`) Root-level suspicious Markdown files.

**What NEVER gets cleaned:**
- `README.md`, `CHANGELOG.md`, `LICENSE`, `CONTRIBUTING.md`
- Everything under `docs/`
- Source code (`src/`, `lib/`, `app/`, etc.)
- Tool state (`.claude/`, `.cursor/`, `.vscode/`, `*.sqlite`, etc.)
- Git-tracked files outside `.agent_tmp/` and `.agent_reports/`

---

## clean-agent-artifacts.bat

Double-click wrapper that runs the PowerShell script in DryRun mode.

- **Double-click:** Run on current directory.
- **Drag-and-drop a folder:** Run on that folder.

---

## Scheduling

The scripts are safe to schedule. If you want automated weekly cleanup:

```powershell
# Example: weekly cleanup via Windows Task Scheduler (manual setup)
# Action: powershell -ExecutionPolicy Bypass -File "C:\path\to\clean-agent-artifacts.ps1" -Root "C:\path\to\project" -DryRun:$false
```

**Note:** 洁癖.skill does NOT register scheduled tasks for you. The above is guidance only.

---

## Safety

- All scripts default to read-only or DryRun mode.
- No administrator privileges required.
- No network access required.
- No data is uploaded or transmitted.
