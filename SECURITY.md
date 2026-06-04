# Security Policy

`洁癖.skill` is designed for local, conservative repository and development-environment hygiene checks.

## Safety Guarantees

- No uploads.
- No telemetry.
- No network calls.
- No credential requests.
- No token, session, SQLite, or private log reads.
- No registry, environment variable, or scheduled task changes.
- No full-disk scan by default.
- No destructive cleanup unless explicitly requested.

Cleanup scripts default to DryRun. Root-level suspicious files are reported by default and require explicit confirmation before deletion.

## Reporting Security Issues

Do not open a public issue with sensitive paths, logs, tokens, or machine-specific environment details.

Report security concerns by opening a minimal issue or pull request that describes:

- Which script or rule is affected.
- What unsafe behavior is possible.
- The smallest safe reproduction.
- Whether credentials, private files, or destructive actions are involved.

Use placeholders for private paths and secrets. Never paste real tokens, cookies, API keys, session files, or database contents.

## Scope

Security-relevant behavior includes:

- Reading sensitive files.
- Deleting files outside `.agent_tmp/` or `.agent_reports/`.
- Deleting Git-tracked files unexpectedly.
- Scanning outside an explicitly requested root.
- Installing dependencies or making network calls.
- Modifying tool state directories such as `.codex/`, `.claude/`, `.cursor/`, `.vscode/`, or IDE storage.
