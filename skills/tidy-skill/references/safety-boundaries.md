# Safety Boundaries Reference

This document defines what 洁癖.skill will **never** do. The goal is to make the safety guarantees clear and verifiable.

> "Conservative by default. Destructive only with explicit consent."

---

## Inventory of Safety Guarantees

### 1. No System Modifications

洁癖.skill scripts never:
- Modify the Windows registry
- Change environment variables
- Alter system PATH
- Edit `.wslconfig`
- Change Docker Desktop settings
- Move package manager or model cache locations
- Install system services or daemons
- Modify firewall rules
- Change system security settings

### 2. No Scheduled Task Registration

洁癖.skill scripts never:
- Register Windows Task Scheduler entries
- Create cron jobs
- Add launch agents or daemons
- Schedule automatic execution of any kind

Users may manually configure scheduling. 洁癖.skill provides guidance only.

### 3. No Document Deletion

洁癖.skill never deletes by default:
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

洁癖.skill never:
- Scans personal user folders (`Documents`, `Desktop`, `Downloads`) unless explicitly specified
- Deletes files from user profile directories
- Touches files outside the specified `-Root` path

### 5. No Unknown Markdown Deletion

洁癖.skill never deletes Markdown files of unknown origin. Files in the project root that match agent-produce patterns are **reported, not deleted**, unless the user passes `-ConfirmClean`.

### 6. No Git-tracked File Deletion

洁癖.skill never deletes Git-tracked files. Cleanup scripts detect Git-tracked paths and skip them, even when root-level cleanup is explicitly enabled.

### 7. No Tool State Touching

洁癖.skill never modifies or deletes:
- `.codex/` — Codex CLI state
- `.claude/` — Claude Code state
- `.cursor/` — Cursor editor state
- `.vscode/` — VS Code state
- `.idea/` — JetBrains IDE state
- `*.sqlite` — Any SQLite database files
- `state.json`, `session.json`, `auth-token` — Tool state files
- `workspaceStorage`, `globalStorage` — IDE storage
- `History`, `User/workspaceStorage` — More tool state

### 7b. No WSL or Docker Mutation

洁癖.skill never:
- Compacts VHDX files
- Deletes `ext4.vhdx` or Docker virtual disks
- Runs `wsl --export`, `wsl --import`, or `wsl --unregister`
- Moves Docker Desktop data
- Edits `.wslconfig`
- Changes Docker Desktop settings

### 8. No Administrator Privileges

洁癖.skill scripts never require:
- Administrator / root permissions
- sudo elevation
- UAC elevation
- Special user group membership

All operations use only the current user's permissions.

### 9. No Full-Disk Scanning

洁癖.skill never:
- Scans entire drives (`C:\`, `D:\`, `/`, `/home`)
- Recursively scans the entire filesystem
- Walks into `node_modules`, `.git`, `build/`, `dist/`, `target/`, `.venv/`, `venv/`

All scans are bounded by `-MaxDepth` (default 3). Workspace audits require explicit root specification.

### 10. No Destructive Operations Without Confirmation

Scripts default to DryRun mode. Destructive operations (file deletion) only happen when:
- `-DryRun:$false` is explicitly passed, AND
- For root-level suspicious files: `-ConfirmClean` must also be passed

### 11. No Data Upload

洁癖.skill never:
- Uploads files or data to any network service
- Sends telemetry or analytics
- Phones home
- Logs to remote servers
- Sends crash reports

### 12. No Credential Storage

洁癖.skill never:
- Requests GitHub tokens or API keys
- Writes credentials to files
- Stores personal access tokens
- Creates `~/.netrc` or similar auth files

### 13. No Dependency Installation

洁癖.skill never:
- Runs `npm install`, `pip install`, or similar
- Downloads packages or scripts from the internet
- Requires dependency installation for the Python baseline or PowerShell audits

### 14. No Network Requirement

洁癖.skill scripts work entirely offline. No internet connection is required for auditing, scoring, or cleanup operations.

### 15. Workspace Audit Requires Explicit Root

`audit-workspace-hygiene.ps1` will not run without an explicitly specified `-Root` parameter. It never defaults to `C:\`, `/`, or the user's home directory.

### 16. Environmental Suggestions Only

洁癖.skill does not automatically:
- Modify shell profiles (`.bashrc`, `.zshrc`, `profile.ps1`)
- Change editor or IDE settings
- Configure agent tooling settings
- Register environment variables

Any environmental optimization suggestions are informational only.

---

## Verification

Users can verify safety guarantees by:

1. **Read the scripts.** Scripts are plain Python or PowerShell. No obfuscation, no binary blobs.
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
| Git-tracked file deletion | Never |
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
