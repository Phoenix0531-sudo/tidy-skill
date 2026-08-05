# /tidy

Run a full **read-only** local hygiene pass on the current repository.

## Steps

1. `score_repo_hygiene.py --root . --json`
2. `audit_agent_artifacts.py --root . --json`
3. Summarize suspicious root files, placement gaps, and safe next steps.
4. Do **not** delete, move, or clean unless the user explicitly asks; if cleanup is requested, preview with DryRun first.

## Safety

- Read-only by default
- No network
- No VHDX / WSL / Docker mutations
