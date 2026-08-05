# Codex setup

## Install skill package

### Option A — skills CLI

```bash
npx skills add Phoenix0531-sudo/tidy-skill --skill tidy-skill -g -a codex -y
```

### Option B — local copy

```powershell
pwsh skills/tidy-skill/scripts/install-local.ps1 -Codex -DryRun:$false -Force
```

Destination (typical):

```text
~/.codex/skills/tidy-skill/
```

## What Codex gets

| Capability | Status |
|---|---|
| `SKILL.md` + `agents/openai.yaml` | yes |
| Portable audit scripts | yes |
| Prompt suggestions in `openai.yaml` | yes |
| Official Codex marketplace plugin | **not published** |
| Automatic hooks | **no** — optional sample only |

## Project rules

```powershell
pwsh skills/tidy-skill/scripts/install-rule-template.ps1 -TargetRoot . -DryRun
```

Use `templates/AGENTS.md` for multi-agent project instructions.

## Optional end-of-task check

```bash
python ~/.codex/skills/tidy-skill/hooks/stop-hygiene-check.py --root .
```

Sample: [../host-samples/codex-stop-hook.example.json](../host-samples/codex-stop-hook.example.json)

## Triggers

Ask Codex to “score this repo’s agent hygiene” or use phrases in [TRIGGERS.md](../../skills/tidy-skill/commands/TRIGGERS.md).
