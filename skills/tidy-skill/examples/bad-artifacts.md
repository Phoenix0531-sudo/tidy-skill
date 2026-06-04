# Bad Artifacts — Examples of Agent Litter

These files are examples of what 洁癖.skill aims to prevent or manage.

---

## Root-Level Generic Process Markdown

```
project/
├─ plan.md
├─ todo.md
├─ summary.md
├─ final_report.md
├─ implementation_plan.md
├─ cleanup_report.md
├─ work_summary.md
├─ changes_summary.md
└─ src/
```

### Why These Are Likely Garbage

| File | Problem |
|---|---|
| `plan.md` | Generic name. No lifecycle. No task context. The plan belonged in the chat. |
| `todo.md` | Created mid-task, never updated, abandoned. Duplicates the task description. |
| `summary.md` | Restates the chat. No reader. No follow-up. |
| `final_report.md` | Self-congratulatory. Nobody reads it after the task ends. |
| `implementation_plan.md` | Should have been `docs/architecture.md` if lasting, or kept in chat if temporary. |
| `cleanup_report.md` | Meta-litter — a report about cleaning up. The cleanup script already logs. |
| `work_summary.md` | Duplicates the commit message and pull request description. |
| `changes_summary.md` | Same as above. The git log is the authoritative change record. |

### Characteristics of a Bad Artifact

1. **Generic filename** — `plan.md`, `report.md`, `summary.md` tell you nothing about content.
2. **No context** — No date, no task name, no project reference.
3. **Wrong location** — Placed in the project root instead of `.agent_tmp/`, `.agent_reports/`, or `docs/`.
4. **No lifecycle** — No indication of whether this file is temporary or permanent.
5. **No reader** — Created "just in case" without a specific audience.
6. **No user intent** — The agent created it without the user requesting a file.
7. **Redundant** — Content duplicates the chat conversation, commit, or PR.
8. **Self-congratulatory** — Summarizes what the agent did, for nobody in particular.

---

## What to Do Instead

| Instead of this... | Do this... |
|---|---|
| `./plan.md` | Keep the plan in chat, or `.agent_tmp/plan_<task>_<date>.md` |
| `./todo.md` | Use the chat or issue tracker; delete at task end |
| `./summary.md` | Don't create it. The chat is the summary. |
| `./final_report.md` | Don't create it. If a record is needed, commit a meaningful message. |
| `./implementation_plan.md` | Temporary → `.agent_tmp/`. Permanent → `docs/`. |
| `./work_summary.md` | Don't create it. The git log + PR are sufficient. |

---

## Bad Examples by Class

| Class | Bad example | Why it's bad |
|---|---|---|
| C — Temporary | `./plan.md` | Should be in `.agent_tmp/` or chat |
| C — Temporary | `./todo.md` | Abandoned mid-task |
| C — Temporary | `./notes.md` | Scattered notes that should stay in chat |
| D — Self-congratulatory | `./summary.md` | No reader, no follow-up |
| D — Self-congratulatory | `./final_report.md` | Restates the obvious |
| D — Self-congratulatory | `./lessons.md` | If real, put in team wiki or retro doc |
| D — Self-congratulatory | `./cleanup_summary.md` | The cleanup script already logs |
| D — Self-congratulatory | `./work_summary.md` | Redundant with git log |
| C → A (misclassified) | `./migration_plan.md` | If lasting value, move to `docs/` |
