#!/usr/bin/env python3
"""Score repository hygiene for agent-generated artifacts.

This script is dependency-free and cross-platform. It mirrors the core scoring
model used by the PowerShell implementation, but avoids shell-specific encoding
and execution-policy issues for routine repo checks.
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

STATE_DIRS = [".codex", ".claude", ".cursor", ".vscode", ".idea"]


@dataclass(frozen=True)
class ScoreResult:
    root: Path
    total: int
    rating: str
    dimensions: dict[str, int]
    suspicious_root_files: list[Path]
    has_agent_tmp: bool
    has_agent_reports: bool
    has_readme: bool
    has_license: bool
    has_changelog: bool
    has_docs: bool
    report_path: Path | None


def is_forbidden_root_file(path: Path) -> bool:
    name = path.name.lower()
    return any(re.match(pattern, name) for pattern in FORBIDDEN_ROOT_PATTERNS)


def is_layout_marker(path: Path) -> bool:
    return path.name.lower() in {".gitkeep", ".keep"}


def rating_for(score: int) -> str:
    if score >= 90:
        return "Clean"
    if score >= 70:
        return "Mostly clean"
    if score >= 50:
        return "Needs tidy-up"
    return "Artifact landfill"


DEFAULT_WEIGHTS = {
    "Root cleanliness": 1.0,
    "Artifact placement": 1.0,
    "Protected docs clarity": 1.0,
    "Git hygiene": 1.0,
    "Agent state isolation": 1.0,
    "Cleanup readiness": 1.0,
}


def score_repo(
    root: Path,
    report_path: Path | None,
    weights: dict[str, float] | None = None,
) -> ScoreResult:
    root = root.resolve()
    root_files = [path for path in root.iterdir() if path.is_file()]
    suspicious_root_files = [path for path in root_files if is_forbidden_root_file(path)]

    suspicious_count = len(suspicious_root_files)
    if suspicious_count == 0:
        score_root = 25
    elif suspicious_count <= 2:
        score_root = 18
    elif suspicious_count <= 5:
        score_root = 10
    else:
        score_root = 5

    has_agent_tmp = (root / ".agent_tmp").is_dir()
    has_agent_reports = (root / ".agent_reports").is_dir()
    score_placement = 0
    if has_agent_tmp:
        score_placement += 8
    if has_agent_reports:
        score_placement += 7
    if suspicious_count == 0:
        score_placement += 5
    elif suspicious_count <= 3:
        score_placement += 2

    has_readme = (root / "README.md").is_file()
    has_license = (root / "LICENSE").is_file()
    has_changelog = (root / "CHANGELOG.md").is_file()
    has_docs = (root / "docs").is_dir()
    score_docs = 0
    if has_readme:
        score_docs += 5
    if has_license:
        score_docs += 4
    if has_changelog:
        score_docs += 3
    if has_docs:
        score_docs += 3

    gitignore = root / ".gitignore"
    score_git = 5
    if gitignore.is_file():
        gitignore_text = gitignore.read_text(encoding="utf-8", errors="ignore")
        score_git += 3
        if ".agent_tmp" in gitignore_text:
            score_git += 4
        if ".agent_reports" in gitignore_text:
            score_git += 3

    state_count = sum(1 for name in STATE_DIRS if (root / name).exists())
    score_isolation = 15
    if (has_docs or has_readme) and state_count > 3:
        score_isolation = 12

    score_cleanup = 0
    if has_agent_tmp:
        score_cleanup += 3
    if has_agent_reports:
        score_cleanup += 3
    if suspicious_count == 0:
        score_cleanup += 2
    if has_agent_tmp or has_agent_reports:
        tmp_files = list((root / ".agent_tmp").glob("*")) if has_agent_tmp else []
        report_files = list((root / ".agent_reports").glob("*")) if has_agent_reports else []
        real_files = [
            path
            for path in tmp_files + report_files
            if path.is_file() and not is_layout_marker(path)
        ]
        # Layout dirs alone (with optional .gitkeep) count as cleanup-ready.
        if real_files or (has_agent_tmp and has_agent_reports):
            score_cleanup += 2

    raw_dimensions = {
        "Root cleanliness": score_root,
        "Artifact placement": score_placement,
        "Protected docs clarity": score_docs,
        "Git hygiene": score_git,
        "Agent state isolation": score_isolation,
        "Cleanup readiness": score_cleanup,
    }
    active_weights = dict(DEFAULT_WEIGHTS)
    if weights:
        for key, value in weights.items():
            if key in active_weights:
                active_weights[key] = float(value)
    weighted = {
        name: int(round(score * active_weights.get(name, 1.0)))
        for name, score in raw_dimensions.items()
    }
    # Renormalize to 0-100 so optional weights stay comparable.
    raw_total = sum(raw_dimensions.values()) or 1
    weighted_total = sum(weighted.values())
    if weights:
        total = max(0, min(100, int(round(weighted_total * 100 / max(raw_total, 1)))))
        # Prefer simple clamp of weighted sum when weights are near 1.0.
        simple = max(0, min(100, weighted_total))
        # Use simple sum when all weights are 1.0-ish scale (max raw is 100).
        if abs(sum(active_weights.values()) - len(active_weights)) < 1e-6:
            total = simple
        else:
            total = simple if weighted_total <= 100 else total
    else:
        total = max(0, min(100, raw_total))
        weighted = raw_dimensions

    return ScoreResult(
        root=root,
        total=total,
        rating=rating_for(total),
        dimensions=weighted,
        suspicious_root_files=suspicious_root_files,
        has_agent_tmp=has_agent_tmp,
        has_agent_reports=has_agent_reports,
        has_readme=has_readme,
        has_license=has_license,
        has_changelog=has_changelog,
        has_docs=has_docs,
        report_path=report_path,
    )


def write_report(result: ScoreResult, path: Path) -> None:
    lines = [
        "# tidy-skill - Repo Hygiene Score",
        "",
        f"**Repository:** `{result.root}`",
        f"**Score:** {result.total} / 100 - **{result.rating}**",
        f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        "",
        "---",
        "",
        "## Dimension Breakdown",
        "",
        "| Dimension | Score | Max |",
        "|---|---:|---:|",
    ]
    max_scores = {
        "Root cleanliness": 25,
        "Artifact placement": 20,
        "Protected docs clarity": 15,
        "Git hygiene": 15,
        "Agent state isolation": 15,
        "Cleanup readiness": 10,
    }
    for name, score in result.dimensions.items():
        lines.append(f"| {name} | {score} | {max_scores[name]} |")

    lines.extend(["", "## Signals", ""])
    lines.append(f"- `.agent_tmp/`: {'yes' if result.has_agent_tmp else 'no'}")
    lines.append(f"- `.agent_reports/`: {'yes' if result.has_agent_reports else 'no'}")
    lines.append(f"- `README.md`: {'yes' if result.has_readme else 'no'}")
    lines.append(f"- `LICENSE`: {'yes' if result.has_license else 'no'}")
    lines.append(f"- `CHANGELOG.md`: {'yes' if result.has_changelog else 'no'}")
    lines.append(f"- `docs/`: {'yes' if result.has_docs else 'no'}")

    if result.suspicious_root_files:
        lines.extend(["", "## Suspicious Root Files", ""])
        for file_path in result.suspicious_root_files:
            lines.append(f"- `{file_path.name}`")

    lines.extend(["", "## Recommendations", ""])
    if result.suspicious_root_files:
        lines.append("- Move or remove suspicious root-level process files.")
    if not result.has_agent_tmp:
        lines.append("- Create `.agent_tmp/` for temporary agent files.")
    if not result.has_agent_reports:
        lines.append("- Create `.agent_reports/` for user-requested reports.")
    if not result.has_changelog:
        lines.append("- Add `CHANGELOG.md` if this repository has releases.")
    if not result.has_docs:
        lines.append("- Add `docs/` only when formal long-lived documentation is needed.")

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def load_weights(path: Path | None) -> dict[str, float] | None:
    if path is None:
        return None
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        raise ValueError("weights file must be a JSON object of dimension -> factor")
    return {str(key): float(value) for key, value in raw.items()}


def main() -> int:
    parser = argparse.ArgumentParser(description="Score repository hygiene.")
    parser.add_argument("--root", default=".", help="Repository root to score.")
    parser.add_argument("--report-path", help="Optional Markdown report path.")
    parser.add_argument(
        "--weights",
        help="Optional JSON file of dimension weight factors (default 1.0 each).",
    )
    parser.add_argument("--json", action="store_true", help="Print JSON instead of text.")
    args = parser.parse_args()

    root = Path(args.root)
    if not root.is_dir():
        parser.error(f"--root is not a directory: {root}")

    report_path = Path(args.report_path) if args.report_path else None
    try:
        weights = load_weights(Path(args.weights) if args.weights else None)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        parser.error(f"invalid --weights file: {exc}")
    result = score_repo(root, report_path, weights=weights)
    if report_path:
        write_report(result, report_path)

    payload = {
        "root": str(result.root),
        "score": result.total,
        "rating": result.rating,
        "dimensions": result.dimensions,
        "suspicious_root_files": [path.name for path in result.suspicious_root_files],
        "report_path": str(report_path) if report_path else None,
    }
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print(f"tidy-skill - Repo Hygiene Score")
        print(f"Scoring: {result.root}")
        print(f"Score: {result.total} / 100 - {result.rating}")
        if report_path:
            print(f"Report: {report_path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
