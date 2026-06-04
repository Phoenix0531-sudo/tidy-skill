#!/usr/bin/env python3
"""Portable local development-environment hygiene audit.

This dependency-free baseline maps package caches, model caches, browser
runtimes, and project-level dependency/build folders. It is read-only and
cross-platform. On Windows, use audit-dev-environment.ps1 for deeper WSL2 and
Docker Desktop VHDX inspection.
"""

from __future__ import annotations

import argparse
import json
import os
import platform
import shutil
import subprocess
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


SKIP_DIRS = {
    ".git",
    "node_modules",
    "dist",
    "build",
    "target",
    ".venv",
    "venv",
    "__pycache__",
    ".next",
    ".nuxt",
    "bin",
    "obj",
    "packages",
}

PROJECT_CACHE_NAMES = {
    "node_modules",
    ".venv",
    "venv",
    "target",
    ".pytest_cache",
    ".mypy_cache",
    ".ruff_cache",
    ".next",
    ".nuxt",
}

PATH_ENV_NAMES = [
    "NPM_CONFIG_CACHE",
    "PNPM_HOME",
    "YARN_CACHE_FOLDER",
    "PIP_CACHE_DIR",
    "UV_CACHE_DIR",
    "UV_TOOL_DIR",
    "UV_PYTHON_INSTALL_DIR",
    "GOPATH",
    "GOMODCACHE",
    "GOCACHE",
    "CARGO_HOME",
    "RUSTUP_HOME",
    "HF_HOME",
    "TRANSFORMERS_CACHE",
    "HUGGINGFACE_HUB_CACHE",
    "OLLAMA_MODELS",
    "TORCH_HOME",
    "PLAYWRIGHT_BROWSERS_PATH",
]


@dataclass(frozen=True)
class CacheItem:
    category: str
    owner: str
    path: Path
    size: int
    touch: str
    next_step: str


def format_size(size: int) -> str:
    units = ["B", "KB", "MB", "GB", "TB"]
    value = float(size)
    for unit in units:
        if value < 1024 or unit == units[-1]:
            if unit == "B":
                return f"{int(value)} B"
            return f"{value:.2f} {unit}"
        value /= 1024
    return f"{size} B"


def safe_command(args: list[str]) -> str:
    executable = shutil.which(args[0])
    if not executable:
        return "Not Installed"
    command = [executable, *args[1:]]
    if os.name == "nt" and executable.lower().endswith((".cmd", ".bat")):
        command = ["cmd", "/c", executable, *args[1:]]
    try:
        result = subprocess.run(command, check=False, capture_output=True, text=True, timeout=5)
    except (OSError, subprocess.TimeoutExpired):
        return "Unknown / Error running command"
    text = (result.stdout or result.stderr or "").strip()
    return text or "Unknown / Empty output"


def dir_size(path: Path) -> int:
    if not path.exists():
        return 0
    if path.is_file():
        try:
            return path.stat().st_size
        except OSError:
            return 0
    total = 0
    for current, dirs, files in os.walk(path):
        dirs[:] = [name for name in dirs if name not in SKIP_DIRS]
        for name in files:
            file_path = Path(current) / name
            try:
                total += file_path.stat().st_size
            except OSError:
                continue
    return total


def existing_cache(category: str, owner: str, path: Path, touch: str, next_step: str) -> CacheItem | None:
    if not path.exists():
        return None
    return CacheItem(category, owner, path, dir_size(path), touch, next_step)


def default_cache_candidates(home: Path) -> list[tuple[str, str, Path, str, str]]:
    local = Path(os.environ.get("LOCALAPPDATA", home / "AppData" / "Local"))
    roaming = Path(os.environ.get("APPDATA", home / "AppData" / "Roaming"))
    return [
        ("Package cache", "npm", home / ".npm", "Safe to review", "Prefer npm cache commands over manual deletion."),
        ("Package cache", "npm", roaming / "npm-cache", "Safe to review", "Prefer npm cache commands over manual deletion."),
        ("Package cache", "pnpm", home / ".pnpm-store", "Safe to review", "Use pnpm store tooling when available."),
        ("Package cache", "yarn", home / ".yarn", "Safe to review", "Confirm project package manager before cleanup."),
        ("Package cache", "pip", home / ".cache" / "pip", "Safe to review", "Use pip cache commands when available."),
        ("Package cache", "pip", local / "pip" / "cache", "Safe to review", "Use pip cache commands when available."),
        ("Package cache", "uv", local / "uv", "Safe to review", "Review uv cache/tool directories before deletion."),
        ("Package cache", "cargo", home / ".cargo", "Review only", "Cargo may include installed tools; inspect owner first."),
        ("Package cache", "rustup", home / ".rustup", "Manual", "Use rustup tooling, not manual deletion."),
        ("Model cache", "Hugging Face", home / ".cache" / "huggingface", "Manual", "Use HF_HOME/HUGGINGFACE_HUB_CACHE for future placement."),
        ("Model cache", "Ollama", home / ".ollama", "Manual", "Use OLLAMA_MODELS for future placement."),
        ("Model cache", "Torch", home / ".cache" / "torch", "Manual", "Use TORCH_HOME for future placement."),
        ("Model cache", "LM Studio", home / ".lmstudio", "Manual", "Use the app settings before moving models."),
        ("Browser runtime", "Playwright", local / "ms-playwright", "Safe to review", "Check active tests before reinstalling browser runtimes."),
        ("Browser runtime", "Puppeteer", home / ".cache" / "puppeteer", "Safe to review", "Check active tests before cleaning browser runtimes."),
    ]


def env_cache_items() -> list[CacheItem]:
    items: list[CacheItem] = []
    for name in PATH_ENV_NAMES:
        value = os.environ.get(name)
        if not value:
            continue
        path = Path(value).expanduser()
        item = existing_cache(
            "Cache environment variable",
            name,
            path,
            "Review only",
            "Audit the current path before changing shell profiles or user environment variables.",
        )
        if item:
            items.append(item)
    return items


def scan_project_caches(roots: list[Path], max_depth: int) -> list[CacheItem]:
    items: list[CacheItem] = []
    for root in roots:
        root = root.resolve()
        root_depth = len(root.parts)
        for current, dirs, _files in os.walk(root):
            current_path = Path(current)
            depth = len(current_path.parts) - root_depth
            if depth > max_depth:
                dirs[:] = []
                continue
            matches = [name for name in dirs if name in PROJECT_CACHE_NAMES]
            for name in matches:
                path = current_path / name
                items.append(
                    CacheItem(
                        "Project cache",
                        name,
                        path,
                        dir_size(path),
                        "Review project first",
                        "Confirm the project can rebuild it, then clean from that project context.",
                    )
                )
            dirs[:] = [name for name in dirs if name not in SKIP_DIRS and name not in PROJECT_CACHE_NAMES]
    return items


def collect_items(roots: list[Path], max_depth: int) -> list[CacheItem]:
    home = Path.home()
    items: list[CacheItem] = []
    for category, owner, path, touch, next_step in default_cache_candidates(home):
        item = existing_cache(category, owner, path.expanduser(), touch, next_step)
        if item:
            items.append(item)
    items.extend(env_cache_items())
    items.extend(scan_project_caches(roots, max_depth))

    deduped: dict[str, CacheItem] = {}
    for item in items:
        key = str(item.path.resolve()).lower()
        previous = deduped.get(key)
        if not previous or item.size > previous.size:
            deduped[key] = item
    return sorted(deduped.values(), key=lambda item: item.size, reverse=True)


def score_items(items: list[CacheItem]) -> tuple[int, str]:
    total = sum(item.size for item in items)
    model_total = sum(item.size for item in items if item.category == "Model cache")
    score = 100
    if total >= 50 * 1024**3:
        score -= 35
    elif total >= 20 * 1024**3:
        score -= 20
    elif total >= 10 * 1024**3:
        score -= 10
    if model_total >= 20 * 1024**3:
        score -= 15
    if any(item.touch == "Manual" and item.size >= 10 * 1024**3 for item in items):
        score -= 10
    score = max(0, min(100, score))
    if score >= 90:
        rating = "Highly controlled"
    elif score >= 70:
        rating = "Mostly controlled"
    elif score >= 50:
        rating = "Pollution risk"
    else:
        rating = "Environment sprawl"
    return score, rating


def risk_for(size: int, watch: int, high: int) -> str:
    if size >= high:
        return "High"
    if size >= watch:
        return "Watch"
    return "Controlled"


def build_payload(items: list[CacheItem], roots: list[Path]) -> dict[str, object]:
    score, rating = score_items(items)
    total = sum(item.size for item in items)
    model_total = sum(item.size for item in items if item.category == "Model cache")
    project_total = sum(item.size for item in items if item.category == "Project cache")
    top = items[:10]
    python_version = safe_command(["python", "--version"])
    if python_version.startswith("Unknown"):
        python_version = f"Python {platform.python_version()} (current interpreter)"
    return {
        "score": score,
        "rating": rating,
        "platform": platform.platform(),
        "roots": [str(root.resolve()) for root in roots],
        "totals": {
            "all": total,
            "model_cache": model_total,
            "project_cache": project_total,
        },
        "tools": {
            "node": safe_command(["node", "--version"]),
            "npm": safe_command(["npm", "--version"]),
            "python": python_version,
            "uv": safe_command(["uv", "--version"]),
            "go": safe_command(["go", "version"]),
            "rustc": safe_command(["rustc", "--version"]),
            "docker": safe_command(["docker", "--version"]),
        },
        "top_items": [
            {
                "category": item.category,
                "owner": item.owner,
                "path": str(item.path),
                "size": item.size,
                "touch": item.touch,
                "next_step": item.next_step,
            }
            for item in top
        ],
    }


def write_report(payload: dict[str, object], report_path: Path) -> None:
    totals = payload["totals"]  # type: ignore[index]
    top_items = payload["top_items"]  # type: ignore[index]
    score = payload["score"]
    rating = payload["rating"]
    total_size = totals["all"]  # type: ignore[index]
    model_size = totals["model_cache"]  # type: ignore[index]
    project_size = totals["project_cache"]  # type: ignore[index]

    lines = [
        "# tidy-skill - Portable Dev Environment Audit",
        "",
        f"**Score:** {score} / 100 - **{rating}**",
        f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"**Platform:** {payload['platform']}",
        "",
        "## Overview Cards",
        "",
        "| Card | Status | Evidence | Next step |",
        "|---|---|---|---|",
        f"| Environment hygiene | {rating} | {score} / 100 | Review the Top 10 plan before cleanup. |",
        f"| Package/cache footprint | {risk_for(total_size, 10 * 1024**3, 20 * 1024**3)} | {format_size(total_size)} detected | Prefer tool-supported cleanup commands. |",
        "| WSL/Docker risk | Manual deep audit | Portable audit does not inspect VHDX files | Use audit-dev-environment.ps1 on Windows. |",
        f"| Model cache risk | {risk_for(model_size, 5 * 1024**3, 10 * 1024**3)} | {format_size(model_size)} detected | Move future models only through tool settings. |",
        "",
        "## Top 10 Optimization Plan",
        "",
    ]
    if top_items:
        lines.extend(["| # | Area | Size | Why it matters | Can touch? | Next step |", "|---:|---|---:|---|---|---|"])
        for index, item in enumerate(top_items, start=1):
            why = f"{item['owner']} owns {item['category']} at {item['path']}"
            lines.append(
                f"| {index} | {item['category']} | {format_size(item['size'])} | {why} | {item['touch']} | {item['next_step']} |"
            )
    else:
        lines.append("_No cache paths found._")

    lines.extend(
        [
            "",
            "## Findings",
            "",
            f"- Total detected cache footprint: {format_size(total_size)}.",
            f"- Model cache footprint: {format_size(model_size)}.",
            f"- Project-local cache footprint: {format_size(project_size)}.",
            "",
            "## Safe Suggestions",
            "",
            "- Keep cleanup read-only or DryRun first.",
            "- Prefer package-manager cleanup commands over manual deletion.",
            "- Clean project-local caches only from the owning project context.",
            "",
            "## Manual / Risky Operations",
            "",
            "- WSL/Docker VHDX inspection, migration, compaction, and data relocation are not handled by this portable script.",
            "- Model cache relocation should use documented tool settings such as HF_HOME, HUGGINGFACE_HUB_CACHE, OLLAMA_MODELS, or TORCH_HOME.",
            "- Do not modify shell profiles, environment variables, or tool state automatically.",
            "",
            "## Tool Versions",
            "",
            "| Tool | Version |",
            "|---|---|",
        ]
    )
    tools = payload["tools"]  # type: ignore[index]
    for name, value in tools.items():  # type: ignore[union-attr]
        lines.append(f"| {name} | `{value}` |")

    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit portable development-environment hygiene.")
    parser.add_argument("--root", action="append", default=[], help="Project/workspace root to scan. May be repeated.")
    parser.add_argument("--report-path", help="Optional Markdown report path.")
    parser.add_argument("--max-depth", type=int, default=3, help="Maximum project cache scan depth.")
    parser.add_argument("--json", action="store_true", help="Print JSON output.")
    args = parser.parse_args()

    roots = [Path(root) for root in args.root]
    for root in roots:
        if not root.is_dir():
            parser.error(f"--root is not a directory: {root}")
    if args.max_depth < 0:
        parser.error("--max-depth must be non-negative")

    items = collect_items(roots, args.max_depth)
    payload = build_payload(items, roots)
    report_path = Path(args.report_path) if args.report_path else None
    if report_path:
        write_report(payload, report_path)
        payload["report_path"] = str(report_path)
    else:
        payload["report_path"] = None

    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print("tidy-skill - Portable Dev Environment Audit")
        print(f"Score: {payload['score']} / 100 - {payload['rating']}")
        print(f"Detected footprint: {format_size(payload['totals']['all'])}")  # type: ignore[index]
        if report_path:
            print(f"Report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
