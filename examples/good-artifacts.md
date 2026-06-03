# Good Artifacts — Examples of Well-Managed Agent Output

These are examples of agent-created files that are **not** garbage.

---

## User-Requested Deliverables (Correct Location)

```
project/
├─ .agent_reports/
│  ├─ go_migration_report_2026-06-03.md
│  ├─ windows_ai_dev_audit_2026-06-03.md
│  └─ dependency_upgrade_plan_2026-05-28.md
└─ src/
```

| File | Why it's good |
|---|---|
| `.agent_reports/go_migration_report_2026-06-03.md` | User explicitly requested it. Specific name. Dated. Designated reports directory. Clear reader (the team). |
| `.agent_reports/windows_ai_dev_audit_2026-06-03.md` | User-requested audit. Dated. Scoped. Referenced later. |
| `.agent_reports/dependency_upgrade_plan_2026-05-28.md` | Actionable plan with a real deadline. Specific dependencies named. Used to schedule work. |

---

## Formal Documentation (Correct Location)

```
project/
├─ docs/
│  ├─ deployment.md
│  ├─ api.md
│  ├─ architecture.md
│  └─ migration-guide.md
└─ README.md
```

| File | Why it's good |
|---|---|
| `docs/deployment.md` | Formal doc. User requested it. Long-term value. Referenced by new team members. |
| `docs/api.md` | API contract documentation. Users and developers read it. Versioned alongside code. |
| `docs/architecture.md` | Architecture decision record. Clear reader (future developers). Evolving document. |
| `README.md` | Standard project entry point. Protected by policy. |

---

## Temporary Working Artifacts (Correct Location)

```
project/
├─ .agent_tmp/
│  ├─ refactor_steps_2026-06-03.md
│  └─ debug_session_notes_2026-06-02.md
└─ src/
```

| File | Why it's acceptable |
|---|---|
| `.agent_tmp/refactor_steps_2026-06-03.md` | Temporary. Dated. In the temp directory. Agent cleans at task end. Promotable if lasting. |
| `.agent_tmp/debug_session_notes_2026-06-02.md` | Session-specific debugging notes. Deleted after 7 days. No one depends on it. |

---

## Characteristics of a Good Artifact

1. **Specific filename** — Contains task name, context, and date. `go_migration_report_2026-06-03.md` vs `report.md`.
2. **Correct location** — `.agent_tmp/`, `.agent_reports/`, or `docs/` as appropriate. Never project root.
3. **Non-redundant content** — Information not already in the chat, commit messages, or PR descriptions.
4. **Clear reader** — Written for a specific audience.
5. **Clear lifecycle** — Either temporary (will be deleted) or permanent (will be maintained).
6. **User intent** — The user asked for it, or the agent proposed and user agreed.
7. **Follow-up value** — Someone will read, reference, or act on it.
8. **Context preserved** — Filename and content include enough context to be useful weeks later.

---

## Decision Table

| Scenario | Action | Good artifact? |
|---|---|---|
| User says "write a migration plan" | `.agent_reports/migration_plan_<date>.md` | Yes — user-requested, correct location |
| User says "tell me the steps" | Answer in chat | No file needed |
| Agent finishes, auto-creates `summary.md` | Don't create | No — self-congratulatory, no reader |
| Agent tracks progress during complex task | `.agent_tmp/progress_<task>_<date>.md`, clean at end | Yes — temporary, correct location |
| User says "document the API" | `docs/api.md` | Yes — formal doc, correct location |
| Agent runs cleanup, creates `cleanup_report.md` | Don't create | No — cleanup script already logs |
