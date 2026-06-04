#!/usr/bin/env python3
"""Audit a repository for AI agent-generated artifacts.

This dependency-free script is the portable companion to
audit-agent-artifacts.ps1. It reports suspicious root-level process files,
agent temp/report directories, and protected documentation without modifying
anything.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


FORBIDDEN_ROOT_PATTERNS = [
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

PROTECTED_DOC_PATTERNS = [
    r"^readme\.md$",
    r"^readme\..+\.md$",
    r"^changelog\.md$",
    r"^license$",
    r"^license\..+$",
    r"^contributing\.md$",
    r"^code_of_conduct\.md$",
    r"^security\.md$",
]

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


@dataclass(frozen=True)
class AuditResult:
    root: Path
    suspicious_root: list[Path]
    agent_tmp: list[Path]
    agent_reports: list[Path]
    protected_docs: list[Path]
    report_path: Path | None


def rel(path: Path, root: Path) -> str:
    try:
        return str(path.relative_to(root)).replace("\\", "/")
    except ValueError:
        return str(path)


def matches(patterns: list[str], name: str) -> bool:
    lowered = name.lower()
    return any(re.match(pattern, lowered) for pattern in patterns)


def iter_files(root: Path, max_depth: int) -> list[Path]:
    files: list[Path] = []
    root_depth = len(root.parts)
    for path in root.rglob("*"):
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        if not path.is_file():
            continue
        depth = len(path.parent.parts) - root_depth
        if depth <= max_depth:
            files.append(path)
    return files


def audit(root: Path, max_depth: int, report_path: Path | None) -> AuditResult:
    root = root.resolve()
    files = iter_files(root, max_depth)
    suspicious_root: list[Path] = []
    agent_tmp: list[Path] = []
    agent_reports: list[Path] = []
    protected_docs: list[Path] = []

    for file_path in files:
        relative_parts = file_path.relative_to(root).parts
        first = relative_parts[0] if relative_parts else ""
        if len(relative_parts) == 1 and matches(FORBIDDEN_ROOT_PATTERNS, file_path.name):
            suspicious_root.append(file_path)
        if first == ".agent_tmp":
            agent_tmp.append(file_path)
        if first == ".agent_reports":
            agent_reports.append(file_path)
        if first == "docs" or (len(relative_parts) == 1 and matches(PROTECTED_DOC_PATTERNS, file_path.name)):
            protected_docs.append(file_path)

    return AuditResult(
        root=root,
        suspicious_root=sorted(suspicious_root),
        agent_tmp=sorted(agent_tmp),
        agent_reports=sorted(agent_reports),
        protected_docs=sorted(protected_docs),
        report_path=report_path,
    )


def write_report(result: AuditResult, path: Path) -> None:
    lines = [
        "# tidy-skill - Artifact Audit Report",
        "",
        f"**Root:** `{result.root}`",
        f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        "",
        "| Category | Count |",
        "|---|---:|",
        f"| Suspicious root files | {len(result.suspicious_root)} |",
        f"| Temporary artifacts | {len(result.agent_tmp)} |",
        f"| Persistent reports | {len(result.agent_reports)} |",
        f"| Protected docs | {len(result.protected_docs)} |",
        "",
    ]
    sections = [
        ("Suspicious Root Files", result.suspicious_root),
        ("Temporary Artifacts", result.agent_tmp),
        ("Persistent Reports", result.agent_reports),
        ("Protected Docs", result.protected_docs),
    ]
    for title, paths in sections:
        lines.extend([f"## {title}", ""])
        if paths:
            for path_item in paths:
                lines.append(f"- `{rel(path_item, result.root)}`")
        else:
            lines.append("_None found._")
        lines.append("")

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit a repository for agent artifacts.")
    parser.add_argument("--root", default=".", help="Repository root to audit.")
    parser.add_argument("--report-path", help="Optional Markdown report path.")
    parser.add_argument("--max-depth", type=int, default=3, help="Maximum directory depth to scan.")
    parser.add_argument("--json", action="store_true", help="Print JSON output.")
    args = parser.parse_args()

    root = Path(args.root)
    if not root.is_dir():
        parser.error(f"--root is not a directory: {root}")
    if args.max_depth < 0:
        parser.error("--max-depth must be non-negative")

    report_path = Path(args.report_path) if args.report_path else None
    result = audit(root, args.max_depth, report_path)
    if report_path:
        write_report(result, report_path)

    payload = {
        "root": str(result.root),
        "summary": {
            "suspicious_root": len(result.suspicious_root),
            "agent_tmp": len(result.agent_tmp),
            "agent_reports": len(result.agent_reports),
            "protected_docs": len(result.protected_docs),
        },
        "suspicious_root_files": [rel(path, result.root) for path in result.suspicious_root],
        "report_path": str(report_path) if report_path else None,
    }
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print("tidy-skill - Artifact Audit")
        print(f"Scanning: {result.root}")
        print(f"Suspicious root files: {len(result.suspicious_root)}")
        print(f"Temporary artifacts: {len(result.agent_tmp)}")
        print(f"Persistent reports: {len(result.agent_reports)}")
        print(f"Protected docs: {len(result.protected_docs)}")
        if report_path:
            print(f"Report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
