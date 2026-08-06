#!/usr/bin/env python3
"""Fail when staged root-level agent process Markdown files are present.

Uses the shared policy_loader so that forbidden patterns stay in sync with
audit_agent_artifacts.py and the rest of the tidy-skill surface.
"""

from __future__ import annotations

import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
SKILL_SCRIPTS = SCRIPT_DIR.parent / "skills" / "tidy-skill" / "scripts"
if str(SKILL_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(SKILL_SCRIPTS))

from policy_loader import discover_policy, is_forbidden_name  # noqa: E402


def is_forbidden_root(path: str, repo_root: Path | None = None) -> bool:
    """True when *path* is a root-level file matching a forbidden pattern."""
    normalized = path.replace("\\", "/")
    if "/" in normalized:
        return False
    root = repo_root or Path.cwd()
    policy = discover_policy(root)
    return is_forbidden_name(normalized, policy)


def main(argv: list[str]) -> int:
    repo_root = Path.cwd()
    offenders = [path for path in argv[1:] if is_forbidden_root(path, repo_root)]
    if not offenders:
        return 0
    print("tidy-skill pre-commit: refusing root agent process Markdown:")
    for path in offenders:
        print(f"  - {path}")
    print("Move to .agent_tmp/ or .agent_reports/, or unstage the file.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
