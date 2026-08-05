#!/usr/bin/env python3
"""One-shot read-only doctor for tidy-skill installs and repo hygiene.

Exit codes:
  0 = healthy (or warnings only)
  1 = usage/runtime error
  2 = hygiene/policy failures (CI-friendly gate)
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
SKILL_DIR = SCRIPT_DIR.parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import audit_agent_artifacts as audit_mod  # noqa: E402
import score_repo_hygiene as score_mod  # noqa: E402
from policy_loader import discover_policy  # noqa: E402


REQUIRED_RELATIVE = [
    "SKILL.md",
    "scripts/score_repo_hygiene.py",
    "scripts/audit_agent_artifacts.py",
    "scripts/tidy_doctor.py",
    "scripts/classify_artifact.py",
    "scripts/hygiene_snapshot.py",
    "scripts/policy_loader.py",
    "scripts/Policy.ps1",
    "hooks/stop-hygiene-check.py",
    "commands/TRIGGERS.md",
]


@dataclass
class Check:
    name: str
    status: str  # pass | warn | fail
    detail: str


@dataclass
class DoctorReport:
    root: Path
    skill_dir: Path
    generated_at: str
    score: int | None = None
    rating: str | None = None
    checks: list[Check] = field(default_factory=list)
    suspicious_root: list[str] = field(default_factory=list)
    recommendations: list[str] = field(default_factory=list)

    @property
    def failed(self) -> bool:
        return any(item.status == "fail" for item in self.checks)

    @property
    def warnings(self) -> bool:
        return any(item.status == "warn" for item in self.checks)


def check_skill_package(skill_dir: Path) -> list[Check]:
    checks: list[Check] = []
    if not skill_dir.is_dir():
        return [Check("skill_package", "fail", f"skill dir missing: {skill_dir}")]
    missing = [rel for rel in REQUIRED_RELATIVE if not (skill_dir / rel).exists()]
    if missing:
        checks.append(Check("skill_package", "fail", f"missing: {', '.join(missing)}"))
    else:
        checks.append(Check("skill_package", "pass", f"core files present under {skill_dir}"))
    skill_md = skill_dir / "SKILL.md"
    if skill_md.is_file():
        text = skill_md.read_text(encoding="utf-8", errors="ignore")
        if not text.startswith("---"):
            checks.append(Check("skill_frontmatter", "fail", "SKILL.md missing YAML frontmatter"))
        else:
            checks.append(Check("skill_frontmatter", "pass", "frontmatter present"))
    return checks


def run_doctor(
    root: Path,
    skill_dir: Path,
    policy_path: Path | None = None,
    min_score: int | None = None,
    max_depth: int = 3,
) -> DoctorReport:
    generated = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    report = DoctorReport(root=root.resolve(), skill_dir=skill_dir.resolve(), generated_at=generated)
    report.checks.extend(check_skill_package(skill_dir))

    try:
        policy = discover_policy(root, policy_path)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        report.checks.append(Check("policy", "fail", f"invalid policy: {exc}"))
        policy = None
    else:
        src = policy.source or "built-in defaults"
        report.checks.append(Check("policy", "pass", f"using {src}"))

    score = score_mod.score_repo(root, report_path=None)
    report.score = score.total
    report.rating = score.rating
    report.suspicious_root = [path.name for path in score.suspicious_root_files]
    report.checks.append(
        Check(
            "repo_score",
            "pass" if score.total >= 70 else "warn" if score.total >= 50 else "fail",
            f"{score.total}/100 ({score.rating})",
        )
    )

    audit = audit_mod.audit(root, max_depth=max_depth, report_path=None)
    if audit.suspicious_root:
        report.checks.append(
            Check(
                "suspicious_root",
                "fail",
                f"{len(audit.suspicious_root)} file(s): "
                + ", ".join(path.name for path in audit.suspicious_root[:8]),
            )
        )
        report.recommendations.append(
            "Move process Markdown out of root or delete only with explicit user approval (DryRun first)."
        )
    else:
        report.checks.append(Check("suspicious_root", "pass", "0 suspicious root process files"))

    if not score.has_agent_tmp or not score.has_agent_reports:
        missing = []
        if not score.has_agent_tmp:
            missing.append(".agent_tmp/")
        if not score.has_agent_reports:
            missing.append(".agent_reports/")
        status = "fail" if policy and policy.require_agent_dirs else "warn"
        report.checks.append(Check("agent_dirs", status, "missing " + ", ".join(missing)))
        report.recommendations.append("Create layout dirs with .gitkeep so placement is explicit.")
    else:
        report.checks.append(Check("agent_dirs", "pass", ".agent_tmp/ and .agent_reports/ present"))

    gate_min = min_score
    if gate_min is None and policy is not None:
        gate_min = policy.min_score
    if gate_min is not None:
        if score.total >= gate_min:
            report.checks.append(Check("score_gate", "pass", f"score {score.total} >= min {gate_min}"))
        else:
            report.checks.append(Check("score_gate", "fail", f"score {score.total} < min {gate_min}"))

    stop_hook = skill_dir / "hooks" / "stop-hygiene-check.py"
    if stop_hook.is_file():
        report.checks.append(Check("stop_hook", "pass", "stop-hygiene-check.py available (optional wire-up)"))
    else:
        report.checks.append(Check("stop_hook", "warn", "stop hook script missing"))

    if not report.recommendations and not report.failed:
        report.recommendations.append("No blocking hygiene issues. Keep DryRun defaults for cleanup.")
    return report


def to_payload(report: DoctorReport) -> dict:
    return {
        "root": str(report.root),
        "skill_dir": str(report.skill_dir),
        "generated_at": report.generated_at,
        "score": report.score,
        "rating": report.rating,
        "failed": report.failed,
        "warnings": report.warnings,
        "suspicious_root": report.suspicious_root,
        "checks": [{"name": c.name, "status": c.status, "detail": c.detail} for c in report.checks],
        "recommendations": report.recommendations,
    }


def write_markdown(report: DoctorReport, path: Path) -> None:
    lines = [
        "# tidy-skill doctor",
        "",
        f"**Root:** `{report.root}`",
        f"**Skill:** `{report.skill_dir}`",
        f"**Generated:** {report.generated_at}",
        f"**Score:** {report.score} / 100 — {report.rating}",
        "",
        "| Check | Status | Detail |",
        "|---|---|---|",
    ]
    for item in report.checks:
        lines.append(f"| `{item.name}` | {item.status.upper()} | {item.detail} |")
    lines.extend(["", "## Recommendations", ""])
    for rec in report.recommendations:
        lines.append(f"- {rec}")
    lines.append("")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Read-only tidy-skill doctor / CI gate.")
    parser.add_argument("--root", default=".", help="Repository root.")
    parser.add_argument(
        "--skill-dir",
        default=str(SKILL_DIR),
        help="Path to installed or source tidy-skill package.",
    )
    parser.add_argument("--policy", help="Optional policy JSON.")
    parser.add_argument("--min-score", type=int, help="Fail if score below this.")
    parser.add_argument("--max-depth", type=int, default=3)
    parser.add_argument("--report-path", help="Optional Markdown report path.")
    parser.add_argument("--json", action="store_true")
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Treat warnings as failures (exit 2).",
    )
    args = parser.parse_args()

    root = Path(args.root)
    skill_dir = Path(args.skill_dir)
    if not root.is_dir():
        print(f"--root is not a directory: {root}", file=sys.stderr)
        return 1

    report = run_doctor(
        root=root,
        skill_dir=skill_dir,
        policy_path=Path(args.policy) if args.policy else None,
        min_score=args.min_score,
        max_depth=args.max_depth,
    )
    if args.report_path:
        write_markdown(report, Path(args.report_path))

    payload = to_payload(report)
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print("tidy-skill doctor (read-only)")
        print(f"root: {report.root}")
        print(f"score: {report.score}/100 ({report.rating})")
        for item in report.checks:
            print(f"[{item.status.upper():4}] {item.name}: {item.detail}")
        print("recommendations:")
        for rec in report.recommendations:
            print(f"- {rec}")
        if args.report_path:
            print(f"report: {args.report_path}")

    if report.failed or (args.strict and report.warnings):
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
