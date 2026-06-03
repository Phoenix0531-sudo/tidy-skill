# Safety Boundaries Reference

This document defines what Tidy Skill will **never** do. The goal is to make the safety guarantees clear and verifiable.

> "Conservative by default. Destructive only with explicit consent."

---

## Inventory of Safety Guarantees

### 1. No System Modifications

Tidy Skill scripts never:
- Modify the Windows registry
- Change environment variables
- Alter system PATH
- Install system services or daemons
- Modify firewall rules
- Change system security settings

### 2. No Scheduled Task Registration

Tidy Skill scripts never:
- Register Windows Task Scheduler entries
- Create cron jobs
- Add launch agents or daemons
- Schedule automatic execution of any kind

Users may manually configure scheduling. Tidy Skill provides guidance only.

### 3. No Document Deletion

Tidy Skill never deletes by default:
- `README.md`, `README.*.md`
- `CHANGELOG.md`
- `LICENSE`, `LICENSE.*`
- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md`
- `SECURITY.md`
- Everything under `docs/`
- Any Git-tracked file outside `.agent_tmp/` or `.agent_reports/`
- Source code (`src/`, `lib/`, `app/`, etc.)

### 4. No User Document Cleanup

Tidy Skill never:
- Scans personal user folders (`Documents`, `Desktop`, `Downloads`) unless explicitly specified
- Deletes files from user profile directories
- Touches files outside the specified `-Root` path

### 5. No Unknown Markdown Deletion

Tidy Skill never deletes Markdown files of unknown origin. Files in the project root that match agent-produce patterns are **reported, not deleted**, unless the user passes `-ConfirmClean`.

### 6. No Git-tracked File Deletion

Tidy Skill never deletes Git-tracked files by default. Files tracked by Git outside `.agent_tmp/` and `.agent_reports/` are excluded from cleanup operations.

### 7. No Tool State Touching

Tidy Skill never modifies or deletes:
- `.codex/` — Codex CLI state
- `.claude/` — Claude Code state
- `.cursor/` — Cursor editor state
- `.vscode/` — VS Code state
- `.idea/` — JetBrains IDE state
- `*.sqlite` — Any SQLite database files
- `state.json`, `session.json`, `auth-token` — Tool state files
- `workspaceStorage`, `globalStorage` — IDE storage
- `History`, `User/workspaceStorage` — More tool state

### 8. No Administrator Privileges

Tidy Skill scripts never require:
- Administrator / root permissions
- sudo elevation
- UAC elevation
- Special user group membership

All operations use only the current user's permissions.

### 9. No Full-Disk Scanning

Tidy Skill never:
- Scans entire drives (`C:\`, `D:\`, `/`, `/home`)
- Recursively scans the entire filesystem
- Walks into `node_modules`, `.git`, `build/`, `dist/`, `target/`, `.venv/`, `venv/`

All scans are bounded by `-MaxDepth` (default 3). Workspace audits require explicit root specification.

### 10. No Destructive Operations Without Confirmation

Scripts default to DryRun mode. Destructive operations (file deletion) only happen when:
- `-DryRun:$false` is explicitly passed, AND
- For root-level suspicious files: `-ConfirmClean` must also be passed

### 11. No Data Upload

Tidy Skill never:
- Uploads files or data to any network service
- Sends telemetry or analytics
- Phones home
- Logs to remote servers
- Sends crash reports

### 12. No Credential Storage

Tidy Skill never:
- Requests GitHub tokens or API keys
- Writes credentials to files
- Stores personal access tokens
- Creates `~/.netrc` or similar auth files

### 13. No Dependency Installation

Tidy Skill never:
- Runs `npm install`, `pip install`, or similar
- Downloads packages or scripts from the internet
- Requires runtime setup beyond the OS-default PowerShell

### 14. No Network Requirement

Tidy Skill scripts work entirely offline. No internet connection is required for auditing, scoring, or cleanup operations.

### 15. Workspace Audit Requires Explicit Root

`audit-workspace-hygiene.ps1` will not run without an explicitly specified `-Root` parameter. It never defaults to `C:\`, `/`, or the user's home directory.

### 16. Environmental Suggestions Only

Tidy Skill does not automatically:
- Modify shell profiles (`.bashrc`, `.zshrc`, `profile.ps1`)
- Change editor or IDE settings
- Configure agent tooling settings
- Register environment variables

Any environmental optimization suggestions are informational only.

---

## Verification

Users can verify safety guarantees by:

1. **Read the scripts.** All scripts are plain PowerShell. No obfuscation, no binary blobs.
2. **Audit before cleanup.** Run `audit-agent-artifacts.ps1` to see what exists, before running any cleanup.
3. **Always DryRun first.** Cleanup scripts default to preview mode. Nothing is deleted without explicit opt-in.
4. **Run with `-WhatIf` equivalent.** For maximum safety, use `-DryRun` (the default).
5. **No network.** Disconnect from the internet — the scripts still work.

---

## Boundary Summary

| Boundary | Guarantee |
|---|---|
| System modification | Never |
| Scheduled task registration | Never |
| Document deletion | Never without explicit flags |
| User document cleanup | Never |
| Unknown content deletion | Never |
| Git-tracked file deletion | Never without explicit `-ConfirmClean` |
| Tool state modification | Never |
| Admin rights required | Never |
| Full-disk scan | Never |
| Destructive default | Never (always DryRun) |
| Data upload | Never |
| Credential storage | Never |
| Dependency install | Never |
| Network requirement | Never |
| Workspace audit scope | Must be explicit |
| Environmental auto-change | Never (suggestions only) |
