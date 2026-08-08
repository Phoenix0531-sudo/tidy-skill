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

CI runs two workflows:

| Workflow | Matrix / runner | Covers |
|---|---|---|
| `ci.yml` | Python **3.10 / 3.11 / 3.12** on Ubuntu | ruff, pytest, fixture evals, doctor |
| `validate.yml` | Python **3.10 / 3.11 / 3.12** + Windows smoke | package validate, score/audit/doctor/gate/classify, PS1 policy + cleanup safety |

Run these checks before opening a pull request:

```powershell
python tools\validate_skill.py --skill-dir skills\tidy-skill
python tools\run_evals.py
python skills\tidy-skill\scripts\score_repo_hygiene.py --root . --json
python skills\tidy-skill\scripts\audit_agent_artifacts.py --root . --json
python skills\tidy-skill\scripts\audit_dev_environment.py --root . --json
python skills\tidy-skill\scripts\audit_workspace_hygiene.py --root . --json
python skills\tidy-skill\scripts\tidy_doctor.py --root . --json
python skills\tidy-skill\scripts\classify_artifact.py plan.md --root . --json
# Batch many candidate paths from stdin (NDJSON per line):
printf 'plan.md\n.todo.md\ndocs/index.md\n' | python skills\tidy-skill\scripts\classify_artifact.py --stdin --json --root .
python skills\tidy-skill\scripts\hygiene_snapshot.py gate --root . --min-score 80 --json
python -m unittest discover -s tests -p "test_*.py"
powershell -ExecutionPolicy Bypass -File .\skills\tidy-skill\scripts\clean-agent-artifacts.ps1 -Root . -DryRun
# Optional: skills CLI discovery smoke (needs network)
# npx.cmd skills add Phoenix0531-sudo/tidy-skill --list -y
```

Platform install docs live under `docs/platforms/`. Host hook samples under `docs/host-samples/` are examples only — do not present them as auto-registered.

On Windows, also smoke-test the PowerShell scoring and audit scripts:

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\tidy-skill\scripts\score-repo-hygiene.ps1 -Root . -ReportPath "$env:TEMP\tidy_skill_score.md"
powershell -ExecutionPolicy Bypass -File .\skills\tidy-skill\scripts\audit-agent-artifacts.ps1 -Root . -ReportPath "$env:TEMP\tidy_skill_artifacts.md"
powershell -ExecutionPolicy Bypass -File .\skills\tidy-skill\scripts\audit-dev-environment.ps1 -Roots . -ReportPath "$env:TEMP\tidy_skill_dev_environment.md"
powershell -ExecutionPolicy Bypass -File .\skills\tidy-skill\scripts\install-local.ps1 -SelfCheckOnly
powershell -ExecutionPolicy Bypass -File .\tests\test-clean-agent-artifacts.ps1
powershell -ExecutionPolicy Bypass -File .\tests\test-policy-ps1.ps1
```

## Releasing

Use `tools/release.py`. Default mode is a **read-only preview**. Git write
steps are separately opt-in and must chain: `--apply` → `--commit` → `--tag` →
`--push`.

```powershell
# Preview only (no file writes)
python tools\release.py --bump patch

# Write pyproject / CHANGELOG / docs/index / doctor snapshot
python tools\release.py --bump patch --apply

# Write + commit + annotated tag + push (all opt-in)
python tools\release.py --bump minor --apply --commit --tag --push
```

Requirements before `--apply`:

- Working tree is clean.
- `[Unreleased]` in `CHANGELOG.md` has real notes (not `_Nothing yet._`).
- Target version is strictly greater than the current `pyproject.toml` version
  and does not already exist as a CHANGELOG section.

`--apply` always regenerates `docs/self-audit/tidy_doctor.md` via
`tidy_doctor.py --strict` before writing release metadata.

## Pull Request Checklist

- The display name remains `洁癖.skill`.
- The machine-readable folder name remains `tidy-skill`.
- The skill validates with `tools/validate_skill.py`.
- New scripts are read-only or DryRun by default.
- Documentation links resolve after file moves.
