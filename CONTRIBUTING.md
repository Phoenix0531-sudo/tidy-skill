# Contributing

Thanks for improving `洁癖.skill`. Keep changes small, verifiable, and aligned with the skill's purpose: preventing unmanaged AI-agent artifacts.

## Repository Shape

The packaged skill lives at:

```text
skills/tidy-skill/
```

Keep the skill self-contained. Do not add `README.md` inside the skill folder. Human-facing repository documentation belongs at the repository root. Detailed skill references belong in `skills/tidy-skill/references/`.

## Change Guidelines

- Keep `skills/tidy-skill/SKILL.md` concise and under 500 lines.
- Put detailed rules, examples, and script usage in `references/`.
- Prefer dependency-free Python for portable checks.
- Keep Windows-specific environment inspection in PowerShell.
- Keep `.ps1` and `.bat` files ASCII-only to avoid Windows PowerShell encoding failures.
- Default all cleanup behavior to read-only or DryRun.

## Validation

Run these checks before opening a pull request:

```powershell
python tools\validate_skill.py --skill-dir skills\tidy-skill
python skills\tidy-skill\scripts\score_repo_hygiene.py --root . --json
python skills\tidy-skill\scripts\audit_agent_artifacts.py --root . --json
powershell -ExecutionPolicy Bypass -File .\skills\tidy-skill\scripts\clean-agent-artifacts.ps1 -Root . -DryRun
```

On Windows, also smoke-test the PowerShell scoring and audit scripts:

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\tidy-skill\scripts\score-repo-hygiene.ps1 -Root . -ReportPath "$env:TEMP\tidy_skill_score.md"
powershell -ExecutionPolicy Bypass -File .\skills\tidy-skill\scripts\audit-agent-artifacts.ps1 -Root . -ReportPath "$env:TEMP\tidy_skill_artifacts.md"
```

## Pull Request Checklist

- The display name remains `洁癖.skill`.
- The machine-readable folder name remains `tidy-skill`.
- The skill validates with `tools/validate_skill.py`.
- New scripts are read-only or DryRun by default.
- Documentation links resolve after file moves.
