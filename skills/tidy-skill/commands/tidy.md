# /tidy

Run a full **read-only** local hygiene pass on the current repository.

## Steps

1. Prefer `tidy_doctor.py --root . --json` for a one-shot package + hygiene gate.
2. Or run `score_repo_hygiene.py --root . --json` and `audit_agent_artifacts.py --root . --json`.
3. Optional: `hygiene_snapshot.py save --root .` to record score history under `.agent_reports/hygiene-history/`.
4. Summarize suspicious root files, placement gaps, and safe next steps.
5. Do **not** delete, move, or clean unless the user explicitly asks; if cleanup is requested, preview with DryRun first.

## Safety

- Read-only by default
- No network
- No VHDX / WSL / Docker mutations
