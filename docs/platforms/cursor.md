# Cursor setup

## Install skill package

### Option A — skills CLI

```bash
npx skills add Phoenix0531-sudo/tidy-skill --skill tidy-skill -g -a cursor -y
```

### Option B — local copy

```powershell
pwsh skills/tidy-skill/scripts/install-local.ps1 -Cursor -DryRun:$false -Force
```

Destination (typical):

```text
~/.cursor/skills/tidy-skill/
```

## Project rule (recommended)

Install the Cursor rule template into the project:

```powershell
pwsh skills/tidy-skill/scripts/install-rule-template.ps1 -TargetRoot . -Cursor -DryRun
```

Source: `skills/tidy-skill/templates/cursor-rule.mdc`  
Typical target: `.cursor/rules/tidy-skill.mdc`

## Optional hooks.json sample

Cursor supports project hooks. A **read-only** stop-style sample lives at:

[../host-samples/cursor-hooks.example.json](../host-samples/cursor-hooks.example.json)

Copy into the project as `.cursor/hooks.json` only after reviewing paths for your machine. The sample runs `stop-hygiene-check.py` and **never deletes files**.

## What Cursor gets

| Capability | Status |
|---|---|
| Skill package | yes after install |
| Project rule template | yes |
| Marketplace plugin | **not claimed** |
| Automatic lifecycle | only if you wire hooks.json |

## Verify

```bash
python ~/.cursor/skills/tidy-skill/hooks/stop-hygiene-check.py --root .
```
