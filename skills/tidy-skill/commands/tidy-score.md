# /tidy-score

Score the current repository hygiene 0–100.

## Command

```bash
python scripts/score_repo_hygiene.py --root . --json
```

Optional weights:

```bash
python scripts/score_repo_hygiene.py --root . --weights references/score-weights.example.json --json
```

## Output expectations

- Total score and rating
- Six dimension breakdown
- List of suspicious root process files if any
