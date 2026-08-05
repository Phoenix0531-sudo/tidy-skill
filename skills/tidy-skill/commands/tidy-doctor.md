# /tidy-doctor

One-shot **read-only** doctor for skill package presence and repo hygiene.

## Command

```bash
python scripts/tidy_doctor.py --root . --json
```

Optional policy / score gate:

```bash
python scripts/tidy_doctor.py --root . --policy .tidy-skill.json --min-score 80 --json
```

## Output expectations

- Skill package core files present
- Repo score and rating
- Suspicious root process files (if any)
- Optional score gate vs policy `min_score`
- Exit `2` when hygiene/policy checks fail (CI-friendly)
