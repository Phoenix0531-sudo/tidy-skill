#!/usr/bin/env python3
"""Read-only end-of-task hygiene check for agent stop hooks.

Reports suspicious root artifacts. Never deletes or modifies files.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path


def find_audit_script() -> Path:
    here = Path(__file__).resolve().parent
    candidate = here.parent / "scripts" / "audit_agent_artifacts.py"
    if candidate.is_file():
        return candidate
    raise FileNotFoundError("audit_agent_artifacts.py not found next to hooks/")


def main() -> int:
    parser = argparse.ArgumentParser(description="Read-only stop-hook hygiene check.")
    parser.add_argument(
        "--root",
        default=os.environ.get("TIDY_SKILL_ROOT")
        or os.environ.get("CLAUDE_PROJECT_DIR")
        or os.environ.get("CODEX_PROJECT_DIR")
        or ".",
        help="Repository root to audit.",
    )
    parser.add_argument("--max-depth", type=int, default=2)
    args = parser.parse_args()

    root = Path(args.root)
    if not root.is_dir():
        print(f"[tidy-skill hook] root is not a directory: {root}", file=sys.stderr)
        return 2

    script = find_audit_script()
    proc = subprocess.run(
        [
            sys.executable,
            str(script),
            "--root",
            str(root),
            "--max-depth",
            str(args.max_depth),
            "--json",
        ],
        check=False,
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        print("[tidy-skill hook] audit failed (read-only; no changes made)", file=sys.stderr)
        if proc.stderr:
            print(proc.stderr, file=sys.stderr)
        return proc.returncode

    try:
        payload = json.loads(proc.stdout)
    except json.JSONDecodeError:
        print(proc.stdout)
        return 0

    summary = payload.get("summary", {})
    suspicious = payload.get("suspicious_root_files", [])
    print("tidy-skill stop check (read-only)")
    print(f"root: {payload.get('root', root)}")
    print(f"suspicious_root: {summary.get('suspicious_root', len(suspicious))}")
    print(f"agent_tmp: {summary.get('agent_tmp', 0)}")
    print(f"agent_reports: {summary.get('agent_reports', 0)}")
    if suspicious:
        print("suspicious files:")
        for name in suspicious:
            print(f"  - {name}")
        print("suggestion: move process files to .agent_tmp/ or .agent_reports/, or delete only with explicit DryRun review")
    else:
        print("no suspicious root process files detected")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
