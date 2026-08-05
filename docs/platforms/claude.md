# Claude Code setup

## Install skill package

### Option A — skills CLI

```bash
npx skills add Phoenix0531-sudo/tidy-skill --skill tidy-skill -g -a claude -y
```

### Option B — local copy

```powershell
pwsh skills/tidy-skill/scripts/install-local.ps1 -Claude -DryRun:$false -Force
```

Destination (typical):

```text
~/.claude/skills/tidy-skill/
```

## What Claude gets

| Capability | Status |
|---|---|
| `SKILL.md` discovery | yes after install |
| Portable audit scripts | yes |
| Rule templates | yes (`templates/CLAUDE.md`) |
| Marketplace plugin listing | **not published** |
| Automatic stop hook registration | **no** — optional sample only |

## Project rules (recommended)

Copy or merge the template:

```powershell
pwsh skills/tidy-skill/scripts/install-rule-template.ps1 -TargetRoot . -Claude -DryRun
```

Or manually place `skills/tidy-skill/templates/CLAUDE.md` content into the project `CLAUDE.md` / agent instructions.

## Optional stop hook

Claude Code plugin marketplace route is **not** claimed for this repo yet. For a manual stop/end check:

```bash
python ~/.claude/skills/tidy-skill/hooks/stop-hygiene-check.py --root "$CLAUDE_PROJECT_DIR"
```

Sample host config shape: [../host-samples/claude-stop-hook.example.json](../host-samples/claude-stop-hook.example.json)

## Trigger phrases

See [../../skills/tidy-skill/commands/TRIGGERS.md](../../skills/tidy-skill/commands/TRIGGERS.md). Natural language is enough; slash commands are documentation triggers unless your host maps them.
