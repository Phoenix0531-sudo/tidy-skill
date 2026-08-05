# Artifact Classification Reference

This document defines the five-class taxonomy used by 洁癖.skill to classify all files an AI coding agent might create or encounter.

---

## A. Formal Documentation — Protected by Default

Files in this class are part of the project's official record. They have long-term value, clear readers, and are maintained like source code.

### Examples

| File/Directory | Typical location | Notes |
|---|---|---|
| `README.md` | Project root | Project entry point |
| `README.*.md` | Project root | Localized versions |
| `CHANGELOG.md` | Project root | Release history |
| `LICENSE` | Project root | License text |
| `LICENSE.*` | Project root | License variants |
| `CONTRIBUTING.md` | Project root | Contribution guide |
| `CODE_OF_CONDUCT.md` | Project root | Community standards |
| `SECURITY.md` | Project root | Security policy |
| Everything under `docs/` | `docs/` | All subdirectories included |
| `architecture.md` | `docs/` or root | Architecture decisions |
| `design.md` | `docs/` or root | Design documents |
| `spec.md` | `docs/` or root | Specifications |
| `api.md` | `docs/` | API documentation |
| `deployment.md` | `docs/` | Deployment guide |
| User hand-written notes | Anywhere | Recognizable by style/content |
| Product requirements docs | `docs/` | PRDs |
| Team convention documents | `docs/` | Team standards |

### Rules

- **Never** auto-delete.
- **Never** auto-rewrite.
- Only modify when explicitly requested by the user.
- Included in audit reports as "protected" (informational only).

---

## B. User-requested Deliverables — Allowed but Must Have a Home

These are files the user explicitly asked an agent to create. They are not garbage, but they must be placed in the correct location.

### Examples

| File | Why it's B-class |
|---|---|
| `.agent_reports/security_audit_2026-06-03.md` | User asked for a security audit report |
| `.agent_reports/migration_plan_v2_to_v3.md` | User asked for a migration plan |
| `.agent_reports/dependency_audit_2026-06-01.md` | User asked for a dependency audit |
| `.agent_reports/research_langchain_vs_llamaindex.md` | User asked for research |
| `docs/installation_guide.md` | User asked for install docs (became formal) |

### Rules

- Allowed to exist.
- Must live in a known directory (`.agent_reports/`, `docs/`, or user-specified).
- **Never** dropped in the project root by default.
- Filename must include task name and date.
- Default retention: 30 days in `.agent_reports/`.
- Can be promoted to `docs/` if it gains long-term value.

---

## C. Temporary Working Artifacts — `.agent_tmp/` Only

These are intermediate files that help the agent track its work during a task. They have value only during the task execution and should be cleaned afterward.

### Common Examples

| File | Purpose | Typical use |
|---|---|---|
| `plan.md` | Task plan | Active during task, obsolete after |
| `todo.md` | Task checklist | Updated during task, obsolete after |
| `notes.md` | Working notes | Scratch space, variable quality |
| `scratch.md` | Rough notes | Highly disposable |
| `implementation_plan.md` | Step-by-step plan | Active during implementation |
| `task_list.md` | Subtask tracking | Manual Kanban |
| `progress.md` | Status tracking | Updated during long tasks |

### Rules

- **Must** live in `.agent_tmp/`.
- **Must not** be created in the project root.
- **Must not** be committed to Git.
- Default retention: 7 days.
- Agent should clean its own entries at task end.
- Not included in commit history.

---

## D. Agent Self-congratulatory Artifacts — Do Not Create by Default

These files exist only to document what the agent did. They typically restate the chat conversation, are written for no specific reader, and have no follow-up use.

### Examples

| File | Why it's D-class |
|---|---|
| `summary.md` | Restates what happened in the chat |
| `final_report.md` | Summarizes completed work (no one reads it) |
| `task_complete.md` | "I finished the task" — already said in chat |
| `lessons.md` | Lessons learned — if real, belongs in team wiki |
| `cleanup_summary.md` | "I cleaned up" — cleanup script already logs |
| `work_summary.md` | Duplicates git log, commit, and PR |
| `changes_summary.md` | Duplicates the diff |
| `done.md` | The chat is the done signal |

### Rules

- **Do not create** unless the user explicitly asks for a file.
- If the user asks "what did you do?" — answer in the chat.
- If an actual record is needed, use: commit message, PR description, or changelog entry.

---

## E. Tool State — Out of Scope, Do Not Touch

These are files and directories created and managed by AI coding tools, IDEs, and editors. They are not Markdown debris and are not governed by 洁癖.skill.

### Examples

| Path | Tool |
|---|---|
| `.codex/` | Codex CLI |
| `.claude/` | Claude Code |
| `.cursor/` | Cursor editor |
| `.vscode/` | VS Code |
| `.idea/` | JetBrains IDEs |
| `*.sqlite` | Various tools (vector stores, cache) |
| `state.json` | Various tools |
| `session.json` | Various tools |
| `auth-token` | Various tools |
| `workspaceStorage` | VS Code |
| `globalStorage` | VS Code |
| `History` | Various tools |

### Rules

- **Never** delete.
- **Never** audit as "suspicious".
- **Never** report as "junk".
- **Never** move or rename.
- **Never** modify content.

---

## Quick Classification Guide

| Question | If yes → class |
|---|---|
| Is this a standard project doc (README, LICENSE, CHANGELOG)? | A — Formal Documentation |
| Is this in `docs/` and maintained like source code? | A — Formal Documentation |
| Did the user explicitly ask for this file? | B — User-requested Deliverable |
| Is this a temporary plan, todo, or note for current task? | C — Temporary Working Artifact |
| Is this a self-congratulatory summary of what the agent did? | D — Self-congratulatory (do not create) |
| Is this a tool state directory or file? | E — Tool State (out of scope) |
| Do I not know what this is? | Stop and ask the user |

Machine-check a proposed path before writing:

```bash
python scripts/classify_artifact.py path/to/proposed.md --root . --json
```

Optional project overrides: `.tidy-skill.json` (see `tidy-skill.policy.example.json`).

---

## Change Log

| Date | Change |
|---|---|
| 2026-06-03 | Initial version |
| 2026-08-05 | Document `classify_artifact.py` + project policy hook |
