# Changelog

All notable changes to this project will be documented in this file.

## [1.4.0] - 2026-08-05

### Added
- Shared `policy_loader.py` with optional `.tidy-skill.json` / `tidy-skill.policy.json` project policy
- `classify_artifact.py` — pre-write Class A–E path classifier (read-only)
- `hygiene_snapshot.py` — save/compare score history + CI `gate` against `min_score`
- `tidy_doctor.py` — one-shot install + hygiene doctor (exit 2 on policy/hygiene fail)
- Policy-aware `--policy` on `audit_agent_artifacts.py`, `score_repo_hygiene.py`, and `audit_workspace_hygiene.py`
- Example policy template `references/tidy-skill.policy.example.json`
- Command stubs / triggers for doctor, classify, and score gate

### Changed
- Forbidden/protected root patterns centralized in `policy_loader` (defaults unchanged)
- `audit_workspace_hygiene.py` uses shared policy (per-repo discovery or shared `--policy`)
- `validate_skill.py` / `install-local.ps1` self-check require the four new Python modules
- Fixture evals expanded to 7 cases (policy, classify, doctor)
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
