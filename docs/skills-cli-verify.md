# skills CLI verification log

**Date:** 2026-08-05 (author machine, Windows)  
**CLI:** `npx skills` (vercel-labs/skills style package)  
**Source:** `https://github.com/Phoenix0531-sudo/tidy-skill.git`

## List

Command:

```bash
npx.cmd skills add Phoenix0531-sudo/tidy-skill --list -y
```

Result:

```text
Found 1 skill
tidy-skill
```

## Project install (Codex agent, copy mode)

Command:

```bash
npx.cmd skills add Phoenix0531-sudo/tidy-skill --skill tidy-skill -a codex -y --copy
```

Working directory: temporary empty folder under `%TEMP%`.

Result:

```text
Installed 1 skill
✓ tidy-skill (copied)
→ <temp>/.agents/skills/tidy-skill
```

Observed tree (abbreviated):

```text
.agents/skills/tidy-skill/
├─ SKILL.md
├─ agents/openai.yaml
├─ commands/
├─ hooks/
├─ scripts/
├─ templates/
├─ references/
└─ examples/
```

Also wrote `skills-lock.json` in the project root.

Security panel (CLI-printed, third-party scanners): Gen=Safe, Socket=0 alerts, Snyk=Low Risk.  
Details URL printed by CLI: `https://skills.sh/Phoenix0531-sudo/tidy-skill`

## Windows note

PowerShell may block `npx.ps1` under restricted execution policy. Use:

```powershell
npx.cmd skills add Phoenix0531-sudo/tidy-skill --skill tidy-skill
```

## Limits

- Verified discovery + project copy install for **Codex** agent target on one machine.
- Does not prove marketplace ranking, install counts, or every agent adapter.
- Host stop hooks are still manual; skills CLI does not auto-wire them for this package.
