#!/usr/bin/env python3
"""Fail when staged root-level agent process Markdown files are present."""

from __future__ import annotations

import re
import sys

FORBIDDEN = [
    r"^todo\.md$",
    r"^plan\.md$",
    r"^notes\.md$",
    r"^lessons\.md$",
    r"^summary\.md$",
    r"^report\.md$",
    r"^final_report\.md$",
    r"^implementation_plan\.md$",
    r"^migration_plan\.md$",
    r"^audit_report\.md$",
    r"^cleanup_report\.md$",
    r"^task_list\.md$",
    r"^progress\.md$",
    r"^work_summary\.md$",
    r"^changes_summary\.md$",
    r"^.+_summary\.md$",
    r"^.+_report\.md$",
    r"^.+_plan\.md$",
]


def is_forbidden_root(path: str) -> bool:
    normalized = path.replace("\\", "/")
    if "/" in normalized:
        return False
    name = normalized.lower()
    return any(re.match(pattern, name) for pattern in FORBIDDEN)


def main(argv: list[str]) -> int:
    offenders = [path for path in argv[1:] if is_forbidden_root(path)]
    if not offenders:
        return 0
    print("tidy-skill pre-commit: refusing root agent process Markdown:")
    for path in offenders:
        print(f"  - {path}")
    print("Move to .agent_tmp/ or .agent_reports/, or unstage the file.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
