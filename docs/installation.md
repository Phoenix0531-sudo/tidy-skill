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

## Fastest path (recommended)

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

## Doctor check

After install, from a project root:

```bash
# Preferred one-shot doctor (package + score + suspicious root)
python path/to/tidy-skill/scripts/tidy_doctor.py --root . --json
# or from this repo:
uv run python skills/tidy-skill/scripts/tidy_doctor.py --root . --json

# Lighter stop check / score only
uv run python skills/tidy-skill/hooks/stop-hygiene-check.py --root .
uv run python skills/tidy-skill/scripts/score_repo_hygiene.py --root . --json

# Optional CI gate (uses .tidy-skill.json min_score when present)
uv run python skills/tidy-skill/scripts/hygiene_snapshot.py gate --root . --json
```

Expected healthy baseline: doctor `failed: false`, `suspicious_root: 0`, and a documented score (this repo self-scores 100 when layout dirs exist).

Optional project policy: copy `skills/tidy-skill/references/tidy-skill.policy.example.json` to `.tidy-skill.json` at the repo root.

## Safety reminder

- Audits are **read-only**.
- Cleanup defaults to **DryRun**.
- Never auto-migrate WSL, compact VHDX, relocate Docker data, or rewrite tool configs.
