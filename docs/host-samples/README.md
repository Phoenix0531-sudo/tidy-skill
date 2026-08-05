# Host wiring samples (optional)

These are **examples**, not auto-installed configs. Copy only after editing paths for your machine.

All samples are **read-only**. They never delete files, compact disks, or rewrite tool configs.

| Sample | Host | Purpose |
|---|---|---|
| [claude-stop-hook.example.json](claude-stop-hook.example.json) | Claude Code style | End-of-task hygiene printout |
| [codex-stop-hook.example.json](codex-stop-hook.example.json) | Codex style | End-of-task hygiene printout |
| [cursor-hooks.example.json](cursor-hooks.example.json) | Cursor | Project hooks.json shape |
| [session-start.example.md](session-start.example.md) | Any | Paste into AGENTS.md / CLAUDE.md |

Canonical script:

```text
skills/tidy-skill/hooks/stop-hygiene-check.py
```

After a skills CLI install the same file lives under the installed skill tree, for example:

```text
.agents/skills/tidy-skill/hooks/stop-hygiene-check.py
~/.codex/skills/tidy-skill/hooks/stop-hygiene-check.py
```
