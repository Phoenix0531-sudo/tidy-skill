# 洁癖.skill Improvement Plan

## Current Assumptions

- The immediate failure is CC Switch not recognizing or importing this repository as a skill.
- The target should support both current CC Switch behavior and older/stricter skill scanners where possible.
- The repository should remain a usable skill package, not become only documentation.
- README quality matters as a product surface: first-screen positioning, clear install paths, examples, safety guarantees, and contribution/update guidance.

## Key Tradeoffs

- Root-level `SKILL.md` is valid in some newer scanners, but `skill-name/SKILL.md` is the safest cross-tool layout.
- Duplicating the skill into a nested folder improves marketplace/import compatibility, but can create drift if both copies are edited independently.
- Moving everything into a nested skill folder is cleaner for skill consumers, but changes the current repository shape more aggressively.
- Keep portable repo checks in Python where practical; keep Windows-specific development-environment audits in PowerShell.

## Success Criteria

- CC Switch can detect the package through a standard skill folder layout.
- Claude Code/Codex-style skill validation passes.
- The skill entrypoint remains concise, under 500 lines, and references supporting files instead of duplicating them.
- README clearly answers: what it is, why it exists, who it is for, how to install it in CC Switch, how to install it manually, how to run the scripts, and why it is safe.
- The repository has UI-facing metadata for skill lists where appropriate.
- Scripts used in README examples are smoke-tested.

## Plan

- [x] Step 1: Confirm packaging strategy
  - Proposed default: restructure toward a canonical `tidy-skill/SKILL.md` skill folder while keeping repository-level docs and install guidance.
  - Verification: local tree contains exactly one authoritative skill entrypoint or an explicit sync mechanism if compatibility requires two.

- [x] Step 2: Fix CC Switch detectability
  - Add or adjust the folder layout that CC Switch and Claude-style scanners expect.
  - Add installation instructions for CC Switch custom repository import and manual install paths.
  - Verification: run skill validation on the final skill folder and inspect path/name consistency.

- [x] Step 3: Add skill UI metadata
  - Add `agents/openai.yaml` with display name, short description, and default prompt if it fits this repository's intended consumers.
  - Verification: check metadata matches `SKILL.md` and does not claim unsupported capabilities.

- [x] Step 4: Tighten `SKILL.md`
  - Keep the trigger description strong and specific.
  - Move non-core details into `references/` where needed.
  - Make script usage paths robust under the chosen folder layout.
  - Verification: `SKILL.md` stays under 500 lines and validates.

- [x] Step 5: Rework README presentation
  - Rewrite Chinese and English READMEs with a stronger first viewport, clearer compatibility badges, a quick install section, examples, safety model, and roadmap.
  - Avoid vague claims such as "compatible" unless the repo structure actually proves them.
  - Verification: README commands match existing files and the final package layout.

- [x] Step 6: Validate scripts and examples
  - Smoke-test the read-only scoring/audit scripts.
  - Smoke-test cleanup in DryRun mode only.
  - Verification: commands complete without destructive changes.

- [x] Step 7: Final review
  - Check for unintended root clutter, stale paths, duplicate instructions, and mismatched bilingual docs.
  - Append results to this file's Review section.
  - Verification: final status, changed files, and any known remaining risks are documented.

## Review

Completed on 2026-06-04.

- Final skill entrypoint: `skills/tidy-skill/SKILL.md`.
- Root-level `SKILL.md` was removed to avoid duplicate authoritative entrypoints.
- Added `skills/tidy-skill/agents/openai.yaml` with display name `洁癖.skill`.
- Rewrote `README.md` and `README.en.md` around CC Switch import, manual install, scripts, and safety boundaries.
- Updated scripts to avoid non-ASCII output in `.ps1` and `.bat` files, fixing Windows PowerShell parsing issues.
- Validation passed: `quick_validate.py skills/tidy-skill`.
- Smoke tests passed:
  - `score_repo_hygiene.py`
  - `score-repo-hygiene.ps1`
  - `audit-agent-artifacts.ps1`
  - `audit-dev-environment.ps1`
  - `clean-agent-artifacts.ps1 -DryRun`

## Polish Pass Plan

- [x] Move `skills/tidy-skill/scripts/README.md` to `skills/tidy-skill/references/script-usage.md`.
  - Verification: no `README.md` remains inside the skill folder; README links still resolve.
- [x] Add CI validation.
  - Verification: workflow validates skill frontmatter, runs Python scoring, runs PowerShell smoke tests, and checks `.ps1/.bat` files stay ASCII-only.
- [x] Add `CONTRIBUTING.md` and `SECURITY.md`.
  - Verification: root documentation covers contribution flow and safety reporting without duplicating skill internals.
- [x] Add README before/after example.
  - Verification: Chinese and English READMEs show the concrete value without bloating the first screen.
- [x] Add Python artifact audit script for portable repo artifact checks.
  - Verification: script runs without dependencies and can write a Markdown report.
- [x] Run validation suite and commit.
  - Verification: git status is clean after commit.

## Polish Pass Review

Completed on 2026-06-04.

- Moved script usage docs from `scripts/README.md` to `references/script-usage.md`; no `README.md` remains inside the skill folder.
- Added `.github/workflows/validate.yml` with Linux Python validation and Windows PowerShell smoke tests.
- Added `tools/validate_skill.py` for repo-local validation of required files, frontmatter, script encoding, and `SKILL.md` resource links.
- Added `CONTRIBUTING.md` and `SECURITY.md`.
- Added README before/after examples and project governance links.
- Added portable Python artifact audit script: `scripts/audit_agent_artifacts.py`.
- Verified:
  - `python tools\validate_skill.py --skill-dir skills\tidy-skill`
  - `python skills\tidy-skill\scripts\score_repo_hygiene.py --root . --json`
  - `python skills\tidy-skill\scripts\audit_agent_artifacts.py --root . --json`
  - system skill `quick_validate.py`
  - PowerShell repo scoring, artifact audit, dev environment audit, and cleanup DryRun
- `audit-workspace-hygiene.ps1` ran successfully; it reported no child Git repositories when pointed at this repo root, which matches its workspace-scan behavior.
- User corrected the display name after this pass. The final display name is `洁癖.skill`; the machine-readable slug remains `tidy-skill`.
- Added `scripts/score_repo_hygiene.py` as the portable, dependency-free Python baseline for repo scoring.
- README now explains the split: Python for portable repo checks, PowerShell for Windows-specific development environment audits.
- Re-ran validation after the Python addition:
  - `quick_validate.py skills/tidy-skill`
  - `score_repo_hygiene.py --root . --json`
  - `score-repo-hygiene.ps1`
  - `audit-agent-artifacts.ps1`
  - `audit-dev-environment.ps1`
  - `clean-agent-artifacts.ps1 -DryRun`
