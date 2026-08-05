# Pi setup

## Install skill package

### Option A — skills CLI (if Pi is a known agent target)

```bash
npx skills add Phoenix0531-sudo/tidy-skill --skill tidy-skill -g -y
```

Confirm the CLI agent list on your machine; agent names change over CLI versions.

### Option B — local copy

```powershell
pwsh skills/tidy-skill/scripts/install-local.ps1 -Pi -DryRun:$false -Force
```

Destination (typical):

```text
~/.pi/agent/skills/tidy-skill/
```

### Option C — project AGENTS.md

Pi loads project `AGENTS.md`. Merge hygiene rules from:

```text
skills/tidy-skill/templates/AGENTS.md
skills/tidy-skill/hooks/session-hygiene-reminder.md
```

## What Pi gets

| Capability | Status |
|---|---|
| Native skill directory install | yes via `install-local.ps1 -Pi` |
| Session reminder (manual) | yes |
| Pi package marketplace (`pi install git:...`) | **not published as a Pi package** |

## Optional stop check

```bash
python ~/.pi/agent/skills/tidy-skill/hooks/stop-hygiene-check.py --root .
```

Or from a clone:

```bash
uv run python skills/tidy-skill/hooks/stop-hygiene-check.py --root .
```
