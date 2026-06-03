# Recommended Project Layout

This example shows a project directory structure that follows Tidy Skill conventions.

---

## Standard Layout

```
project/
├─ AGENTS.md                  # Agent file hygiene rules (from templates/)
├─ .agent_tmp/                # Temporary agent files — auto-cleanable, gitignored
├─ .agent_reports/            # User-requested reports — 30-day retention, gitignored
├─ .gitignore                 # Includes .agent_tmp/ and .agent_reports/
├─ README.md                  # Protected — formal documentation
├─ CHANGELOG.md               # Protected
├─ LICENSE                    # Protected
├─ CONTRIBUTING.md            # Protected
├─ docs/                      # Formal documentation — protected, versioned
│  ├─ architecture.md
│  ├─ api.md
│  └─ deployment.md
├─ src/                       # Source code
├─ tests/                     # Tests
└─ package.json               # Project config
```

---

## With CLAUDE.md (for Claude Code)

```
project/
├─ CLAUDE.md                  # Claude-specific instructions (from templates/)
├─ .agent_tmp/
├─ .agent_reports/
├─ .gitignore
├─ README.md
├─ docs/
├─ src/
└─ ...
```

---

## With Cursor Rules

```
project/
├─ .cursor/
│  └─ rules/
│     └─ agent-tidy.mdc       # Cursor-specific rule (from templates/)
├─ .agent_tmp/
├─ .agent_reports/
├─ .gitignore
├─ README.md
├─ docs/
├─ src/
└─ ...
```

---

## With All Agent Configs

```
project/
├─ AGENTS.md                  # Generic agent file hygiene rules
├─ CLAUDE.md                  # Claude Code instructions
├─ .cursor/
│  └─ rules/
│     └─ agent-tidy.mdc       # Cursor rules
├─ .agent_tmp/
├─ .agent_reports/
├─ .gitignore
├─ README.md
├─ docs/
│  ├─ architecture.md
│  ├─ api.md
│  └─ deployment.md
├─ src/
└─ ...
```

---

## `.gitignore` Entries

```gitignore
.agent_tmp/
.agent_reports/
```

If you want to track certain reports, add exceptions:

```gitignore
.agent_tmp/
.agent_reports/
!.agent_reports/README.md   # Keep an index if needed
```

---

## What Goes Where

| Directory | Purpose | Lifecycle | Git? |
|---|---|---|---|
| `.agent_tmp/` | Temporary working files (plans, todos, scratch notes) | ≤ 7 days | No |
| `.agent_reports/` | User-requested deliverables (audits, migration plans) | ≤ 30 days | No (default) |
| `docs/` | Formal project documentation | Permanent | Yes |
| Project root | Only formal repo files (README, LICENSE, AGENTS.md, etc.) | Permanent | Yes |
| `src/`, `lib/`, `app/` | Source code | Permanent | Yes |

---

## What NOT to Put Where

| Don't put this... | In here... |
|---|---|
| `plan.md` | project root |
| `todo.md` | project root |
| `summary.md` | project root |
| `final_report.md` | project root |
| `*.report.md` | project root |
| `*_plan.md` | project root |
| Temporary scratch files | `src/`, `docs/` |
| Formal documentation | `.agent_tmp/` |
