# skills CLI verification log

**Date:** 2026-08-05 (Codex); 2026-08-07 (claude-code/cursor/pi added) — author machine, Windows  
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

## Other agent targets (2026-08-07)

Re-verified after github.com connectivity was restored. Same command shape, `-a <agent>` swapped. All `--copy` mode in a temporary empty `%TEMP%` folder.

| `-a` value | Landing tree | Result |
|---|---|---|
| `claude-code` | `.claude/skills/tidy-skill/` | ✓ tidy-skill (copied) |
| `cursor` | `.agents/skills/tidy-skill/` | ✓ tidy-skill (copied) |
| `pi` | `.pi/skills/tidy-skill/` | ✓ tidy-skill (copied) |

> **Adapter quirk worth recording:** `claude` is **not** a valid agent name. The CLI rejects it with `Invalid agents: claude` and lists `claude-code` as the valid name. Use `-a claude-code`.
>
> **Landing path differs by adapter:** claude-code writes to its own `.claude/skills/`; codex and cursor both write to the shared `.agents/skills/`; pi writes to `.pi/skills/`. When you classify or audit, `.claude/`, `.agents/`, and `.pi/` are all Class E (tool/agent state — keep ignored). Path is what matters, not adapter.

## Limits

- Verified discovery + project copy install for **codex**, **claude-code**, **cursor**, and **pi** agent targets on one author machine. Other adapters in the CLI's valid list (aider-desk, amp, gemini-cli, …) were not exercised.
- Does not prove marketplace ranking, install counts, or every agent adapter.
- Host stop hooks are still manual; skills CLI does not auto-wire them for this package. See `tidy-install-hooks.py` for a DryRun-first config emitter.
