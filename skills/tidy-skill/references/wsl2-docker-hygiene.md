# WSL2 and Docker Hygiene

Use this reference when the user asks about WSL2, Docker Desktop, virtual disk growth, C-drive pressure, Linux distro migration, or local virtualization footprint.

## Principles

- Audit first, suggest second, never mutate automatically.
- Treat VHDX files as stateful virtual disks, not disposable cache.
- Treat Docker Desktop data as application-managed state.
- Separate facts from safe suggestions from manual high-risk operations.
- Never compact, export, import, move, or delete WSL/Docker storage without a separate explicit migration request.

## What to Audit

| Area | Signals |
|---|---|
| WSL status | `wsl --status`, default version, kernel/update info when available |
| WSL distros | `wsl --list --verbose`, distro name, running/stopped state, WSL version |
| WSL config | `%USERPROFILE%\.wslconfig`, presence of `memory`, `swap`, `processors`, `defaultVhdSize`, `autoMemoryReclaim`, `sparseVhd` |
| WSL VHDX | `ext4.vhdx` / `*.vhdx` path, size, drive letter, likely owner |
| Docker Desktop | Docker version, Docker Desktop WSL backend VHDX hints, Docker settings file presence |
| Risk | C-drive growth, large virtual disks, missing resource caps, unknown owner, stale-looking storage |

## Report Buckets

### Findings

Facts observed from read-only commands and path metadata:

- WSL installation/status.
- Distro list and WSL version.
- `.wslconfig` presence and selected resource keys.
- VHDX file paths and sizes.
- Docker Desktop version and likely WSL backend storage paths.

### Safe Suggestions

Low-risk next steps:

- Review large VHDX owners before taking action.
- Add or review `.wslconfig` resource limits if WSL consumes too much memory.
- Move future model caches by setting tool-supported environment variables.
- Use Docker Desktop UI settings for Docker disk image location where supported.
- Run cleanup scripts only in DryRun first.

### Manual / Risky Operations

Never perform these automatically:

- `wsl --export`, `wsl --import`, or `wsl --unregister`.
- VHDX compaction.
- Docker Desktop data relocation.
- Editing `.wslconfig`.
- Changing environment variables such as `OLLAMA_MODELS`, `HF_HOME`, `GOMODCACHE`, `UV_CACHE_DIR`.
- Deleting VHDX, Docker, distro, model, or tool-state directories.

## Notes from Official Documentation

- WSL2 distributions use virtual hard disk files represented as `ext4.vhdx` on Windows. Microsoft documents disk-space management and VHDX operations separately from normal file deletion.
- Microsoft documents `.wslconfig` as the global configuration file for WSL2 VM settings such as memory, swap, and processors.
- Microsoft documents `wsl --list --verbose`, `wsl --status`, export/import, and distro version management as WSL commands.
- Docker documents that Docker Desktop with the WSL2 backend creates and manages its own virtual disk for storage, and disk image location is managed through Docker Desktop settings.

Sources:

- Microsoft Learn: https://learn.microsoft.com/en-us/windows/wsl/disk-space
- Microsoft Learn: https://learn.microsoft.com/en-us/windows/wsl/basic-commands
- Microsoft Learn: https://learn.microsoft.com/en-us/windows/wsl/wsl-config
- Docker Docs: https://docs.docker.com/docker-for-windows/wsl/
