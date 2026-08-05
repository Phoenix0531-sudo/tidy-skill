# Fixture evals

Deterministic, author-run fixtures for hygiene scoring and artifact audit.

```bash
uv run python tools/run_evals.py
```

Latest report: [docs/evals/latest.md](../docs/evals/latest.md)

## Methodology

- Fixtures are synthetic temp directories, not production customer data.
- Scripts under test are this repository's own portable auditors.
- Results are **not** an independent third-party comparison.
