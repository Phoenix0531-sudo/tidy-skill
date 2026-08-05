# Changelog

All notable changes to this project will be documented in this file.

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
