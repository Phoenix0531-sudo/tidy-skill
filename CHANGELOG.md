# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

_Nothing yet._

## [1.9.1] - 2026-08-09

### Changed
- **Logo redesign (light, tidy).** Replaced the dark hex-prism mark from v1.9.0 with a light, airy Notion/Linear-family mark: three dots riding a shallow cradle arc, the third lit sage-green = "ready", first two slate-dark. Same for the motion GIF (cradle arc draws in → dots drop in order → ready dot lights). Re-audited 16px favicon fidelity (opaque larger dots survive at 16px). See [docs/branding.md](docs/branding.md).

## [1.9.0] - 2026-08-09

### Added
- **Project logo + README motion GIF.** Light, tidy mark (`assets/readme/logo.svg`, 512px icon: three dots riding a shallow cradle arc, the third lit sage-green = "ready", first two slate-dark) — Notion/Linear family, light palette per the "clean/tidy" brief. Exported PNG sizes (16/32/48/192/512/1024/2048) and favicon. A GitHub-safe animated `tidy-motion.gif` (cradle arc draws in → dots drop in order → ready dot lights) replaces the top banner as the README hero; the three-layer mechanism banner moves inline to the *Three-Layer Hygiene Model* section. See [docs/branding.md](docs/branding.md).
- `tools/svg_to_png.js` — zero-native-dep SVG→PNG exporter using `@resvg/resvg-js` (WASM).
- `tools/render_motion_frames.js` — per-frame renderer for the motion GIF (resvg does not run SMIL timelines).
- Logo concept art and preview under `logos/` (`concept-1..4`, `iteration-1`, `preview.html`).

## [1.8.0] - 2026-08-08

### Added
- `tools/release.py`: dry-run-first release helper. Bumps `pyproject.toml`,
  migrates `[Unreleased]` notes into a dated section, updates the doctor
  version label in `docs/index.md`, regenerates `docs/self-audit/tidy_doctor.md`
  under `--strict`, then optionally `--commit` / `--tag` / `--push` as a chained
  opt-in sequence. Refuses empty Unreleased notes, dirty trees, and non-strict
  version increments.
- `tests/test_release.py` covers version math, CHANGELOG migration, empty
  Unreleased rejection, index label rewrite, default read-only CLI, and the
  apply/commit/tag/push guard chain.

### Changed
- **Get-RelativePath / Resolve-TidyRoot dedup**: the 8.3-safe path helpers live
  once in `Policy.ps1`. `audit-agent-artifacts.ps1` and `clean-agent-artifacts.ps1`
  call the shared functions instead of carrying independent copies.
- `CONTRIBUTING.md` documents the release workflow.

## [1.7.1] - 2026-08-08 (patch)

### Fixed
- **Windows CI 8.3 short-name path mismatch (audit)**: `audit-agent-artifacts.ps1`
  used `$Root.Substring()` in `Get-RelativePath`; on Windows runners `$env:TEMP`
  is an 8.3 short name (`C:\Users\RUNNER~1\...`) while `Get-ChildItem -Recurse`
  returns long-form `FullName`s (`C:\Users\runneradmin\...`), so the prefix never
  matched and every root file silently dropped out of the suspicious scan.
  `Get-RelativePath` now does an `OrdinalIgnoreCase` prefix match with a
  `GetFileName()` fallback, and `$Root` is canonicalized via `Get-Item.FullName`.
  Fixes `test-policy-ps1.ps1` audit assertion failing only on Windows smoke.
- **Windows CI 8.3 short-name path mismatch (clean)**: `clean-agent-artifacts.ps1`
  carried an independent copy of the same `Get-RelativePath` with the identical bug;
  git-tracked root files were mis-keyed as untracked and deleted. Same fix applied
  (canonicalized `$Root` + tolerant `Get-RelativePath`). Fixes
  `test-clean-agent-artifacts.ps1` deleting a tracked `plan.md` on Windows smoke.
- **Cross-platform test assertion**: `test_classify_artifact_stdin_batch_emits_ndjson`
  hard-coded Windows backslashes in expected paths and failed on Linux CI.
  Comparison now normalizes path separators.

## [1.7.0] - 2026-08-08

### Added
- `classify_artifact.py` **stdin batch mode**: pass `-` or `--stdin` to read
  one path per line and emit NDJSON (with `--json`). Blank lines and `#`-comment
  lines are skipped, so an agent can classify a whole proposed layout in one
  tool call without scripting a loop.
- `Invoke-TidyRepair` in `Policy.ps1` — PowerShell mirror of `tidy_repair.py`
  (dryrun default, `-Apply` for layout dirs, `-Apply -MoveRoot` for careful root
  moves; same guard contract: never auto-write host configs, never move
  protected/git-tracked files).
- `tidy_repair.py` added to the Windows PowerShell smoke step and a new Repair
  DryRun smoke step in the CI workflow (`.github/workflows/validate.yml`).
- `docs/cases/guard-contract.md` — reference case documenting the guard verb
  (protected docs, git-tracked files, apply-time recheck, destination
  collision, host configs, VHDX/Docker) with reproduction commands and the
  exit-code 2 semantics; indexed in `docs/cases/README.md`.
- Repair test boundary cases: destination collision (exit 2), apply-time
  git-tracked recheck, custom non-Markdown forbidden policy, and `.planning/`
  files untouched.

### Changed
- Docs (README EN/ZH, script-usage, SKILL, CONTRIBUTING) document the stdin
  batch mode for `classify_artifact.py`.
- `tidy_repair.py` `plan_root_moves` now passes the policy to `audit()` so
  custom `forbidden_globs` / `planning_root_globs` are honored at repair time.
- `docs/skills-cli-verify.md` records a **2026-08-08 re-verification**: with
  github.com connectivity restored, `npx skills add --list` plus `--copy`
  installs to codex / claude-code / cursor / pi all succeeded (exit 0) into
  `.agents/` / `.claude/` / `.pi/` landing trees, closing the earlier
  transient network-block.

## [1.6.0] - 2026-08-07

### Added
- `tidy_repair.py` — DryRun-first safe repairs companion to doctor
  (create `.agent_tmp/` + `.agent_reports/` with `.gitkeep`; optional
  `--apply --move-root` for untracked suspicious root Markdown;
  refuses git-tracked / protected / host configs)
- Product **safety verbs**: dryrun · careful · guard (README, SKILL,
  installation, repair CLI)
- README **four failure modes** (root litter / cache sprawl / unsafe
  cleanup / no CI gate) in EN + ZH
- Dual install philosophy (subscribe via skills CLI vs editable clone/local)
- Installation: retention knobs table + uninstall/reset section
- Comparison docs (EN + ZH): ECC, gstack, mattpocock peers + learn-from table
- Doctor recommendations now point at `tidy_repair` / `tidy-install-hooks`

### Changed
- `script-usage.md` documents `tidy_repair.py` and `tidy-install-hooks.py`
- Commands tables in README / README.zh-CN / SKILL.md include repair + hooks emitter
- Package version bumped to 1.6.0

## [1.5.1] - 2026-08-07

### Added
- `tidy_doctor.py` detects host hook integration: scans Claude/Codex/Cursor/Pi
  config files for a `stop-hygiene-check` reference and reports `wired`/
  `unwired`/`absent` (warn-only, never fails the gate)
- `tidy-install-hooks.py` — DryRun-first emitter for host hook config snippets
  (claude/codex/cursor/pi); `-W/--write` requires `--force` to overwrite
- `Policy.ps1` gains `Test-TidyHostHookIntegration` and `Get-TidyArtifactClass`
  (PowerShell mirrors of the Python doctor integration check and
  `classify_artifact.py` A–E classes, including `.planning/` and
  `planning_root_globs` opt-in)
- `docs/cases/pwf-coexistence.md` — PWF coexistence scenario case
- `docs/comparison.zh-CN.md` — Chinese mirror of the peer-positioning doc

### Changed
- `docs/cases/README.md` indexes the PWF case
- `README.zh-CN.md` links the Chinese comparison doc

### Fixed
- `docs/skills-cli-verify.md` now covers **four** agent targets —
  codex, claude-code, cursor, and pi (copy mode); records the
  `claude` → `claude-code` adapter-name quirk and the per-adapter landing
  path difference (`.claude/` vs `.agents/` vs `.pi/`)

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
