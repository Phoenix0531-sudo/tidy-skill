# OpenCode setup

## Install skill package

### Option A — skills CLI

```bash
npx skills add Phoenix0531-sudo/tidy-skill --skill tidy-skill -g -y
```

### Option B — local copy

```powershell
pwsh skills/tidy-skill/scripts/install-local.ps1 -OpenCode -DryRun:$false -Force
```

Destination (typical):

```text
~/.config/opencode/skills/tidy-skill/
# or $env:XDG_CONFIG_HOME/opencode/skills/tidy-skill
```

## What OpenCode gets

| Capability | Status |
|---|---|
| Skill files under config skills dir | yes |
| OpenCode-native plugin INSTALL.md | **not published** |
| Automatic session hooks | **no** unless you wire them |

## Recommended project rules

Merge `templates/AGENTS.md` into the project agent instructions so hygiene rules apply even when the skill is not auto-selected.

## Optional stop check

```bash
python ~/.config/opencode/skills/tidy-skill/hooks/stop-hygiene-check.py --root .
```
