# Good Artifacts — Examples of Well-Managed Agent Output

These are examples of agent-created files that are **not** garbage.

---

## User-requested deliverable (in correct location)

```
project/
├─ .agent_reports/
│  ├─ go_migration_report_2026-06-03.md
│  ├─ windows_ai_dev_audit_2026-06-03.md
│  └─ dependency_upgrade_plan_2026-05-28.md
└─ src/
```

### Why these are NOT garbage

| File | Why it's good |
|---|---|
| `.agent_reports/go_migration_report_2026-06-03.md` | User explicitly requested it. Specific name. Dated. In the designated reports directory. Has a clear reader (the team evaluating the migration). |
| `.agent_reports/windows_ai_dev_audit_2026-06-03.md` | User-requested audit. Dated. Scoped. Referenced in later conversations. |
| `.agent_reports/dependency_upgrade_plan_2026-05-28.md` | Actionable plan with a real deadline. Specific dependencies named. Used by the team to schedule upgrade work. |

---

## Formal documentation (in correct location)

```
project/
├─ docs/
│  ├─ deployment.md
│  ├─ api.md
│  ├─ architecture.md
│  └─ migration-guide.md
└─ README.md
```

### Why these are NOT garbage

| File | Why it's good |
|---|---|
| `docs/deployment.md` | Formal doc. User requested it. Has long-term value. In the docs directory. Referenced by new team members. |
| `docs/api.md` | API contract documentation. Users and developers read it. Versioned alongside the code. |
| `docs/architecture.md` | Architecture decision record. Has a clear reader (current and future developers). Updated as the architecture evolves. |
| `README.md` | Standard project entry point. Protected by policy. |

---

## Temporary working artifact (in correct location)

```
project/
├─ .agent_tmp/
│  ├─ refactor_steps_2026-06-03.md
│  └─ debug_session_notes_2026-06-02.md
└─ src/
```

### Why these are acceptable

| File | Why it's acceptable |
|---|---|
| `.agent_tmp/refactor_steps_2026-06-03.md` | Temporary. Has a date. In the temp directory. Agent cleans it at task end. If it has lasting value, it gets promoted to `docs/` or `.agent_reports/`. |
| `.agent_tmp/debug_session_notes_2026-06-02.md` | Session-specific debugging notes. Deleted after 7 days. No one depends on it. |

---

## Characteristics of a good artifact

1. **Specific filename** — Contains task name, context, and date. `go_migration_report_2026-06-03.md` vs `report.md`.
2. **Correct location** — In `.agent_tmp/`, `.agent_reports/`, or `docs/` as appropriate. Never in the project root.
3. **Non-redundant content** — Adds information not already in the chat, commit messages, or PR descriptions.
4. **Clear reader** — Written for a specific audience (the team, a reviewer, future maintainers).
5. **Clear lifecycle** — Either temporary (will be deleted) or permanent (will be maintained).
6. **User intent** — The user asked for it, or the agent proposed it and the user agreed.
7. **Follow-up value** — Someone will read it, reference it, or act on it.
8. **Context preserved** — Filename and content include enough context to be useful weeks later.

---

## Decision table

| Scenario | Action | Good artifact? |
|---|---|---|
| User says "write a migration plan" | Create `.agent_reports/migration_plan_<date>.md` | Yes — user-requested, correct location |
| User says "tell me the steps" | Answer in chat | No file needed |
| Agent finishes task, auto-creates `summary.md` | Don't create | No — self-congratulatory, no reader |
| Agent needs to track progress during a complex task | Create `.agent_tmp/progress_<task>_<date>.md`, clean at end | Yes — temporary, correct location |
| User says "document the API" | Create `docs/api.md` | Yes — formal doc, correct location |
| Agent runs cleanup and creates `cleanup_report.md` | Don't create | No — the cleanup script already logs |
