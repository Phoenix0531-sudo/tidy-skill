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
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from policy_loader import (  # noqa: E402
    Policy,
    discover_policy,
    is_planning_root_name,
    is_protected_name,
    is_suspicious_root_name,
)

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
    planning_working_memory: list[Path]
    report_path: Path | None


def rel(path: Path, root: Path) -> str:
    try:
        return str(path.relative_to(root)).replace("\\", "/")
    except ValueError:
        return str(path)


def is_layout_marker(path: Path) -> bool:
    """Directory placeholders are not agent process artifacts."""
    return path.name.lower() in {".gitkeep", ".keep"}


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


def audit(
    root: Path,
    max_depth: int,
    report_path: Path | None,
    policy: Policy | None = None,
) -> AuditResult:
    root = root.resolve()
    active_policy = policy or Policy()
    files = iter_files(root, max_depth)
    suspicious_root: list[Path] = []
    agent_tmp: list[Path] = []
    agent_reports: list[Path] = []
    protected_docs: list[Path] = []
    planning_working_memory: list[Path] = []

    for file_path in files:
        relative_parts = file_path.relative_to(root).parts
        first = relative_parts[0] if relative_parts else ""
        if len(relative_parts) == 1 and is_suspicious_root_name(file_path.name, active_policy):
            suspicious_root.append(file_path)
        if first == ".agent_tmp" and not is_layout_marker(file_path):
            agent_tmp.append(file_path)
        if first == ".agent_reports" and not is_layout_marker(file_path):
            agent_reports.append(file_path)
        if first == "docs" or (
            len(relative_parts) == 1 and is_protected_name(file_path.name, active_policy)
        ):
            protected_docs.append(file_path)
        # Intentional planning working memory (planning-with-files):
        # everything under .planning/, plus any policy-opted root plan file.
        if first == ".planning":
            planning_working_memory.append(file_path)
        elif len(relative_parts) == 1 and is_planning_root_name(file_path.name, active_policy):
            planning_working_memory.append(file_path)

    return AuditResult(
        root=root,
        suspicious_root=sorted(suspicious_root),
        agent_tmp=sorted(agent_tmp),
        agent_reports=sorted(agent_reports),
        protected_docs=sorted(protected_docs),
        planning_working_memory=sorted(planning_working_memory),
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
        f"| Planning working memory | {len(result.planning_working_memory)} |",
        "",
    ]
    sections = [
        ("Suspicious Root Files", result.suspicious_root),
        ("Temporary Artifacts", result.agent_tmp),
        ("Persistent Reports", result.agent_reports),
        ("Protected Docs", result.protected_docs),
        ("Planning Working Memory", result.planning_working_memory),
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
    parser.add_argument("--policy", help="Optional policy JSON (.tidy-skill.json schema).")
    parser.add_argument("--json", action="store_true", help="Print JSON output.")
    args = parser.parse_args()

    root = Path(args.root)
    if not root.is_dir():
        parser.error(f"--root is not a directory: {root}")
    if args.max_depth < 0:
        parser.error("--max-depth must be non-negative")

    report_path = Path(args.report_path) if args.report_path else None
    try:
        policy = discover_policy(root, Path(args.policy) if args.policy else None)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        parser.error(f"invalid --policy file: {exc}")
    result = audit(root, args.max_depth, report_path, policy=policy)
    if report_path:
        write_report(result, report_path)

    payload = {
        "root": str(result.root),
        "summary": {
            "suspicious_root": len(result.suspicious_root),
            "agent_tmp": len(result.agent_tmp),
            "agent_reports": len(result.agent_reports),
            "protected_docs": len(result.protected_docs),
            "planning_working_memory": len(result.planning_working_memory),
        },
        "suspicious_root_files": [rel(path, result.root) for path in result.suspicious_root],
        "planning_working_memory": [rel(path, result.root) for path in result.planning_working_memory],
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
        print(f"Planning working memory: {len(result.planning_working_memory)}")
        if report_path:
            print(f"Report: {report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
