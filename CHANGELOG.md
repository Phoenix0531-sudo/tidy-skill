# Changelog

All notable changes to this project will be documented in this file.

## [1.5.0] - 2026-08-07

### Added
- `planning_root_globs` policy field (Python + PowerShell) for intentional planning-layout root names
- `is_planning_root_name` / `is_suspicious_root_name` helpers in `policy_loader.py`
- `classify_artifact.py` recognizes `.planning/**` and policy-opted planning root files as Class C working memory
- `audit_agent_artifacts.py` reports a `planning_working_memory` bucket (files under `.planning/` + opted root plan files)
- PWF coexistence policy example `references/tidy-skill.policy.pwf.example.json`
- Peer positioning doc `docs/comparison.md` (planning-with-files, superpowers, addy, anthropic)
- Fixture eval case `planning_with_files_coexistence` (8/8)
- README + README.zh-CN FAQ on planning-with-files coexistence

### Changed
- Score / artifact / workspace audits use `is_suspicious_root_name` so planning opt-ins are not root litter
- `Test-TidyForbiddenName` honors `PlanningRootGlobs` so PowerShell cleanup/score paths match Python
- Fixture evals expanded to 8 cases
- Package version `1.5.0`
- docs hub, SKILL, script-usage document coexistence policy and `.planning/` recognition

## [1.4.0] - 2026-08-05

### Added
- Shared `policy_loader.py` with optional `.tidy-skill.json` / `tidy-skill.policy.json` project policy
- Shared PowerShell `Policy.ps1` (same schema) for Windows hygiene scripts
- `classify_artifact.py` — pre-write Class A–E path classifier (read-only)
- `hygiene_snapshot.py` — save/compare score history + CI `gate` against `min_score`
- `tidy_doctor.py` — one-shot install + hygiene doctor (exit 2 on policy/hygiene fail)
- Policy-aware `--policy` on `audit_agent_artifacts.py`, `score_repo_hygiene.py`, and `audit_workspace_hygiene.py`
- Policy-aware `-Policy` on `score-repo-hygiene.ps1`, `audit-agent-artifacts.ps1`, `audit-workspace-hygiene.ps1`, `clean-agent-artifacts.ps1`
- Example policy template `references/tidy-skill.policy.example.json`
- Command stubs / triggers for doctor, classify, and score gate
- PowerShell policy smoke test `tests/test-policy-ps1.ps1`

### Changed
- Forbidden/protected root patterns centralized in `policy_loader` / `Policy.ps1` (defaults unchanged)
- `audit_workspace_hygiene.py` uses shared policy (per-repo discovery or shared `--policy`)
- `validate_skill.py` / `install-local.ps1` self-check require the new policy modules
- Fixture evals expanded to 7 cases (policy, classify, doctor)
- CI matrix: Python 3.10/3.11/3.12 for lint+tests and package validation; Windows smoke hard-fails safety tests and covers `Policy.ps1`
- CI runs doctor / fixture evals / score gate; drops leftover Qt system packages from the generic CI template
- Package version `1.4.0`
- SKILL / script-usage / README document policy, doctor, classify, and snapshots

## [1.3.0] - 2026-08-05

### Added
- Full install guide `docs/installation.md` with route matrix and doctor steps
- Per-platform setup: Claude, Codex, Cursor, Pi, OpenCode under `docs/platforms/`
- Optional host wiring samples under `docs/host-samples/` (read-only; not auto-installed)
- Command stubs `commands/tidy.md`, `tidy-score.md`, `audit-artifacts.md`
- Case studies: synthetic dirty→clean + this-repo self-audit under `docs/cases/`
- Author-run skills CLI verification log `docs/skills-cli-verify.md`

### Changed
- README (EN/zh) links install matrix, platforms, cases; states CLI is **verified discoverable**
- `validate_skill.py` requires command stub files
- Package version `1.3.0`

## [1.2.0] - 2026-08-05

### Added
- Portable `audit_workspace_hygiene.py` multi-repo audit (explicit root required)
- Read-only stop hook `hooks/stop-hygiene-check.py` and session reminder
- Trigger phrase catalog `commands/TRIGGERS.md`
- Fixture eval harness `tools/run_evals.py` + `docs/evals/latest.md`
- Optional score dimension weights via `--weights`
- Optional pre-commit guard `tools/pre_commit_no_root_process_md.py`
- `install-local.ps1` targets for Cursor, Pi, OpenCode, and `-All`

### Changed
- Ignore `.gitkeep` / `.keep` layout markers in artifact counts
- Cleanup readiness treats empty layout dirs (with markers) as ready
- `validate_skill.py` requires workspace audit + hooks + triggers files
- Version aligned to `1.2.0` in `pyproject.toml`
- Bilingual README: skills CLI compatible install note, evals, hooks, expanded command table

## [1.1.0] - 2026-08-05

### Added
- Portfolio-grade bilingual README (`README.md` English primary, `README.zh-CN.md` full Chinese)
- Banner and terminal self-audit screenshots under `docs/screenshots/`
- Author-run self-audit reports under `docs/self-audit/`
- Tracked `.agent_tmp/.gitkeep` and `.agent_reports/.gitkeep` so clones keep the placement layout

### Changed
- Replaced placeholder root README pair with structured Before/After, install matrix, FAQ, and methodology note
- Removed redundant `README.en.md` (content folded into `README.md`)
- Expanded `.gitignore` for packaging/test caches (`*.egg-info`, `.pytest_cache`, `.ruff_cache`)
- Rewrote `docs/index.md` as a docs hub linking README, SKILL, and self-audit

## [1.0.0] - 2026-06-08

### Added
- Initial public release
- Initial commit: add Agent Tidy Skill
