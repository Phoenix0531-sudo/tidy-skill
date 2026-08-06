# Read-only hygiene hooks

These hooks **report only**. They never delete files, never compact disks, and never rewrite configs.

## What they do

| Hook | When | Action |
|---|---|---|
| `stop-hygiene-check.py` | Agent stop / end of task | Run `audit_agent_artifacts.py --json` on the current repo and print suspicious root files. Honors `--policy` / `TIDY_SKILL_POLICY` env. |
| `session-hygiene-reminder.md` | Session start (manual paste or host hook) | Remind the agent of Classes A–E and DryRun defaults |

## Safety

- Read-only audit only
- No network
- No cleanup invocation
- Scope is the current working directory unless `TIDY_SKILL_ROOT` is set
- Optional `--policy` / `TIDY_SKILL_POLICY` env forwards to the audit script

## Wire-up examples

### Manual / any agent

```bash
python skills/tidy-skill/hooks/stop-hygiene-check.py
# or
python path/to/installed/tidy-skill/hooks/stop-hygiene-check.py --root .
```

### Claude Code / Codex style stop hook

Point the host stop hook at:

```text
python <skill>/hooks/stop-hygiene-check.py --root $CLAUDE_PROJECT_DIR
```

Ready-to-edit JSON/Markdown samples (not auto-installed):

- `docs/host-samples/claude-stop-hook.example.json`
- `docs/host-samples/codex-stop-hook.example.json`
- `docs/host-samples/cursor-hooks.example.json`
- `docs/host-samples/session-start.example.md`

If the host cannot run Python, paste the contents of `session-hygiene-reminder.md` into the project `AGENTS.md` / `CLAUDE.md` instead.
