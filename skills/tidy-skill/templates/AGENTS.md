# AGENTS.md — Agent File Hygiene Rules for This Project

This file defines how AI coding agents should handle files in this project.
It is part of the 洁癖.skill governance framework.

---

## Core Rule

**Do not create Markdown files in the project root unless the user explicitly requests a file with a specific name.**

Temporary plans, todos, notes, and progress belong in the chat — not on disk.

---

## File Classification

| What | Where it lives | Can auto-delete? |
|---|---|---|
| Formal docs (`README.md`, `docs/`, `LICENSE`, `CHANGELOG.md`) | Project doc structure | Never |
| User-requested deliverables (reports, migration plans, audits) | `.agent_reports/` | After 30 days |
| Temporary working artifacts (plan, todo, notes, scratch) | `.agent_tmp/` | After 7 days |
| Agent self-congratulatory files (summary, final_report, etc.) | **Do not create** | N/A |

---

## Artifact Intent Check

Before creating any new file, the agent must answer:

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

If the answer to any of these is unclear — **do not create the file**.

---

## Forbidden Root-Level Filenames

The following files must **not** appear in the project root unless the user explicitly asks for that exact file:

```
todo.md
plan.md
notes.md
lessons.md
summary.md
report.md
final_report.md
implementation_plan.md
migration_plan.md
audit_report.md
cleanup_report.md
task_list.md
progress.md
work_summary.md
changes_summary.md
*_summary.md
*_report.md
*_plan.md
```

---

## Directory Layout

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

## End-of-Task Checklist

Before reporting "done":

1. Did I create any files? If yes, were each justified by an Artifact Intent Check?
2. Are any of my files in the project root that should not be?
3. Are any of my files in `.agent_tmp/` that I can safely remove now?
4. Did I avoid creating `summary.md` / `final_report.md` / `work_summary.md`?
5. If the user wants the result archived, did I propose a path under `.agent_reports/` or `docs/`?

---

## When in Doubt: Ask

If you cannot confidently classify a file or determine its lifecycle, **ask the user** before creating, modifying, or deleting it.
