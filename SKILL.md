---
name: Agent Tidy Skill
description: Governs AI-agent-generated artifacts so agents stop littering project roots with plan.md, todo.md, summary.md, and other throwaway Markdown. Provides classification rules, an Artifact Intent Check, conservative audit and cleanup scripts, and drop-in templates for AGENTS.md / CLAUDE.md / Cursor Rules.
---

# Agent Tidy Skill

> Stop AI agents from littering your repo with `plan.md`, `todo.md`, `summary.md`, and other throwaway artifacts.
>
> 别让 AI Agent 把你的项目根目录变成 Markdown 垃圾场。

This is **not a Markdown deleter**. This Skill governs agent-generated artifacts that have **no ownership, no lifecycle, and no reusable value**.

A Markdown file is not garbage because it ends in `.md`. It is garbage when an agent produced it with no clear user intent, no clear reader, no clear destination, no clear lifecycle, and no follow-up use.

---

## 1. When to use this Skill

Invoke this Skill whenever the user (or you, as an agent) is about to:

- Tidy or reorganize a project directory.
- Generate a `plan`, `todo`, `summary`, `report`, `audit`, `migration plan`, `implementation plan`, `progress`, `notes`, `lessons`, or similar Markdown file.
- Audit a project for agent-generated files.
- Clean up artifacts left behind by a previous agent task.
- Decide whether a Markdown file should be created, kept, moved, or removed.
- Create or maintain `AGENTS.md`, `CLAUDE.md`, or Cursor Rules in a project.
- Wrap up a coding-agent task (final file-hygiene pass before exiting).
- Resolve pollution caused by multiple agents writing to the same repo.

User intent signals that trigger this Skill:

- "整理项目目录" / "tidy this project"
- "不要生成垃圾文档" / "don't make junk docs"
- "清理 plan.md / todo.md / summary.md"
- "治理 Agent 产物"
- "让 Agent 不要在根目录乱写报告"
- "audit agent artifacts"
- "clean up agent-generated markdown"

## 2. When NOT to use this Skill

Do not use this Skill to:

- Delete formal project documentation (`README.md`, `CHANGELOG.md`, `LICENSE`, `CONTRIBUTING.md`, anything under `docs/`).
- Modify user-written notes.
- Clean source code.
- Touch tool state files: `.codex/`, `.claude/`, `.cursor/`, `.vscode/`, `*.sqlite`, `state.json`, `session.json`, `auth-token`, `workspaceStorage`, `globalStorage`, `History`.
- Perform unconfirmed mass Markdown deletion.
- Replace version control, issue tracking, or formal documentation processes.
- Force-delete Git-tracked files.
- Clean unknown Markdown of unclear origin in a user's personal folders.
- Modify system settings.
- Register Windows Task Scheduler entries.
- Upload logs, local reports, environment paths, or credentials anywhere.

If the situation falls into the above list, stop and ask the user.

---

## 3. Artifact classification

Every file an agent might create or encounter falls into one of five classes. The class — not the file extension — determines how to treat it.

### A. Formal Documentation — protected by default

Examples: `README.md`, `CHANGELOG.md`, `LICENSE`, `CONTRIBUTING.md`, anything under `docs/`, `architecture.md`, `design.md`, `spec.md`, `api.md`, `deployment.md`, user hand-written notes, PRDs, design docs, long-lived project explainers, team conventions.

Rules: never auto-delete. Never auto-rewrite. Only edit when explicitly requested.

### B. User-requested Deliverables — allowed but must have a home

Examples: an audit report, a migration plan, a research write-up, an install guide, a retrospective, a config doc — created because the user **asked** for it.

Rules:

- Allowed to exist.
- Must live in a known directory, **never** dropped in the project root by default.
- Recommended home: `.agent_reports/` (or `docs/reports/`, or a path the user named).
- Filename must include task name and date (e.g. `windows_ai_dev_audit_2026-06-03.md`).

### C. Temporary Working Artifacts — `.agent_tmp/` only

Examples: `plan.md`, `todo.md`, `notes.md`, `scratch.md`, `implementation_plan.md`, `migration_plan.md`, `task_list.md`, `progress.md`.

Rules:

- These have value only during the task.
- They live in `.agent_tmp/`, never in the project root.
- Default lifetime: ≤ 7 days.
- Not committed to Git.
- Agent should delete its own `.agent_tmp/` entries on task completion when safe.

### D. Agent Self-congratulatory Artifacts — do not create by default

Examples: `summary.md`, `final_report.md`, `task_complete.md`, `lessons.md`, `cleanup_summary.md`, `work_summary.md`, `changes_summary.md`.

These usually restate the chat or prove "I finished." They have no reader and no follow-up use.

Rules:

- Do **not** create unless the user explicitly asks for a file.
- Keep the summary in the chat reply.

### E. Tool State — out of scope, do not touch

Examples: `.codex/`, `.claude/`, `.cursor/`, `.vscode/`, `*.sqlite`, `state.json`, `session.json`, `auth-token`, `workspaceStorage`, `globalStorage`, `History`, `User/workspaceStorage`.

Rules: this Skill ignores them. Never delete, never audit as "junk", never report as suspicious.

---

## 4. Artifact Intent Check

Before creating **any** new Markdown (or other persistent artifact), fill out this check. If you cannot answer all questions, do not create the file.

```text
Artifact Intent Check

1. User requested a file?           yes / no
2. Purpose:
3. Reader:
4. Expected lifetime:               session / days / persistent / formal-doc
5. Destination path:
6. Why a chat response is not enough:
7. Class:                           temporary / persistent / formal-documentation
8. Should this be in .gitignore?    yes / no
```

Decision rules derived from the check:

- If question 1 = no and class ≠ formal-documentation → **do not create the file**. Answer in chat.
- If purpose is "plan", "todo", "summary", "progress" and reader is "the user during this session" → **chat only**.
- If a file is required and it is temporary → `.agent_tmp/<specific-name>.md`.
- If a file is required and it is a user-requested deliverable → `.agent_reports/<task>_<YYYY-MM-DD>.md`.
- If a file is formal documentation → it must go under `docs/` (or the project's existing doc structure) **and** the user must have explicitly asked for it.
- If the file would only restate this chat → do not create it.

## 5. Hard rules for file generation

1. Default behavior: **do not write files**.
2. Plans, todos, summaries, and progress go in the chat reply, not on disk.
3. The project root is reserved for formal repository files. Do not drop generic process Markdown there.
4. The following filenames are **forbidden in the project root** unless the user explicitly asks for that exact file:

   ```text
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

5. Temporary files → `.agent_tmp/`.
6. Persistent user-requested reports → `.agent_reports/`.
7. Formal docs → `docs/`, and only when explicitly requested.
8. Do not generate a report just to "look professional."
9. Do not auto-emit an end-of-task summary file.
10. Do not duplicate the chat into a file.
11. No generic filenames. Use task name + context + date.
12. If the user asks for a file, propose path and filename first, then create.
13. If the user only says "tell me", "summarize", "plan it" — answer in chat. No file.

## 6. Allowed and forbidden locations

Allowed locations for agent-generated content:

- `.agent_tmp/` — temporary working artifacts.
- `.agent_reports/` — user-requested persistent reports.
- `docs/` — only when the user explicitly requests formal documentation.
- A path the user explicitly named.

Forbidden by default:

- The project root (top-level) for any generic process Markdown.
- Inside `src/`, `lib/`, `app/`, or other source directories.
- Inside other tools' state directories (`.codex/`, `.claude/`, `.cursor/`, `.vscode/`, etc.).

## 7. Protected files

These are never auto-deleted, never auto-rewritten by this Skill:

- `README.md`, `README.*.md`
- `CHANGELOG.md`
- `LICENSE`, `LICENSE.*`
- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md`
- `SECURITY.md`
- everything under `docs/`
- any file tracked by Git that is not inside `.agent_tmp/` or `.agent_reports/`
- user hand-written notes recognizable by content
- tool state directories listed in Class E

## 8. Lifecycle

`.agent_tmp/`:

- Default retention: 7 days.
- Agent should clean its own entries at task end when safe.
- Never committed.

`.agent_reports/`:

- Default retention: 30 days.
- If the user wants to keep a report long-term, move it to `docs/` (or out of `.gitignore`).

`docs/`:

- No automatic lifecycle. Managed like normal source.

## 9. Cleanup rules

Auto-cleanup is allowed **only** for:

1. Files inside `.agent_tmp/`.
2. Files inside `.agent_reports/` older than the configured retention.
3. A user-specified directory of agent temporary files.
4. Files that are clearly named, clearly expired, and clearly created by an agent process.

Auto-cleanup must **never**:

- Touch formal documentation (Class A).
- Touch source code.
- Touch tool state (Class E).
- Touch unknown Markdown in the user's personal folders.
- Touch Git-tracked files without explicit user confirmation.

For suspicious root-level files (`plan.md`, `todo.md`, `summary.md`, `report.md`, `implementation_plan.md`, etc.): **report only**. Let the user decide.

## 10. Audit rules

Audits are read-only. An audit:

- Scans a project root with bounded depth.
- Skips `.git`, `node_modules`, `dist`, `build`, `target`, `.venv`, `venv`.
- Lists `.agent_tmp/` and `.agent_reports/` contents.
- Lists suspicious root-level Markdown matching the forbidden-name patterns.
- Lists protected formal documentation found.
- Suggests actions but **does not** perform them.
- Does not upload, transmit, or phone home.

## 11. Examples

Bad artifacts (Class C/D, wrong placement):

- `./plan.md`
- `./summary.md`
- `./final_report.md`
- `./implementation_plan.md`
- `./cleanup_report.md`
- `./work_summary.md`

Good artifacts:

- `.agent_reports/go_migration_report_2026-06-03.md` — user asked, dated, scoped.
- `.agent_reports/windows_ai_dev_audit_2026-06-03.md` — user-requested deliverable.
- `docs/deployment.md` — formal doc, explicitly requested.
- `docs/api.md` — formal doc.
- `docs/architecture.md` — formal doc.

## 12. Safety boundaries

This Skill, and any script under `scripts/`:

- Does not modify system settings.
- Does not register scheduled tasks.
- Does not require administrator / root privileges.
- Does not perform full-disk scans.
- Does not delete formal documentation.
- Does not delete tool state files.
- Does not delete Git-tracked files unless the user passes an explicit confirmation flag.
- Does not upload anything.
- Does not install dependencies.
- Does not require network access to run cleanup.
- Defaults to DryRun where deletion is involved.
- Refuses to operate on system directories (`C:\Windows`, `/`, `/usr`, `/etc`, `$HOME` root, etc.).

## 13. Agent workflow (recommended)

When this Skill is active and you are about to finish a task:

1. Did I create any files? If yes, were they each justified by an Artifact Intent Check?
2. Are any of my files in the project root that should not be?
3. Are any of my files in `.agent_tmp/` that I can safely remove now?
4. Did I avoid creating `summary.md` / `final_report.md` / `work_summary.md`?
5. If the user wants the result archived, did I propose a path under `.agent_reports/` or `docs/` instead of dropping it in root?

If any answer is unsatisfactory, fix it before reporting "done."
