---
name: tidy-skill
description: Keep AI agent artifacts intentional, scoped, and clean. Prevent throwaway Markdown files, audit repo hygiene, and safely clean temporary agent outputs.
---

# 洁癖.skill

> Stop AI agents from littering your repo with `plan.md`, `todo.md`, `summary.md`, and throwaway artifacts.
> 别让 AI Agent 把你的项目根目录变成 Markdown 垃圾场。

**This is not a Markdown deleter.** This Skill governs agent-generated artifacts that have **no ownership, no lifecycle, and no reusable value**.

A file is not garbage because it is Markdown. It becomes garbage when it has **no intent, no owner, no reader, no lifecycle, and no reusable value.** The goal is not to ban files — it is to ensure every file an agent creates has a purpose, a place, and a lifetime.

---

## 1. When to Use This Skill

Invoke this Skill when the user asks about:

| Trigger | Examples |
|---|---|
| **Tidy / organize** | "整理项目目录", "clean up this repo", "organize my project" |
| **Generate artifacts** | "写计划", "生成报告", "create a plan/todo/summary/report/audit" |
| **Audit** | "审计项目文件", "scan for agent artifacts", "列出可疑文件" |
| **Clean up** | "清理 Agent 文件", "clean agent temp files", "删除临时文件" |
| **Decide** | "这个文件该不该生成?", "should I create this file or keep it in chat?" |
| **Score** | "给我的仓库打洁癖分", "repo hygiene score", "how clean is my repo?" |
| **Workspace audit** | "扫描工作区", "audit my workspace", "找出多个仓库的 Agent 产物" |
| **Create rules** | "创建 AGENTS.md / CLAUDE.md / Cursor Rules" |
| **Task completion** | Wrap-up hygiene check before exiting |
| **Pollution** | "多个 Agent 乱写文件", "project root is a mess of markdown" |
| **Complaint** | "不要生成垃圾文档", "清理 plan.md / todo.md" |
| **Env Inspect** | "inspect my coding environment", "where is node/python/go installed?" |
| **Drive Growth** | "why is my C drive growing?", "find package/model caches" |

---

## 2. When NOT to Use This Skill (Never Do)

**Stop and ask the user** or strictly avoid if the request involves:

- Deleting formal project documentation
- Modifying user-written notes
- Cleaning source code (`src/`, `lib/`, `app/`)
- Touching tool state directories (`.codex/`, `.claude/`, `.cursor/`, `.vscode/`, `*.sqlite`, `state.json`, `session.json`, `workspaceStorage`, `globalStorage`, `auth-token`)
- Unconfirmed mass Markdown deletion
- Force-deleting Git-tracked files
- Cleaning unknown Markdown in personal/user folders
- Modifying system settings or registry
- Registering scheduled tasks
- Uploading logs, reports, credentials, or environment data
- Scanning the whole computer without an explicit user-specified root scope
- Reading auth tokens, session files, sqlite databases, or private logs
- Deleting tool or model caches just because they are large
- Moving tools or rewriting environment variables without a separate explicit migration request

---

## 3. Artifact Classification

Every file an agent creates belongs to one of five classes. **Class — not extension — determines treatment.**

| Class | Examples | Home | Lifecycle | Auto-delete? |
|---|---|---|---|---|
| **A — Formal Documentation** | `README.md`, `CHANGELOG.md`, `LICENSE`, `docs/**`, `CONTRIBUTING.md`, user notes | `docs/`, project root | Permanent | Never |
| **B — User-requested Deliverables** | audit report, migration plan, research write-up (user explicitly asked) | `.agent_reports/` | 30 days | After retention |
| **C — Temporary Working Artifacts** | plan, todo, notes, scratch, progress, task_list | `.agent_tmp/` | 7 days | After retention |
| **D — Self-congratulatory** | summary, final_report, work_summary, lessons, changes_summary | **Do not create** | N/A | N/A |
| **E — Tool State (out of scope)** | `.codex/`, `.claude/`, `.cursor/`, `*.sqlite`, state files | Tool dirs | N/A | Never |

**Key rules:**
- Class A → never auto-delete, never auto-rewrite
- Class B → specific filename `<task>_<date>.md`, never in project root
- Class C → `.agent_tmp/` only, never committed, clean at task end
- Class D → do not create. The chat is the summary.
- Class E → completely ignore, never mark as suspicious

---

## 4. Artifact Intent Check (MANDATORY)

**Before creating any new file**, fill out this check. If you cannot answer every field, **do not create the file.**

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

**Decision rules:**

| Scenario | Action |
|---|---|
| #1 = no, class ≠ A | **Do not create.** Answer in chat. |
| Purpose = plan/todo/summary/progress, reader = this user | **Chat only.** No file. |
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
3. **Project root is forbidden** for generic process Markdown unless the user explicitly names a file.
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
12. If user asks for a file, propose path + filename first.
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

| Location | Why |
|---|---|
| Project root (generic process Markdown) | Reserved for formal repo files |
| `src/`, `lib/`, `app/` | Source directories |
| `.codex/`, `.claude/`, `.cursor/`, `.vscode/` | Tool state — do not touch |

---

## 7. Protected Files (Never Auto-delete)

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

## 8. Lifecycle

| Location | Default retention | Cleanup |
|---|---|---|
| `.agent_tmp/` | 7 days | Agent should clean its own at task end |
| `.agent_reports/` | 30 days | Move to `docs/` for long-term keeping |
| `docs/` | Permanent | No auto-lifecycle |

---

## 9. Repo Hygiene Score

When asked for a repo hygiene score, prefer `${CLAUDE_SKILL_DIR}/scripts/score_repo_hygiene.py` when Python is available. On Windows-only environments, use `${CLAUDE_SKILL_DIR}/scripts/score-repo-hygiene.ps1`.

| Score | Rating (en) | Rating (zh) |
|---|---|---|
| 90–100 | Clean | 很干净 |
| 70–89 | Mostly clean | 基本干净 |
| 50–69 | Needs tidy-up | 需要整理 |
| 0–49 | Artifact landfill | Agent 产物垃圾场 |

**Dimensions:** root cleanliness, artifact placement, protected docs clarity, Git hygiene, agent state isolation, cleanup readiness.

---

## 10. Workspace Hygiene Audit

When asked to scan multiple repos, use `${CLAUDE_SKILL_DIR}/scripts/audit-workspace-hygiene.ps1`. The user must explicitly specify a root directory. Never default to scanning entire drives.

---

## 11. Cleanup Rules

**Allowed auto-cleanup:**
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
- Root-level suspicious files → **report only, ask user**

---

## 12. Audit Rules

- Read-only — never modifies files
- Bounded depth, skips `.git/`, `node_modules/`, `dist/`, `build/`, `target/`, `.venv/`, `venv/`
- Lists: `.agent_tmp/`, `.agent_reports/`, root-level suspicious files, protected docs
- Suggests actions, performs none
- No upload or network calls

---

## 13. End-of-Task Checklist

Before reporting "done":
1. Did I create any files? Were each justified by an Artifact Intent Check?
2. Are any of my files in the project root that should not be?
3. Are any of my `.agent_tmp/` files safe to delete now?
4. Did I avoid creating `summary.md` / `final_report.md` / `work_summary.md`?
5. If user wants archival, did I propose `.agent_reports/` or `docs/`?

---

## 14. Safety Boundaries

This Skill and its scripts:
- Do not modify system settings or registry
- Do not register scheduled tasks
- Do not require admin/root privileges
- Do not perform full-disk scans (user must specify roots)
- Do not delete formal documentation
- Do not delete tool state files
- Do not delete Git-tracked files without explicit confirmation
- Do not upload any data
- Do not install dependencies
- Do not require network access
- Default to DryRun for all deletion operations
- Refuse to operate on system directories (`C:\Windows`, `/`, `/usr`, `/etc`, `$HOME` root unless explicitly requested)
- Workspace scans require explicit user-specified root path
- Environmental suggestions only — no automatic system changes
- Never read auth tokens, credentials, or private credentials databases

---

## 15. Audit Workflows

### For Environment Audits:
1. Ask for or infer the explicit scan root folder path.
2. Run read-only audit command first (`audit-dev-environment.ps1`).
3. Classify paths as cache, config, runtime, model, project, or unknown.
4. Mark C-drive growth risks and potential cache size optimizations.
5. Produce a clear Markdown report with score rating (Highly controlled to Environment sprawl).
6. Do not perform any cleaning or migration actions unless the user confirms in a separate explicit request.
