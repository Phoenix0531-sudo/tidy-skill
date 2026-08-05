# tidy-skill fixture evals

**Passed:** 7/7

> Author-run deterministic fixtures. Not an independent third-party benchmark.

| Case | Result | Detail |
|---|---|---|
| `dirty_repo_score_below_80` | PASS | score=45 files=['plan.md', 'todo.md'] |
| `clean_repo_score_at_least_90` | PASS | score=100 |
| `gitkeep_not_counted_as_artifact` | PASS | tmp=0 reports=0 |
| `workspace_two_repos_scored` | PASS | n=2 average=53.5 |
| `policy_extends_forbidden_patterns` | PASS | suspicious=['scratch.md'] |
| `classify_artifact_a_d_e_c` | PASS | A=A D=D E=E C=C |
| `doctor_fails_on_dirty_repo` | PASS | failed=True score=45 files=['plan.md', 'todo.md'] |
