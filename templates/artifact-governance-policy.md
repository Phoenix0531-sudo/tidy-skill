# Agent Artifact Governance Policy

**Part of:** [Tidy Skill](https://github.com/your-org/tidy-skill)
**Version:** 1.0
**Applies to:** All AI coding agents working on this project
**Purpose:** Define when, where, and how agents may create, retain, and remove files

---

## 1. Scope

This policy governs all files produced by AI coding agents (Claude Code, Codex, Cursor, Copilot, and similar tools) during task execution. It covers Markdown reports, plans, summaries, notes, and any other non-source artifacts.

## 2. Classification

Every agent-created file belongs to one of five classes:

### A. Formal Documentation

| Attribute | Value |
|---|---|
| Examples | `README.md`, `CHANGELOG.md`, `LICENSE`, `CONTRIBUTING.md`, `docs/**`, architecture docs, design docs, API specs, deployment guides |
| Destination | `docs/` or project root (for repo-standard files) |
| Lifecycle | Permanent |
| Git-tracked | Yes |
| Auto-deletable | Never |

### B. User-requested Deliverables

| Attribute | Value |
|---|---|
| Examples | Audit report, migration plan, research write-up, installation guide, retrospective, config documentation |
| Destination | `.agent_reports/` or user-specified path |
| Lifecycle | 30 days (configurable) |
| Git-tracked | No (by default) |
| Auto-deletable | After retention period |

### C. Temporary Working Artifacts

| Attribute | Value |
|---|---|
| Examples | `plan.md`, `todo.md`, `notes.md`, `scratch.md`, `implementation_plan.md`, `task_list.md`, `progress.md` |
| Destination | `.agent_tmp/` |
| Lifecycle | 7 days (configurable) |
| Git-tracked | No |
| Auto-deletable | After retention period, or at task end |

### D. Agent Self-congratulatory Artifacts

| Attribute | Value |
|---|---|
| Examples | `summary.md`, `final_report.md`, `task_complete.md`, `lessons.md`, `cleanup_summary.md`, `work_summary.md`, `changes_summary.md` |
| Destination | **Do not create** |
| Lifecycle | N/A |
| Git-tracked | N/A |
| Auto-deletable | N/A |

**Rule:** These files typically restate chat content. They have no reader and no follow-up value. Default behavior: keep the summary in the chat.

### E. Tool State — Out of Scope

| Attribute | Value |
|---|---|
| Examples | `.codex/`, `.claude/`, `.cursor/`, `.vscode/`, `*.sqlite`, `state.json`, `session.json`, `auth-token`, `workspaceStorage`, `globalStorage`, `History` |
| Destination | Tool-owned directories |
| Lifecycle | Managed by the tool |
| Git-tracked | Should not be |
| Auto-deletable | Never by this policy |

## 3. Artifact Intent Check

Every agent must complete this check **before** creating any file outside `docs/`:

```
1. User requested a file?           yes / no
2. Purpose:
3. Reader:
4. Expected lifetime:               session / days / persistent / formal-doc
5. Destination path:
6. Why a chat response is not enough:
7. Class:                           temporary / persistent / formal-documentation
8. Should this be in .gitignore?    yes / no
```

**If any field cannot be answered confidently, do not create the file.**

## 4. Location Rules

| Content type | Allowed location | Forbidden location |
|---|---|---|
| Temporary artifacts | `.agent_tmp/` | Project root, `src/`, `docs/` |
| Persistent reports | `.agent_reports/`, user-specified path | Project root |
| Formal documentation | `docs/`, project root (repo-standard files) | `.agent_tmp/`, `.agent_reports/` |
| Agent self-congratulatory files | Nowhere | Everywhere |

## 5. Lifecycle and Retention

| Location | Default retention | Cleanup behavior |
|---|---|---|
| `.agent_tmp/` | 7 days from last modified | Auto-deleted by cleanup script |
| `.agent_reports/` | 30 days from creation | Auto-deleted by cleanup script if expired |
| `docs/` | Permanent | Never auto-deleted |

## 6. Cleanup Policy

### Allowed auto-cleanup
- Files in `.agent_tmp/` older than retention period.
- Files in `.agent_reports/` older than retention period.
- Explicit user-specified directories of agent temp files.

### Forbidden auto-cleanup
- Any file under `docs/`, `src/`, `lib/`, `app/`.
- `README.md`, `CHANGELOG.md`, `LICENSE`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`.
- Tool state directories (Class E).
- Git-tracked files not inside `.agent_tmp/` or `.agent_reports/`.
- Files of unknown origin in the project root.
- User personal notes or documents.

### Root-level suspicious files
Files like `plan.md`, `todo.md`, `summary.md`, `report.md` found in the project root should be **reported in an audit, not deleted automatically**. The user decides their fate.

## 7. Audit Policy

Audits are read-only. An audit should:
- Scan the project root for suspicious Markdown files matching forbidden patterns.
- List contents of `.agent_tmp/` and `.agent_reports/`.
- List formal documentation found (for confirmation).
- Suggest actions but never perform them.
- Skip `.git/`, `node_modules/`, `dist/`, `build/`, `target/`, `.venv/`, `venv/`.
- Never upload or transmit results.

## 8. Enforcement

- **Recommended:** Add `.agent_tmp/` and `.agent_reports/` to `.gitignore`.
- **Recommended:** Place `AGENTS.md` (or this policy) in the project root.
- **Recommended:** Run the audit script weekly or before code review.
- **Optional:** Configure Windows Task Scheduler to run cleanup weekly (not done by this policy).

## 9. Non-compliance

If an agent creates files violating this policy:
- Files will be reported by the next audit.
- The agent should be reminded of the Artifact Intent Check.
- Repeat violations indicate the agent configuration needs updating.

---

*This policy is part of the Tidy Skill. See the full project at https://github.com/your-org/tidy-skill*
