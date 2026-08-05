# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2026-08-05

### Added
- Portfolio-grade bilingual README (`README.md` English primary, `README.zh-CN.md` full Chinese)
- Banner and terminal self-audit screenshots under `docs/screenshots/`
- Author-run self-audit reports under `docs/self-audit/`
  - repo hygiene score
  - agent artifact audit
  - portable dev environment audit
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
