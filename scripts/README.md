# Tidy Skill — Scripts

## Overview

| Script | Purpose | Safety |
|---|---|---|
| `audit-agent-artifacts.ps1` | Read-only repo audit | Never modifies files |
| `score-repo-hygiene.ps1` | Repo hygiene score (0–100) | Read-only |
| `audit-workspace-hygiene.ps1` | Multi-repo workspace scan | Read-only, explicit root |
| `clean-agent-artifacts.ps1` | Conservative cleanup | Defaults to DryRun |
| `clean-agent-artifacts.bat` | Windows double-click wrapper | DryRun by default |

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

Scores a repository on a 0–100 scale across six dimensions.

```powershell
powershell -ExecutionPolicy Bypass -File score-repo-hygiene.ps1 -Root "C:\path\to\project"
```

See [references/hygiene-scoring-model.md](../references/hygiene-scoring-model.md) for details.

---

## audit-workspace-hygiene.ps1

Scans multiple Git repositories under a workspace root. User must explicitly specify the root.

```powershell
powershell -ExecutionPolicy Bypass -File audit-workspace-hygiene.ps1 -Root "E:\1_Code\Projects"
```

**Privacy:** Never defaults to `C:\` or `$HOME`. Never reads file contents. No upload.

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

**Note:** Tidy Skill does NOT register scheduled tasks for you. The above is guidance only.

---

## Safety

- All scripts default to read-only or DryRun mode.
- No administrator privileges required.
- No network access required.
- No data is uploaded or transmitted.
