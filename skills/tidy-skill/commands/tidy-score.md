# /tidy-score

Score the current repository hygiene 0–100.

## Command

```bash
python scripts/score_repo_hygiene.py --root . --json
```

Optional weights / project policy:

```bash
python scripts/score_repo_hygiene.py --root . --weights references/score-weights.example.json --json
python scripts/score_repo_hygiene.py --root . --policy .tidy-skill.json --json
```

CI score gate (uses policy `min_score` when present):

```bash
python scripts/hygiene_snapshot.py gate --root . --json
```

## Output expectations

- Total score and rating
- Six dimension breakdown
- List of suspicious root process files if any
- Gate exit `2` when below min score
