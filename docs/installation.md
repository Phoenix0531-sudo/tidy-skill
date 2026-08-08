# Installation Guide

Tidy Skill (`洁癖.skill`) installs as a standard Agent Skills package under `skills/tidy-skill/`.

This guide is honest about what each route ships. **Hooks and slash commands are optional add-ons**, not automatic on every host.

## What each install route ships

| Route | Skill + scripts + templates | Slash / trigger docs | Read-only stop hook | Host marketplace listing |
|---|---|---|---|---|
| `npx skills add` | **yes** | docs only (`commands/TRIGGERS.md`) | script present; host must wire it | not claimed |
| Local `install-local.ps1` | **yes** | docs only | script present; host must wire it | n/a |
| Manual copy / clone | **yes** | docs only | script present; host must wire it | n/a |
| Claude / Codex marketplace plugin | not published yet | — | — | do not claim |

Verified on 2026-08-05 (author machine):

```text
npx skills add Phoenix0531-sudo/tidy-skill --list
# Found 1 skill: tidy-skill
```

## Two install philosophies

| Path | Philosophy | Update model | Best when |
|---|---|---|---|
| **Subscribe** | skills CLI copies into agent skill dirs | re-run `npx skills add …` | You want managed discovery across hosts |
| **Editable** | `git clone` / `install-local.ps1` — you own the tree | `git pull` or re-copy | You hack scripts, policy, or hooks |

Pick **one per machine** so you do not stack two trees and wonder which script ran.

## Fastest path (recommended — subscribe)

```bash
npx skills add Phoenix0531-sudo/tidy-skill --skill tidy-skill
```

Useful flags:

```bash
# list without installing
npx skills add Phoenix0531-sudo/tidy-skill --list

# global user-level install
npx skills add Phoenix0531-sudo/tidy-skill --skill tidy-skill -g

# all agents the CLI knows about
npx skills add Phoenix0531-sudo/tidy-skill --skill tidy-skill --agent '*' -y

# copy files instead of symlinks
npx skills add Phoenix0531-sudo/tidy-skill --skill tidy-skill --copy -y
```

## Local installer (Windows / multi-hub copy)

```powershell
# DryRun preview (default)
pwsh skills/tidy-skill/scripts/install-local.ps1

# Codex + Claude (default pair)
pwsh skills/tidy-skill/scripts/install-local.ps1 -DryRun:$false -Force

# All supported hubs
pwsh skills/tidy-skill/scripts/install-local.ps1 -All -DryRun:$false -Force
```

Targets: Codex, Claude, Cursor, Pi, OpenCode.

## Per-platform setup

| Platform | Guide | What you get |
|---|---|---|
| Claude Code | [platforms/claude.md](platforms/claude.md) | skill dir + optional stop hook sample |
| Codex | [platforms/codex.md](platforms/codex.md) | skill dir + optional stop hook sample |
| Cursor | [platforms/cursor.md](platforms/cursor.md) | skill dir + project rule template + hooks sample |
| Pi | [platforms/pi.md](platforms/pi.md) | skill dir under `~/.pi/agent/skills` |
| OpenCode | [platforms/opencode.md](platforms/opencode.md) | skill dir under XDG config |
| Any Agent Skills host | this page + `npx skills add` | SKILL.md discovery |

## Optional host wiring (not automatic)

After the skill package is installed, you may optionally:

1. Paste [session-hygiene-reminder.md](../skills/tidy-skill/hooks/session-hygiene-reminder.md) into project `AGENTS.md` / `CLAUDE.md`.
2. Point a host stop/session hook at [stop-hygiene-check.py](../skills/tidy-skill/hooks/stop-hygiene-check.py) using samples under [host-samples/](host-samples/).
3. Install rule templates:

```powershell
pwsh skills/tidy-skill/scripts/install-rule-template.ps1 -TargetRoot <project> -DryRun
```

## Silent failure modes

| Symptom | Likely cause | Fix |
|---|---|---|
| Skill not listed by agent | installed to wrong hub / agent not restarted | re-run install for that host; restart agent |
| Hook never runs | host not wired; skill install does not auto-register hooks | use [host-samples/](host-samples/) or paste session reminder |
| `npx skills` blocked on Windows PowerShell | execution policy blocks `npx.ps1` | use `npx.cmd` or `node path\to\npx` |
| Cleanup deleted something unexpected | operator ran without DryRun | always preview with `-DryRun` first |

## Doctor → repair

After install, from a project root:

```bash
# Preferred one-shot doctor (package + score + suspicious root)
python path/to/tidy-skill/scripts/tidy_doctor.py --root . --json
# or from this repo:
uv run python skills/tidy-skill/scripts/tidy_doctor.py --root . --json

# DryRun repair plan (layout dirs / optional root moves / hook hint)
uv run python skills/tidy-skill/scripts/tidy_repair.py --root .
# Safe apply: create .agent_tmp/ + .agent_reports/ with .gitkeep
uv run python skills/tidy-skill/scripts/tidy_repair.py --root . --apply
# Careful: also move untracked suspicious root Markdown into .agent_tmp/
uv run python skills/tidy-skill/scripts/tidy_repair.py --root . --apply --move-root

# Lighter stop check / score only
uv run python skills/tidy-skill/hooks/stop-hygiene-check.py --root .
uv run python skills/tidy-skill/scripts/score_repo_hygiene.py --root . --json

# Optional CI gate (uses .tidy-skill.json min_score when present)
uv run python skills/tidy-skill/scripts/hygiene_snapshot.py gate --root . --json
```

Expected healthy baseline: doctor `failed: false`, `suspicious_root: 0`, and a documented score (this repo self-scores 100 when layout dirs exist).

Optional project policy: copy `skills/tidy-skill/references/tidy-skill.policy.example.json` to `.tidy-skill.json` at the repo root.

### Retention knobs

| Location | Default | How to change |
|---|---|---|
| `.agent_tmp/` | 7 days | `clean-agent-artifacts.ps1 -TmpRetentionDays N` · `tidy_repair.py --tmp-days N` (note only) |
| `.agent_reports/` | 30 days | `clean-agent-artifacts.ps1 -ReportRetentionDays N` · `tidy_repair.py --report-days N` |
| `.planning/` | not swept | intentional working memory; not cleaned by default |

Cleanup still defaults to **DryRun**. Expired files are never deleted without explicit non-DryRun confirmation.

## Uninstall / reset

Tidy-skill never auto-removes itself from host configs. Manual uninstall:

1. **Skills CLI / agent skill dir** — delete the installed skill folder only, for example:
   - `.agents/skills/tidy-skill/`
   - `.claude/skills/tidy-skill/`
   - `.pi/skills/tidy-skill/`
   - `~/.codex/skills/tidy-skill/` (global)
2. **Local hub copy** — reverse what `install-local.ps1` wrote (same paths under each hub). Prefer DryRun notes from a previous install log if you kept one.
3. **Host stop hooks** — if you merged samples from `docs/host-samples/` or `tidy-install-hooks.py --write`, **manually** remove the `stop-hygiene-check` entry from the host config. Do not leave half-wired hooks.
4. **Project policy** — optional: delete `.tidy-skill.json` if you no longer want score gates.
5. **Layout dirs** — `.agent_tmp/` and `.agent_reports/` are project data, not the skill package; keep or delete per your retention policy.

There is no `tidy uninstall` that rewrites host settings — by design (**guard**).

## Safety reminder

- Audits are **read-only**.
- Cleanup and repair default to **DryRun** (**dryrun** verb).
- Root process moves need `--apply --move-root` (**careful** verb) and still refuse git-tracked / protected files.
- Never auto-migrate WSL, compact VHDX, relocate Docker data, or rewrite tool configs (**guard** verb).
