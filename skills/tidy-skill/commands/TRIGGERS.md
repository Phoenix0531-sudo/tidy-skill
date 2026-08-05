# Trigger phrases / slash-style commands

These are **documentation triggers** for hosts that map natural language or slash commands to skills. They do not install a runtime server.

Command stubs (markdown playbooks hosts can map):

- [tidy.md](tidy.md) — full read-only pass
- [tidy-score.md](tidy-score.md) — score only
- [audit-artifacts.md](audit-artifacts.md) — artifact scan
- [tidy-doctor.md](tidy-doctor.md) — install + hygiene doctor
- [classify-path.md](classify-path.md) — pre-write class A–E check

| Trigger | Intent | Preferred tool |
|---|---|---|
| `/tidy` or "run tidy-skill" | Full local hygiene pass (read-only first) | score + artifact audit |
| `/tidy-score` or "repo hygiene score" | Score current repo 0-100 | `score_repo_hygiene.py` |
| `/tidy-doctor` or "tidy doctor" | Package + hygiene one-shot gate | `tidy_doctor.py` |
| `/classify-path` or "should I create this file" | Class A–E path check before write | `classify_artifact.py` |
| `/tidy-gate` or "hygiene score gate" | Fail CI if score below policy min | `hygiene_snapshot.py gate` |
| `/audit-artifacts` or "scan agent files" | List suspicious root process files | `audit_agent_artifacts.py` |
| `/audit-env` or "why is my disk growing" | Local cache / WSL / model footprint map | `audit_dev_environment.py` / `.ps1` |
| `/audit-workspace` | Multi-repo parent folder audit | `audit_workspace_hygiene.py` |
| `/tidy-clean-preview` | DryRun cleanup preview only | `clean-agent-artifacts.ps1 -DryRun` |
| `/tidy-hooks-check` | End-of-task read-only stop check | `hooks/stop-hygiene-check.py` |

## Canonical prompts

1. "Score this repository's agent hygiene and list suspicious root Markdown."
2. "Audit agent artifacts under the current repo; do not delete anything."
3. "Map local package and model caches; separate safe suggestions from risky operations."
4. "Scan every Git repo under `D:/Projects` for plan.md/todo.md pollution."
5. "Preview cleanup of expired `.agent_tmp` files in DryRun mode."
6. "Install tidy-skill into Claude and Codex skill folders (preview first)."
7. "Install AGENTS.md hygiene rules into this project without overwriting unless forced."
8. "Before you finish, run the read-only stop hygiene check."
9. "Run tidy doctor on this repo and fail if score is below 80."
10. "Classify whether `plan.md` at the root is allowed before creating it."
11. "Save a hygiene snapshot, then gate CI on `.tidy-skill.json` min_score."

## When not to trigger

- User asked to delete formal docs, source, or Git history
- User asked to compact VHDX / migrate WSL / rewrite Docker data root
- User asked for a full-disk scan without an explicit root
