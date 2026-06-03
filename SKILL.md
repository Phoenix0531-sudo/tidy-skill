---
name: Agent Tidy Skill
description: Governs AI-agent-generated artifacts — stops agents from littering project roots with plan.md, todo.md, summary.md. Provides classification rules, Artifact Intent Check, audit/cleanup scripts, and AGENTS.md/CLAUDE.md/Cursor Rules templates.
---

# Agent Tidy Skill

> Stop AI agents from littering your repo with `plan.md`, `todo.md`, `summary.md`, and other throwaway artifacts.
> 别让 AI Agent 把你的项目根目录变成 Markdown 垃圾场。

**This is not a Markdown deleter.** This Skill governs agent-generated artifacts that have **no ownership, no lifecycle, and no reusable value**.

A file is not garbage because it ends in `.md`. It is garbage when an agent produced it with **no clear user intent, no clear reader, no clear destination, no clear lifecycle, and no follow-up use**.

---

## 1. When to use this Skill

Invoke this Skill when the user says anything about:

| Category | Trigger phrases |
|---|---|
| **Tidy / organize** | "整理项目目录", "tidy this project", "organize this repo" |
| **Generate artifacts** | "写一个计划", "生成报告", "create a plan/todo/summary/report/audit" |
| **Audit** | "审计项目文件", "audit agent artifacts", "列出可疑文件" |
| **Clean up** | "清理 Agent 文件", "clean agent markdown", "删除临时文件" |
| **Decide** | "这个文件该不该生成?", "should I create this file?" |
| **Create rules** | "创建 AGENTS.md / CLAUDE.md / Cursor Rules" |
| **Task completion** | Task wrap-up / file-hygiene pass before exiting |
| **Pollution** | "多个 Agent 乱写文件", "project root is a mess" |
| **User complaint** | "不要生成垃圾文档", "清理 plan.md / todo.md", "让 Agent 不要在根目录乱写报告" |

---

## 2. When NOT to use this Skill

**Stop and ask the user** if the request involves:

- Deleting formal project documentation
- Modifying user-written notes
- Cleaning source code (`src/`, `lib/`, `app/`)
- Touching tool state: `.codex/`, `.claude/`, `.cursor/`, `.vscode/`, `*.sqlite`, `state.json`, `session.json`, `workspaceStorage`, `globalStorage`, `auth-token`
- Unconfirmed mass Markdown deletion
- Force-deleting Git-tracked files
- Cleaning unknown Markdown in personal folders
- Modifying system settings or registry
- Registering scheduled tasks
- Uploading logs, reports, or credentials

---

## 3. Artifact Classification

Every file an agent creates belongs to one of five classes. **Class — not extension — determines treatment.**

| Class | Examples | Where | Lifecycle | Auto-delete? |
|---|---|---|---|---|
| **A — Formal Documentation** | `README.md`, `CHANGELOG.md`, `LICENSE`, `CONTRIBUTING.md`, `docs/**`, `architecture.md`, user notes | `docs/`, project root | Permanent | Never |
| **B — User-requested Deliverables** | audit report, migration plan, research write-up (user explicitly asked) | `.agent_reports/` | 30 days | After retention |
| **C — Temporary Working Artifacts** | plan, todo, notes, scratch, progress, task_list | `.agent_tmp/` | 7 days | After retention |
| **D — Self-congratulatory** | summary, final_report, work_summary, lessons, changes_summary | **Do not create** | N/A | N/A |
| **E — Tool State (out of scope)** | `.codex/`, `.claude/`, `.cursor/`, `*.sqlite` | Tool dirs | N/A | Never |

**Classification rules:**
- Class A → never auto-delete, never auto-rewrite
- Class B → must have specific filename with task+date, never in project root
- Class C → `.agent_tmp/` only, never committed, clean at task end
- Class D → do not create. The chat is the summary.
- Class E → completely ignore, never audit as suspicious

---

## 4. Artifact Intent Check (MANDATORY)

**Before creating any file**, fill out this check. If you cannot answer every field, **do not create the file.**

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

**Decision table:**

| Check result | Action |
|---|---|
| #1 = no, class ≠ A | **Do not create.** Answer in chat. |
| Purpose = plan/todo/summary/progress, reader = user this session | **Chat only.** No file. |
| Must create, class = C | `.agent_tmp/<specific-name>.md` |
| Must create, class = B | `.agent_reports/<task>_<YYYY-MM-DD>.md` |
| Class = A (formal doc) | `docs/` path, user explicitly requested |
| File restates this chat | **Do not create** |
| No clear reader | **Do not create** |
| No clear lifecycle | **Do not create** |
| No follow-up use | **Do not create** |

---

## 5. Hard Rules for File Generation

1. **Default: do not write files.**
2. Plans, todos, summaries, progress → answer in chat.
3. **Project root: forbidden** for generic process Markdown. Exceptions only for user-named files.
4. **Forbidden in project root** (unless user explicitly asks for that exact file):
   ```
   todo.md, plan.md, notes.md, lessons.md, summary.md, report.md,
   final_report.md, implementation_plan.md, migration_plan.md,
   audit_report.md, cleanup_report.md, task_list.md, progress.md,
   work_summary.md, changes_summary.md, *_summary.md, *_report.md, *_plan.md
   ```
5. Temporary files → `.agent_tmp/`
6. Persistent reports → `.agent_reports/`
7. Formal docs → `docs/` (only when explicitly requested)
8. Do not generate reports to "look professional."
9. Do not auto-create end-of-task summary files.
10. Do not duplicate chat into files.
11. Use specific filenames: `<task>_<context>_<date>.md`
12. Propose path+filename before creating.
13. If user says "tell me" / "summarize" / "plan it" → answer in chat.

---

## 6. Allowed and Forbidden Locations

### Allowed

| Content | Allowed location |
|---|---|
| Temporary working files | `.agent_tmp/` |
| User-requested reports | `.agent_reports/` |
| Formal documentation | `docs/` (explicit request required) |
| User-specified path | Any path the user explicitly named |

### Forbidden

| Location | Why forbidden |
|---|---|
| Project root (for generic process Markdown) | Reserved for formal repo files |
| `src/`, `lib/`, `app/` | Source directories — not for docs |
| `.codex/`, `.claude/`, `.cursor/`, `.vscode/` | Tool state directories — do not touch |

---

## 7. Protected Files (never auto-delete)

```
README.md, README.*.md
CHANGELOG.md
LICENSE, LICENSE.*
CONTRIBUTING.md
CODE_OF_CONDUCT.md
SECURITY.md
Everything under docs/
Any Git-tracked file outside .agent_tmp/ or .agent_reports/
User hand-written notes
```

---

## 8. Cleanup Rules

**Allowed auto-cleanup (only):**
1. `.agent_tmp/` — files older than 7 days
2. `.agent_reports/` — files older than 30 days
3. User-specified agent temp directory
4. Named, expired, agent-created process files

**Forbidden auto-cleanup:**
- Protected docs (Class A)
- Source code
- Tool state (Class E)
- Unknown Markdown in user folders
- Git-tracked files without explicit confirmation
- Root-level suspicious files (`plan.md`, `todo.md`, etc.) → **report only, ask user**

---

## 9. Audit Rules

- Read-only — never modifies files
- Bounded depth
- Skips `.git/`, `node_modules/`, `dist/`, `build/`, `target/`, `.venv/`, `venv/`
- Lists: `.agent_tmp/` contents, `.agent_reports/` contents, root-level suspicious files, protected docs
- Suggests actions, performs none
- No upload or network calls

---

## 10. End-of-Task Checklist

Before reporting "done":
1. Did I create any files? Were each justified by an Artifact Intent Check?
2. Are any of my files in the project root that should not be?
3. Are any of my `.agent_tmp/` files safe to delete now?
4. Did I avoid creating `summary.md` / `final_report.md` / `work_summary.md`?
5. If user wants archival, did I propose `.agent_reports/` or `docs/`?

---

## 11. Safety Boundaries

This Skill and its scripts:
- Do not modify system settings or registry
- Do not register scheduled tasks
- Do not require admin/root privileges
- Do not perform full-disk scans
- Do not delete formal documentation
- Do not delete tool state files
- Do not delete Git-tracked files without explicit confirmation
- Do not upload any data
- Do not install dependencies
- Do not require network access
- Default to DryRun for all deletion operations
- Refuse to operate on system directories (`C:\Windows`, `/`, `/usr`, `/etc`, `$HOME` root)
