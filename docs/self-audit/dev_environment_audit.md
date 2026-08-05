# tidy-skill - Portable Dev Environment Audit

**Score:** 90 / 100 - **Highly controlled**
**Generated:** 2026-08-05 19:01:37
**Platform:** Windows-10-10.0.19045-SP0

## Overview Cards

| Card | Status | Evidence | Next step |
|---|---|---|---|
| Environment hygiene | Highly controlled | 90 / 100 | Review the Top 10 plan before cleanup. |
| Package/cache footprint | Watch | 18.59 GB detected | Prefer tool-supported cleanup commands. |
| WSL/Docker risk | Manual deep audit | Portable audit does not inspect VHDX files | Use audit-dev-environment.ps1 on Windows. |
| Model cache risk | Controlled | 0 B detected | Move future models only through tool settings. |

## Top 10 Optimization Plan

| # | Area | Size | Why it matters | Can touch? | Next step |
|---:|---|---:|---|---|---|
| 1 | Package cache | 6.15 GB | uv owns Package cache at <user-home>\AppData\Local\uv | Safe to review | Review uv cache/tool directories before deletion. |
| 2 | Cache environment variable | 2.53 GB | RUSTUP_HOME owns Cache environment variable at <toolchain> | Review only | Audit the current path before changing shell profiles or user environment variables. |
| 3 | Cache environment variable | 2.07 GB | UV_PYTHON_INSTALL_DIR owns Cache environment variable at <toolchain> | Review only | Audit the current path before changing shell profiles or user environment variables. |
| 4 | Cache environment variable | 1.68 GB | UV_CACHE_DIR owns Cache environment variable at <toolchain> | Review only | Audit the current path before changing shell profiles or user environment variables. |
| 5 | Cache environment variable | 1.63 GB | GOPATH owns Cache environment variable at <toolchain> | Review only | Audit the current path before changing shell profiles or user environment variables. |
| 6 | Cache environment variable | 1.63 GB | GOMODCACHE owns Cache environment variable at <toolchain> | Review only | Audit the current path before changing shell profiles or user environment variables. |
| 7 | Cache environment variable | 1.53 GB | CARGO_HOME owns Cache environment variable at <toolchain> | Review only | Audit the current path before changing shell profiles or user environment variables. |
| 8 | Browser runtime | 688.45 MB | Playwright owns Browser runtime at <user-home>\AppData\Local\ms-playwright | Safe to review | Check active tests before reinstalling browser runtimes. |
| 9 | Cache environment variable | 350.95 MB | GOCACHE owns Cache environment variable at <toolchain> | Review only | Audit the current path before changing shell profiles or user environment variables. |
| 10 | Package cache | 332.24 MB | pip owns Package cache at <user-home>\AppData\Local\pip\cache | Safe to review | Use pip cache commands when available. |

## Findings

- Total detected cache footprint: 18.59 GB.
- Model cache footprint: 0 B.
- Project-local cache footprint: 37.64 MB.

## Safe Suggestions

- Keep cleanup read-only or DryRun first.
- Prefer package-manager cleanup commands over manual deletion.
- Clean project-local caches only from the owning project context.

## Manual / Risky Operations

- WSL/Docker VHDX inspection, migration, compaction, and data relocation are not handled by this portable script.
- Model cache relocation should use documented tool settings such as HF_HOME, HUGGINGFACE_HUB_CACHE, OLLAMA_MODELS, or TORCH_HOME.
- Do not modify shell profiles, environment variables, or tool state automatically.

## Tool Versions

| Tool | Version |
|---|---|
| node | `v26.0.0` |
| npm | `11.12.1` |
| python | `Python 3.13.13` |
| uv | `uv 0.11.18 (e32666915 2026-06-01 x86_64-pc-windows-msvc)` |
| go | `go version go1.26.5 windows/amd64` |
| rustc | `rustc 1.97.1 (8bab26f4f 2026-07-14)` |
| docker | `Docker version 29.6.2, build dfc4efb` |
