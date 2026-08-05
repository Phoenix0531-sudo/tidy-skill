# /audit-artifacts

List suspicious root agent process files and placement directories.

## Command

```bash
python scripts/audit_agent_artifacts.py --root . --max-depth 3 --json
```

## Rules

- Report only
- Ignore `.gitkeep` / `.keep` layout markers
- Never delete files as part of this command
