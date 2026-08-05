# Session start snippet (any host)

Paste into project `AGENTS.md`, `CLAUDE.md`, or host instructions:

---

## tidy-skill hygiene (read-only defaults)

1. Prefer chat over creating root Markdown process files (`plan.md`, `todo.md`, `summary.md`, `*_report.md`).
2. Temporary work → `.agent_tmp/`; user-requested reports → `.agent_reports/`; formal docs → `docs/` only when asked.
3. Audits are read-only. Cleanup is DryRun unless the user explicitly confirms a live clean.
4. Never auto-migrate WSL, compact VHDX, relocate Docker data, or rewrite tool configs.
5. Before finishing a multi-file task, run:

```bash
python skills/tidy-skill/hooks/stop-hygiene-check.py --root .
# or the installed skill path equivalent
```

---
