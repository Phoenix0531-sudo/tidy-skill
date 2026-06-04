# Hygiene Scoring Model Reference

This document describes the repo hygiene scoring model used by `scripts/score-repo-hygiene.ps1`.

---

## Overview

The hygiene score is a 0–100 scale that evaluates how well a repository manages AI agent artifacts. Higher is cleaner.

| Score | Rating (en) | Rating (zh) | Meaning |
|---|---|---|---|
| 90–100 | Clean | 很干净 | Excellent artifact governance |
| 70–89 | Mostly clean | 基本干净 | Minor issues |
| 50–69 | Needs tidy-up | 需要整理 | Significant artifact problems |
| 0–49 | Artifact landfill | Agent 产物垃圾场 | Severe pollution |

---

## Scoring Dimensions

### 1. Root Cleanliness (25 pts)

**What it measures:** Whether the project root is free of generic agent-produce Markdown files.

| Condition | Points |
|---|---|
| No suspicious files in root | 25 |
| 1–2 suspicious files | 18 |
| 3–5 suspicious files | 10 |
| 6+ suspicious files | 5 |

**Suspicious patterns:** `plan.md`, `todo.md`, `summary.md`, `report.md`, `final_report.md`, `implementation_plan.md`, `migration_plan.md`, `audit_report.md`, `cleanup_report.md`, `task_list.md`, `progress.md`, `work_summary.md`, `changes_summary.md`, `notes.md`, `lessons.md`, `*_summary.md`, `*_report.md`, `*_plan.md`

### 2. Artifact Placement (20 pts)

**What it measures:** Whether temporary and persistent artifacts use the correct directories.

| Condition | Points |
|---|---|
| Has `.agent_tmp/` | 8 |
| Has `.agent_reports/` | 7 |
| No suspicious files in root | 5 |
| 1–3 suspicious files in root | 2 |
| 4+ suspicious files in root | 0 |

### 3. Protected Docs Clarity (15 pts)

**What it measures:** Whether the project has standard documentation files.

| Condition | Points |
|---|---|
| Has `README.md` | 5 |
| Has `LICENSE` | 4 |
| Has `CHANGELOG.md` | 3 |
| Has `docs/` directory | 3 |

### 4. Git Hygiene (15 pts)

**What it measures:** Whether artifact directories are properly gitignored.

| Condition | Points |
|---|---|
| Is a Git repository | 5 |
| Has `.gitignore` file | 3 |
| `.gitignore` excludes `.agent_tmp/` | 4 |
| `.gitignore` excludes `.agent_reports/` | 3 |

### 5. Agent State Isolation (15 pts)

**What it measures:** Whether tool state directories are separated from project files.

| Condition | Points |
|---|---|
| Default score | 15 |
| Deduction only if no doc structure AND >3 state dirs | −3 (max) |

### 6. Cleanup Readiness (10 pts)

**What it measures:** Whether the repo has a clear cleanup path.

| Condition | Points |
|---|---|
| Has `.agent_tmp/` | 3 |
| Has `.agent_reports/` | 3 |
| No suspicious root files | 2 |
| Has temporary files with retention policy | 2 |

---

## Calculation

```
Total = RootCleanliness + ArtifactPlacement + ProtectedDocsClarity + GitHygiene + AgentStateIsolation + CleanupReadiness
Total = min(100, max(0, Total))
```

---

## Interpretation

### Clean (90–100)
- Well-maintained project with clear documentation structure
- Agent artifacts are properly classified and placed
- `.gitignore` correctly excludes temporary directories
- No generic Markdown in project root

**Action:** Maintain. Run occasional audits to catch regressions.

### Mostly clean (70–89)
- Minor issues: maybe a stray file, missing CHANGELOG, or incomplete gitignore
- Core structure is sound

**Action:** Run audit, address listed items.

### Needs tidy-up (50–69)
- Multiple suspicious files in root
- Missing `.agent_tmp/` and/or `.agent_reports/`
- README or LICENSE may be missing
- `.gitignore` may not exclude artifact directories

**Action:** Run audit, clean up, add agent rules (AGENTS.md).

### Artifact landfill (0–49)
- Project root is heavily polluted with agent-produce files
- No documentation structure
- No cleanup paths exist
Likely a project where multiple agents have worked without governance

**Action:** Full remediation: audit → clean → add templates → establish rules.
