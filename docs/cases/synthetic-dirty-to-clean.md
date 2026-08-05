# Case: synthetic dirty repo → clean layout

**Kind:** reproducible lab fixture (temp directories)  
**Scripts:** `score_repo_hygiene.py`, `audit_agent_artifacts.py`  
**Source:** `tools/run_evals.py` cases `dirty_repo_score_below_80` / `clean_repo_score_at_least_90`  
**Run date:** 2026-08-05 (author machine)

## Before

Fixture layout:

```text
dirty/
├─ plan.md
├─ todo.md
└─ README.md
```

Observed:

| Metric | Value |
|---|---|
| Hygiene score | **45 / 100** |
| Suspicious root files | `plan.md`, `todo.md` |
| `.agent_tmp/` | missing |
| `.agent_reports/` | missing |

Agent behavior this models: mid-task process Markdown dumped at repo root with no lifecycle.

## After

Fixture layout:

```text
clean/
├─ README.md
├─ LICENSE
├─ CHANGELOG.md
├─ .gitignore          # includes .agent_tmp/ and .agent_reports/
├─ docs/guide.md
├─ .agent_tmp/.gitkeep
└─ .agent_reports/.gitkeep
```

Observed:

| Metric | Value |
|---|---|
| Hygiene score | **100 / 100** |
| Suspicious root files | **0** |
| `.gitkeep` counted as artifacts? | **no** |

## Delta

| | Before | After |
|---|---:|---:|
| Score | 45 | 100 |
| Root process Markdown | 2 | 0 |
| Placement dirs | 0 | 2 |

## Reproduce

```bash
uv run python tools/run_evals.py
# see docs/evals/latest.md
```

## Limits

- Synthetic paths only; not a customer monorepo.
- Scoring model is this project's own rubric.
- Does not measure agent behavior over multi-hour sessions.
