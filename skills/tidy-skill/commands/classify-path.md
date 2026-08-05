# /classify-path

Classify a proposed path into tidy-skill Classes A–E **before** writing a file.

## Command

```bash
python scripts/classify_artifact.py path/to/proposed.md --root . --json
```

## Output expectations

- Class id and name (A–E)
- Allowed at this path? yes/no
- Placement guidance and safe suggestion
- Does **not** create or delete any file
