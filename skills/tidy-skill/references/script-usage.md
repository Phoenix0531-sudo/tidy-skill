# 洁癖.skill Scripts

## Overview

| Script | Purpose | Safety |
|---|---|---|
| `score_repo_hygiene.py` | Portable repo hygiene score (0-100) | Python, dependency-free, read-only |
| `audit_agent_artifacts.py` | Portable agent artifact audit | Python, dependency-free, read-only |
| `audit_dev_environment.py` | Portable dev environment audit | Python, dependency-free, read-only |
| `audit_workspace_hygiene.py` | Portable multi-repo workspace audit | Python, dependency-free, read-only, explicit root |
| `policy_loader.py` | Shared policy defaults + `.tidy-skill.json` loader | Library module (no CLI) |
| `Policy.ps1` | PowerShell policy helpers (dot-sourced by hygiene scripts) | Library module (no CLI) |
| `classify_artifact.py` | Pre-write Class A–E path classifier | Python, dependency-free, read-only |
| `hygiene_snapshot.py` | Score history save/compare + CI gate | Writes only under history dir (default `.agent_reports/hygiene-history/`) |
| `tidy_doctor.py` | One-shot skill + hygiene doctor / gate | Python, dependency-free, read-only |
| `audit-agent-artifacts.ps1` | Read-only repo audit | Never modifies files |
| `score-repo-hygiene.ps1` | Windows repo hygiene score (0-100) | Read-only |
| `audit-workspace-hygiene.ps1` | Multi-repo workspace scan | Read-only, explicit root |
| `audit-dev-environment.ps1` | Windows development environment audit | Read-only, explicit scope |
| `clean-agent-artifacts.ps1` | Conservative cleanup | Defaults to DryRun |
| `clean-agent-artifacts.bat` | Windows double-click wrapper | DryRun by default |
| `install-local.ps1` | Local skill install and self-check (Codex/Claude/Cursor/Pi/OpenCode) | DryRun by default |
| `install-rule-template.ps1` | Rule template installer | DryRun by default |
| `hooks/stop-hygiene-check.py` | End-of-task read-only stop check | Reports only |

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
| `--weights` | No | none | Optional JSON dimension weight factors |
| `--policy` | No | auto | Optional policy JSON; else discovers `.tidy-skill.json` |
| `--json` | No | false | Print JSON output |

---

## Project policy (`.tidy-skill.json`)

Optional project file discovered automatically by scoring, audit, doctor, classify, and gate:

| Field | Effect |
|---|---|
| `forbidden_root_globs` / `forbidden_root_regex` | Extra root process-Markdown patterns |
| `protected_root_globs` / `protected_root_regex` | Extra protected formal docs |
| `ignore_root_globs` | Root names that must **not** count as forbidden |
| `min_score` | CI gate threshold for `hygiene_snapshot.py gate` / doctor |
| `require_agent_dirs` | Require `.agent_tmp/` and `.agent_reports/` for gate/doctor |

Example: `references/tidy-skill.policy.example.json`. Copy to repo root as `.tidy-skill.json` or `tidy-skill.policy.json`.

Python and PowerShell hygiene scripts both honor the same schema via `policy_loader.py` / `Policy.ps1`.

---

## classify_artifact.py

Classify a path into Classes A–E **before** writing. Does not create files.

```powershell
python classify_artifact.py plan.md --root "." --json
```

| Parameter | Required | Default | Description |
|---|---|---|---|
| `path` | Yes | — | File or directory path (may not exist yet) |
| `--root` | No | `.` | Repository root for relative classification |
| `--policy` | No | auto | Optional policy JSON |
| `--json` | No | false | Print JSON output |

---

## hygiene_snapshot.py

Save score snapshots, compare deltas, and gate CI on `min_score`.

```powershell
python hygiene_snapshot.py save --root "." --label baseline
python hygiene_snapshot.py compare --root "."
python hygiene_snapshot.py list --root "." --json
python hygiene_snapshot.py gate --root "." --min-score 80 --json
```

Default history dir: `.agent_reports/hygiene-history/`. Subcommands: `save`, `list`, `compare`, `gate` (exit `2` on fail).

---

## tidy_doctor.py

One-shot package + hygiene doctor. Exit `0` healthy/warnings, `1` usage error, `2` hygiene/policy fail.

```powershell
python tidy_doctor.py --root "." --json
python tidy_doctor.py --root "." --min-score 80 --report-path ".agent_reports/doctor.md"
```

| Parameter | Required | Default | Description |
|---|---|---|---|
| `--root` | No | `.` | Repository root |
| `--skill-dir` | No | package parent | Installed or source skill directory |
| `--policy` | No | auto | Optional policy JSON |
| `--min-score` | No | policy/`none` | Fail if score below this |
| `--report-path` | No | none | Optional Markdown report |
| `--strict` | No | false | Treat warnings as failures |
| `--json` | No | false | Print JSON output |

---

## audit_workspace_hygiene.py

Portable multi-repo scan. Requires an explicit root that contains Git repositories.

```powershell
python audit_workspace_hygiene.py --root "D:\Projects" --report-path ".agent_reports\workspace.md" --json
```

| Parameter | Required | Default | Description |
|---|---|---|---|
| `--root` | Yes | — | Parent directory containing Git repos |
| `--max-depth` | No | 2 | How deep to search for `.git` |
| `--policy` | No | per-repo | Shared policy JSON; else each repo discovers its own |
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
| `--policy` | No | auto | Optional policy JSON; else discovers `.tidy-skill.json` |
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
| `-Policy` | No | auto | Optional policy JSON; else discovers `.tidy-skill.json` |

---

## audit_dev_environment.py

Portable development-environment audit for package caches, model caches, browser runtimes, path-like cache environment variables, and project-local cache folders. It does not inspect Windows WSL2/Docker VHDX files; use `audit-dev-environment.ps1` for that.

```powershell
python audit_dev_environment.py --root "C:\path\to\workspace" --report-path "C:\reports\dev_environment.md"
```

**Parameters:**

| Parameter | Required | Default | Description |
|---|---|---|---|
| `--root` | No | none | Project/workspace root to scan; may be repeated |
| `--report-path` | No | none | Optional Markdown report path |
| `--max-depth` | No | 3 | Maximum project cache scan depth |
| `--json` | No | false | Print JSON output |

**Report structure:** `Overview Cards`, `Top 10 Optimization Plan`, `Findings`, `Safe Suggestions`, and `Manual / Risky Operations`.

---

## score-repo-hygiene.ps1

Windows PowerShell version of repo scoring. Use it when Python is unavailable or when staying inside a PowerShell workflow.

```powershell
powershell -ExecutionPolicy Bypass -File score-repo-hygiene.ps1 -Root "C:\path\to\project"
powershell -ExecutionPolicy Bypass -File score-repo-hygiene.ps1 -Root "C:\path\to\project" -Policy ".tidy-skill.json"
```

Optional `-Policy` discovers the same schema as the Python scorer. See [hygiene-scoring-model.md](hygiene-scoring-model.md) for details.

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

- `Overview Cards`: score, C-drive risk, WSL/Docker risk, and model cache risk.
- `Top 10 Optimization Plan`: why each item matters, whether it can be touched, and the next step.
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
- Git-tracked files

---

## clean-agent-artifacts.bat

Double-click wrapper that runs the PowerShell script in DryRun mode.

- **Double-click:** Run on current directory.
- **Drag-and-drop a folder:** Run on that folder.

---

## install-local.ps1

Installs the packaged skill into local Codex and Claude skill directories, with metadata self-checks for `SKILL.md` and `agents/openai.yaml`.

```powershell
# Self-check only
powershell -ExecutionPolicy Bypass -File install-local.ps1 -SelfCheckOnly

# Preview local install
powershell -ExecutionPolicy Bypass -File install-local.ps1

# Actual install to both Codex and Claude
powershell -ExecutionPolicy Bypass -File install-local.ps1 -DryRun:$false -Force
```

**Safety:** Defaults to DryRun. Existing installed skill folders are replaced only when `-DryRun:$false -Force` is provided.

---

## install-rule-template.ps1

Installs rule templates into a target project.

```powershell
# Preview all template installs
powershell -ExecutionPolicy Bypass -File install-rule-template.ps1 -TargetRoot "C:\path\to\project"

# Install only AGENTS.md
powershell -ExecutionPolicy Bypass -File install-rule-template.ps1 -TargetRoot "C:\path\to\project" -Template AGENTS -DryRun:$false

# Replace an existing Cursor rule
powershell -ExecutionPolicy Bypass -File install-rule-template.ps1 -TargetRoot "C:\path\to\project" -Template cursor -DryRun:$false -Force
```

Targets:

| Template | Destination |
|---|---|
| `AGENTS` | `AGENTS.md` |
| `CLAUDE` | `CLAUDE.md` |
| `cursor` | `.cursor/rules/tidy-skill.mdc` |
| `all` | all of the above |

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
