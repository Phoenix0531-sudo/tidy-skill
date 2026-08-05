#!/usr/bin/env python3
"""Reproducible fixture evals for tidy-skill scoring/audit scripts.

Author-run, deterministic fixtures. Not an independent third-party benchmark.
"""

from __future__ import annotations

import importlib.util
import json
import sys
import tempfile
import traceback
from dataclasses import dataclass
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = REPO_ROOT / "skills" / "tidy-skill" / "scripts"


def load(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


score_mod = load("score_repo_hygiene_eval", SCRIPTS / "score_repo_hygiene.py")
audit_mod = load("audit_agent_artifacts_eval", SCRIPTS / "audit_agent_artifacts.py")
workspace_mod = load("audit_workspace_hygiene_eval", SCRIPTS / "audit_workspace_hygiene.py")


@dataclass
class CaseResult:
    name: str
    passed: bool
    detail: str


def build_dirty_repo(root: Path) -> None:
    (root / "plan.md").write_text("agent plan", encoding="utf-8")
    (root / "todo.md").write_text("agent todo", encoding="utf-8")
    (root / "README.md").write_text("readme", encoding="utf-8")


def build_clean_repo(root: Path) -> None:
    (root / "README.md").write_text("readme", encoding="utf-8")
    (root / "LICENSE").write_text("MIT", encoding="utf-8")
    (root / "CHANGELOG.md").write_text("# Changelog\n", encoding="utf-8")
    (root / "docs").mkdir()
    (root / "docs" / "guide.md").write_text("guide", encoding="utf-8")
    (root / ".gitignore").write_text(".agent_tmp/\n.agent_reports/\n", encoding="utf-8")
    (root / ".agent_tmp").mkdir()
    (root / ".agent_reports").mkdir()
    (root / ".agent_tmp" / ".gitkeep").write_text("", encoding="utf-8")
    (root / ".agent_reports" / ".gitkeep").write_text("", encoding="utf-8")


def case_dirty_score() -> CaseResult:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        build_dirty_repo(root)
        result = score_mod.score_repo(root, None)
        ok = result.total < 80 and {p.name for p in result.suspicious_root_files} >= {"plan.md", "todo.md"}
        return CaseResult("dirty_repo_score_below_80", ok, f"score={result.total} files={[p.name for p in result.suspicious_root_files]}")


def case_clean_score() -> CaseResult:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        build_clean_repo(root)
        result = score_mod.score_repo(root, None)
        ok = result.total >= 90 and not result.suspicious_root_files
        return CaseResult("clean_repo_score_at_least_90", ok, f"score={result.total}")


def case_gitkeep_ignored() -> CaseResult:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        build_clean_repo(root)
        result = audit_mod.audit(root, max_depth=2, report_path=None)
        ok = len(result.agent_tmp) == 0 and len(result.agent_reports) == 0
        return CaseResult(
            "gitkeep_not_counted_as_artifact",
            ok,
            f"tmp={len(result.agent_tmp)} reports={len(result.agent_reports)}",
        )


def case_workspace_average() -> CaseResult:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        dirty = root / "dirty"
        clean = root / "clean"
        dirty.mkdir()
        clean.mkdir()
        (dirty / ".git").mkdir()
        (clean / ".git").mkdir()
        build_dirty_repo(dirty)
        build_clean_repo(clean)
        repos = workspace_mod.find_repos(root, max_depth=2)
        results = [workspace_mod.score_one(repo) for repo in repos]
        average = sum(item.score for item in results) / max(1, len(results))
        ok = len(results) == 2 and average < 95
        return CaseResult("workspace_two_repos_scored", ok, f"n={len(results)} average={average:.1f}")


def main() -> int:
    cases = [
        case_dirty_score,
        case_clean_score,
        case_gitkeep_ignored,
        case_workspace_average,
    ]
    results: list[CaseResult] = []
    for case in cases:
        try:
            results.append(case())
        except Exception as exc:  # noqa: BLE001 - eval harness must continue
            results.append(CaseResult(case.__name__, False, f"error: {exc}\n{traceback.format_exc()}"))

    passed = sum(1 for item in results if item.passed)
    total = len(results)
    lines = [
        "# tidy-skill fixture evals",
        "",
        f"**Passed:** {passed}/{total}",
        "",
        "> Author-run deterministic fixtures. Not an independent third-party benchmark.",
        "",
        "| Case | Result | Detail |",
        "|---|---|---|",
    ]
    for item in results:
        lines.append(f"| `{item.name}` | {'PASS' if item.passed else 'FAIL'} | {item.detail} |")
    lines.append("")

    out_dir = REPO_ROOT / "docs" / "evals"
    out_dir.mkdir(parents=True, exist_ok=True)
    report = out_dir / "latest.md"
    report.write_text("\n".join(lines), encoding="utf-8")

    payload = {
        "passed": passed,
        "total": total,
        "cases": [{"name": item.name, "passed": item.passed, "detail": item.detail} for item in results],
        "report_path": str(report.relative_to(REPO_ROOT)).replace("\\", "/"),
    }
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    print(f"Report: {report}")
    return 0 if passed == total else 1


if __name__ == "__main__":
    raise SystemExit(main())
