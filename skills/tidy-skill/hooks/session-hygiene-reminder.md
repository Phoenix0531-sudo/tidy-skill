# tidy-skill session reminder (read-only)

Before creating files in this repository:

1. Default answer is chat, not a new Markdown file.
2. Do not drop `plan.md`, `todo.md`, `summary.md`, or `*_report.md` in the repo root.
3. Temporary work goes to `.agent_tmp/`; user-requested reports go to `.agent_reports/`.
4. Formal docs stay in `docs/` only when the user explicitly asked for them.
5. Audits are read-only. Cleanup defaults to DryRun. Never auto-delete, migrate VHDX, or rewrite tool configs.

End of task: run a read-only stop check if available:

```bash
python skills/tidy-skill/hooks/stop-hygiene-check.py --root .
```
