# tidy-skill fixture evals

**Passed:** 4/4

> Author-run deterministic fixtures. Not an independent third-party benchmark.

| Case | Result | Detail |
|---|---|---|
| `dirty_repo_score_below_80` | PASS | score=45 files=['plan.md', 'todo.md'] |
| `clean_repo_score_at_least_90` | PASS | score=100 |
| `gitkeep_not_counted_as_artifact` | PASS | tmp=0 reports=0 |
| `workspace_two_repos_scored` | PASS | n=2 average=53.5 |
