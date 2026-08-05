<div align="center">
<img src="docs/screenshots/banner.png" alt="Tidy Skill: three-layer hygiene model" width="100%">
</div>

<h1 align="center">Tidy Skill</h1>

<p align="center">
  <strong>Let AI agents work inside a clean, explainable, recoverable local environment.</strong>
</p>

<p align="center">
  <a href="https://github.com/Phoenix0531-sudo/Tidy_Skill/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/Phoenix0531-sudo/Tidy_Skill/ci.yml?label=CI" alt="CI"></a>
  <a href="https://github.com/Phoenix0531-sudo/Tidy_Skill/actions/workflows/validate.yml"><img src="https://img.shields.io/github/actions/workflow/status/Phoenix0531-sudo/Tidy_Skill/validate.yml?label=Validate" alt="Validate"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License"></a>
  <img src="https://img.shields.io/badge/Python-3.11-3776AB.svg" alt="Python">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-5391FE.svg" alt="PowerShell">
  <img src="https://img.shields.io/badge/network-offline-lightgrey.svg" alt="offline">
</p>

<p align="center">
  <a href="#before-and-after">Before/After</a> ·
  <a href="#three-layer-hygiene-model">Three Layers</a> ·
  <a href="#quickstart">Quickstart</a> ·
  <a href="#self-audit">Self-Audit</a> ·
  <a href="#artifact-classification">Classification</a> ·
  <a href="#scope">Scope</a> ·
  <a href="#faq">FAQ</a>
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.zh-CN.md">中文</a>
</p>

---

## Before and After

<table>
<tr>
<td width="50%" valign="top">

**Without hygiene governance**

> Agent drops `plan.md`, `todo.md`, `final_report.md` into the repo root.
> Next session re-reads the repo, asks you to restate the goal.
> Sees a large `.venv` or `node_modules` and tries to delete it.

</td>
<td width="50%" valign="top">

**With Tidy Skill**

> Plans stay in chat; reports go to `.agent_reports/`; temp files go to `.agent_tmp/`.
> Audits list paths, sizes, risks, and **safe suggestions** — no auto-deletion.
> Cleanup defaults to **DryRun**; migration, compaction, and config edits are suggestions only.

</td>
</tr>
</table>

## Three-Layer Hygiene Model

| Layer | Governs | Typical Problem | Tools |
|---|---|---|---|
| **Repository** | Agent artifacts | `plan.md`, `todo.md` pile up in repo root | `audit_agent_artifacts.py`, `score_repo_hygiene.py` |
| **Workspace** | Dev caches | `node_modules`, `.venv`, `target`, build caches sprawl | `audit-workspace-hygiene.ps1` |
| **Local machine** | Environment footprint | WSL2/Docker VHDX growth, package/model caches sprawl | `audit-dev-environment.ps1`, `audit_dev_environment.py` |

<p align="center">
  <img src="docs/screenshots/preview.png" alt="Terminal self-audit: score_repo_hygiene and audit_agent_artifacts" width="90%">
</p>

## Quickstart

```bash
git clone https://github.com/Phoenix0531-sudo/Tidy_Skill.git
cd Tidy_Skill
uv sync --extra dev

# Score this repo's hygiene
uv run python skills/tidy-skill/scripts/score_repo_hygiene.py --root . --json
# {"score": 77, "rating": "Mostly clean", ...}

# Audit agent artifacts
uv run python skills/tidy-skill/scripts/audit_agent_artifacts.py --root . --json

# Audit local dev environment (read-only)
uv run python skills/tidy-skill/scripts/audit_dev_environment.py --root . --json

# Windows deep audit (WSL2/Docker/VHDX)
pwsh skills/tidy-skill/scripts/audit-dev-environment.ps1 -Roots .

# Cleanup preview (DryRun, deletes nothing)
pwsh skills/tidy-skill/scripts/clean-agent-artifacts.ps1 -Root . -DryRun

# Tests
uv run pytest tests/
uv run ruff check . --select E9,F63,F7,F82
```

### Install Matrix

| Tier | What you get | How |
|---|---|---|
| **Enhanced** | Windows deep audit: WSL2, Docker VHDX, package/model caches + DryRun cleanup | PowerShell scripts under `skills/tidy-skill/scripts/*.ps1` |
| **Standard** | Portable repo scoring + artifact audit + env baseline (cross-platform) | `uv run python skills/tidy-skill/scripts/*.py` |
| **Manual** | Shared hygiene rules for multi-agent projects | `install-rule-template.ps1` or copy `templates/AGENTS.md`, `CLAUDE.md`, `cursor-rule.mdc` |

Install the skill package into local agent hubs (preview first):

```powershell
pwsh skills/tidy-skill/scripts/install-local.ps1
# actual copy requires explicit confirmation:
pwsh skills/tidy-skill/scripts/install-local.ps1 -DryRun:$false -Force
```

## Self-Audit

This repository runs its own scripts against itself. Latest author-run reports:

| Report | Path | Snapshot |
|---|---|---|
| Repo hygiene score | [docs/self-audit/repo_hygiene_score.md](docs/self-audit/repo_hygiene_score.md) | **77 / 100** — Mostly clean |
| Agent artifact audit | [docs/self-audit/agent_artifacts_audit.md](docs/self-audit/agent_artifacts_audit.md) | **0** suspicious root files |
| Dev environment audit | [docs/self-audit/dev_environment_audit.md](docs/self-audit/dev_environment_audit.md) | **90 / 100** — Highly controlled |

Regenerate:

```bash
uv run python skills/tidy-skill/scripts/score_repo_hygiene.py --root . --report-path docs/self-audit/repo_hygiene_score.md
uv run python skills/tidy-skill/scripts/audit_agent_artifacts.py --root . --max-depth 3 --report-path docs/self-audit/agent_artifacts_audit.md
uv run python skills/tidy-skill/scripts/audit_dev_environment.py --root . --report-path docs/self-audit/dev_environment_audit.md
```

> **Methodology note.** Self-audit by own scripts, not independent. Internal v1, author-run on a single Windows machine; not an independent comparison and not a third-party benchmark.

## Artifact Classification

Five-level placement model (see [SKILL.md](skills/tidy-skill/SKILL.md)):

| Class | Kind | Placement | Example |
|---|---|---|---|
| **A** | Formal docs | Repo root / `docs/` | `README.md`, `CHANGELOG.md`, design specs |
| **B** | User deliverables | Agreed output path | Final report the user asked for |
| **C** | Temporary artifacts | `.agent_tmp/` | Scratch notes, intermediate drafts |
| **D** | Self-congratulatory noise | Do not keep | "Mission complete" fluff docs |
| **E** | Tool / agent state | Outside tracked tree or ignored | IDE state, session caches |

## Commands

| Script | Purpose | Invoke |
|---|---|---|
| `score_repo_hygiene.py` | Score repo hygiene 0–100 across 6 dimensions | `uv run python skills/tidy-skill/scripts/score_repo_hygiene.py --root . --json` |
| `audit_agent_artifacts.py` | List suspicious root files and protected docs | `uv run python skills/tidy-skill/scripts/audit_agent_artifacts.py --root . --json` |
| `audit_dev_environment.py` | Portable local cache / env baseline | `uv run python skills/tidy-skill/scripts/audit_dev_environment.py --root . --json` |
| `audit-dev-environment.ps1` | Windows deep audit (WSL2 / Docker / VHDX) | `pwsh skills/tidy-skill/scripts/audit-dev-environment.ps1 -Roots .` |
| `audit-workspace-hygiene.ps1` | Multi-repo workspace cache scan | `pwsh skills/tidy-skill/scripts/audit-workspace-hygiene.ps1 -Root <path>` |
| `clean-agent-artifacts.ps1` | Clean expired agent temp/report files | `pwsh skills/tidy-skill/scripts/clean-agent-artifacts.ps1 -Root . -DryRun` |
| `install-local.ps1` | Install skill into Codex / Claude dirs | `pwsh skills/tidy-skill/scripts/install-local.ps1` |
| `install-rule-template.ps1` | Install AGENTS / CLAUDE / Cursor templates | `pwsh skills/tidy-skill/scripts/install-rule-template.ps1 -TargetRoot <path>` |

Python scripts are pure stdlib (no network, no third-party runtime deps). Cleanup and install scripts default to DryRun.

## Scope

**In scope**

- Read-only audits of agent artifacts, repo hygiene, and local cache footprints
- DryRun cleanup previews for `.agent_tmp/` / `.agent_reports/`
- Rule templates so multiple agents share the same placement policy
- Offline, local-only operation

**Out of scope**

- Automatic deletion of formal docs, source, or Git-tracked files
- Automatic WSL distro migration, VHDX compaction, or Docker data moves
- Token / credential / database / private log reads
- Full-disk scans without an explicit root
- Network calls or uploads

## FAQ

<details>
<summary>Will cleanup delete my files by default?</summary>

No. `clean-agent-artifacts.ps1` defaults to **DryRun** and only previews candidates under agent temp/report directories. Actual deletion requires explicit confirmation flags. Audits never delete.

</details>

<details>
<summary>Why both Python and PowerShell?</summary>

Python covers portable, dependency-free repo and baseline environment checks on any platform. PowerShell adds Windows-depth visibility into WSL2, Docker Desktop VHDX, and user-profile caches that pure Python cannot safely introspect the same way.

</details>

<details>
<summary>When should I not use this skill?</summary>

Do not use it as a general disk cleaner, security scanner, or replacement for backup tools. It will not auto-fix a full C: drive, compact VHDX files, or rewrite agent configs. If you need those operations, follow the vendor docs and treat this skill's output as suggestions only.

</details>

## Layout

```text
Tidy_Skill/
├─ skills/tidy-skill/
│  ├─ SKILL.md                 # skill definition (three-layer model, classes A–E)
│  ├─ scripts/                 # Python + PowerShell tools
│  ├─ templates/               # AGENTS.md / CLAUDE.md / cursor-rule
│  ├─ references/              # deeper usage notes
│  └─ examples/
├─ tools/validate_skill.py     # skill package validation
├─ tests/                      # pytest + PowerShell safety tests
├─ docs/
│  ├─ screenshots/             # banner + terminal preview
│  └─ self-audit/              # author-run reports
├─ .github/workflows/          # ci.yml + validate.yml
├─ pyproject.toml
└─ README.md / README.zh-CN.md
```

## License

MIT. See [LICENSE](LICENSE).
