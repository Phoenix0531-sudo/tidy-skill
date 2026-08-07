#!/usr/bin/env python3
"""Portable multi-repo workspace hygiene audit (read-only).

Companion to audit-workspace-hygiene.ps1. Requires an explicit root that
contains Git repositories. Never defaults to home or drive roots.
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import asdict, dataclass
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from policy_loader import Policy, discover_policy, is_suspicious_root_name  # noqa: E402


@dataclass(frozen=True)
class RepoScore:
    repository: str
    path: str
    score: int
    suspicious_count: int
    suspicious_files: list[str]
    has_agent_tmp: bool
    has_agent_reports: bool
    has_readme: bool
    has_license: bool
    has_docs: bool


def find_repos(root: Path, max_depth: int) -> list[Path]:
    root = root.resolve()
    repos: list[Path] = []
    root_depth = len(root.parts)
    # Include root itself if it is a git repo.
    if (root / ".git").exists():
        repos.append(root)
    for path in root.rglob(".git"):
        if not path.is_dir() and not path.is_file():
            continue
        repo = path.parent
        depth = len(repo.parts) - root_depth
        if 0 < depth <= max_depth and repo not in repos:
            repos.append(repo)
    return sorted(repos, key=lambda item: str(item).lower())


def score_one(repo: Path, policy: Policy | None = None) -> RepoScore:
    active_policy = policy or discover_policy(repo)
    suspicious: list[str] = []
    for file_path in repo.iterdir():
        if file_path.is_file() and is_suspicious_root_name(file_path.name, active_policy):
            suspicious.append(file_path.name)

    has_tmp = (repo / ".agent_tmp").is_dir()
    has_reports = (repo / ".agent_reports").is_dir()
    has_readme = (repo / "README.md").is_file()
    has_license = (repo / "LICENSE").is_file() or any(
        path.name.upper().startswith("LICENSE") for path in repo.iterdir() if path.is_file()
    )
    has_docs = (repo / "docs").is_dir()

    score = 25
    if not suspicious:
        score += 15
    elif len(suspicious) <= 2:
        score += 8
    if has_tmp:
        score += 8
    if has_reports:
        score += 7
    if has_readme:
        score += 5
    if has_license:
        score += 4
    if has_docs:
        score += 3
    if not suspicious:
        score += 2
    score = min(100, score)

    return RepoScore(
        repository=repo.name,
        path=str(repo),
        score=score,
        suspicious_count=len(suspicious),
        suspicious_files=sorted(suspicious),
        has_agent_tmp=has_tmp,
        has_agent_reports=has_reports,
        has_readme=has_readme,
        has_license=has_license,
        has_docs=has_docs,
    )


def write_report(root: Path, results: list[RepoScore], path: Path) -> None:
    average = round(sum(item.score for item in results) / max(1, len(results)), 1)
    clean = sum(1 for item in results if item.score >= 90)
    decent = sum(1 for item in results if 70 <= item.score < 90)
    messy = sum(1 for item in results if 50 <= item.score < 70)
    landfill = sum(1 for item in results if item.score < 50)

    lines = [
        "# tidy-skill - Workspace Hygiene Audit",
        "",
        f"**Workspace root:** `{root}`",
        f"**Repositories found:** {len(results)}",
        f"**Average score:** {average}",
        f"**Scan time:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        "",
        "---",
        "",
        "## Overview",
        "",
        "| Category | Count |",
        "|---|---:|",
        f"| Clean (90-100) | {clean} |",
        f"| Mostly clean (70-89) | {decent} |",
        f"| Needs tidy-up (50-69) | {messy} |",
        f"| Artifact landfill (0-49) | {landfill} |",
        "",
        "## Repository Scores",
        "",
        "| # | Repository | Score | Suspicious | .agent_tmp | .agent_reports | README |",
        "|---:|---|---:|---:|---|---|---|",
    ]
    ranked = sorted(results, key=lambda item: (-item.score, item.repository.lower()))
    for index, item in enumerate(ranked, start=1):
        lines.append(
            f"| {index} | {item.repository} | {item.score} | {item.suspicious_count} | "
            f"{'yes' if item.has_agent_tmp else 'no'} | "
            f"{'yes' if item.has_agent_reports else 'no'} | "
            f"{'yes' if item.has_readme else 'no'} |"
        )

    worst = sorted(results, key=lambda item: (item.score, -item.suspicious_count))[:5]
    if worst:
        lines.extend(["", "## Needs Most Attention", ""])
        for item in worst:
            lines.append(
                f"- **{item.repository}** ({item.score}/100) - {item.suspicious_count} suspicious files"
            )

    frequency: dict[str, int] = {}
    for item in results:
        for name in item.suspicious_files:
            frequency[name] = frequency.get(name, 0) + 1
    if frequency:
        lines.extend(["", "## Most Common Suspicious Filenames", "", "| Filename | Occurrences |", "|---|---:|"])
        for name, count in sorted(frequency.items(), key=lambda pair: (-pair[1], pair[0])):
            lines.append(f"| `{name}` | {count} |")

    if results:
        tmp_pct = round(100 * sum(1 for item in results if item.has_agent_tmp) / len(results), 1)
        reports_pct = round(100 * sum(1 for item in results if item.has_agent_reports) / len(results), 1)
        readme_pct = round(100 * sum(1 for item in results if item.has_readme) / len(results), 1)
        lines.extend(
            [
                "",
                "## Adoption Stats",
                "",
                "| Practice | Adoption |",
                "|---|---:|",
                f"| Has `.agent_tmp/` | {tmp_pct}% |",
                f"| Has `.agent_reports/` | {reports_pct}% |",
                f"| Has `README.md` | {readme_pct}% |",
            ]
        )

    lines.extend(
        [
            "",
            "---",
            "",
            "*Report generated by tidy-skill. Read-only. No files were modified or uploaded.*",
            "",
        ]
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit multiple Git repos under an explicit root.")
    parser.add_argument("--root", required=True, help="Workspace root containing Git repositories.")
    parser.add_argument("--max-depth", type=int, default=2, help="Max depth below root to search for repos.")
    parser.add_argument(
        "--policy",
        help="Optional shared policy JSON applied to every repo (else per-repo discovery).",
    )
    parser.add_argument("--report-path", help="Optional Markdown report path.")
    parser.add_argument("--json", action="store_true", help="Print JSON summary.")
    args = parser.parse_args()

    root = Path(args.root)
    if not root.is_dir():
        parser.error(f"--root is not a directory: {root}")
    if args.max_depth < 1 or args.max_depth > 5:
        parser.error("--max-depth must be between 1 and 5")

    shared_policy: Policy | None = None
    if args.policy:
        try:
            shared_policy = discover_policy(root, Path(args.policy))
        except (OSError, ValueError, json.JSONDecodeError) as exc:
            parser.error(f"invalid --policy file: {exc}")

    repos = find_repos(root, args.max_depth)
    results = [score_one(repo, policy=shared_policy) for repo in repos]
    report_path = Path(args.report_path) if args.report_path else None
    if report_path:
        write_report(root.resolve(), results, report_path)

    average = round(sum(item.score for item in results) / max(1, len(results)), 1)
    payload = {
        "root": str(root.resolve()),
        "repos_scanned": len(results),
        "average_score": average,
        "repositories": [asdict(item) for item in results],
        "report_path": str(report_path) if report_path else None,
    }
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print("tidy-skill - Workspace Hygiene Audit")
        print(f"Workspace root: {root.resolve()}")
        print(f"Repositories found: {len(results)}")
        print(f"Average score: {average}")
        if report_path:
            print(f"Report: {report_path}")
        if not results:
            print("No Git repositories found under the given root.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
