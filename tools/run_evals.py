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
policy_mod = load("policy_loader_eval", SCRIPTS / "policy_loader.py")
classify_mod = load("classify_artifact_eval", SCRIPTS / "classify_artifact.py")
doctor_mod = load("tidy_doctor_eval", SCRIPTS / "tidy_doctor.py")


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


def case_policy_extends_forbidden() -> CaseResult:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / "scratch.md").write_text("x", encoding="utf-8")
        (root / "vendor_plan.md").write_text("ok", encoding="utf-8")
        (root / ".tidy-skill.json").write_text(
            '{"forbidden_root_globs": ["scratch.md"], "ignore_root_globs": ["vendor_plan.md"]}',
            encoding="utf-8",
        )
        policy = policy_mod.discover_policy(root)
        result = audit_mod.audit(root, max_depth=1, report_path=None, policy=policy)
        names = sorted(path.name for path in result.suspicious_root)
        ok = names == ["scratch.md"] and "vendor_plan.md" not in names
        return CaseResult("policy_extends_forbidden_patterns", ok, f"suspicious={names}")


def case_classify_classes() -> CaseResult:
    root = Path(".")
    a = classify_mod.classify_path(Path("README.md"), root=root).class_id
    d = classify_mod.classify_path(Path("mission_complete.md"), root=root).class_id
    e = classify_mod.classify_path(Path(".claude/state.json"), root=root).class_id
    c = classify_mod.classify_path(Path("plan.md"), root=root).class_id
    pwf_planning = classify_mod.classify_path(
        Path(".planning/2026-08-07-demo/task_plan.md"), root=root
    )
    ok = a == "A" and d == "D" and e == "E" and c == "C" and pwf_planning.class_id == "C"
    return CaseResult(
        "classify_artifact_a_d_e_c",
        ok,
        f"A={a} D={d} E={e} C={c} planning={pwf_planning.class_id}",
    )


def case_pwf_coexistence() -> CaseResult:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / ".tidy-skill.json").write_text(
            '{"planning_root_globs": ["task_plan.md", "findings.md", "progress.md"]}',
            encoding="utf-8",
        )
        for name in ("task_plan.md", "findings.md", "progress.md"):
            (root / name).write_text("working memory", encoding="utf-8")
        (root / "plan.md").write_text("still bad", encoding="utf-8")
        (root / "README.md").write_text("readme", encoding="utf-8")

        policy = policy_mod.discover_policy(root)
        audit = audit_mod.audit(root, max_depth=1, report_path=None, policy=policy)
        scored = score_mod.score_repo(root, report_path=None, policy=policy)
        cls = classify_mod.classify_path(Path("task_plan.md"), root=root, policy=policy)

        suspicious = [p.name for p in audit.suspicious_root]
        ok = (
            suspicious == ["plan.md"]
            and scored.suspicious_root_files
            and [p.name for p in scored.suspicious_root_files] == ["plan.md"]
            and cls.class_id == "C"
            and cls.allowed
            and "Planning" in cls.class_name
        )
        return CaseResult(
            "planning_with_files_coexistence",
            ok,
            f"suspicious={suspicious} score={scored.total} classify={cls.class_id}:{cls.class_name}",
        )


def case_doctor_detects_dirty() -> CaseResult:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        build_dirty_repo(root)
        skill_dir = REPO_ROOT / "skills" / "tidy-skill"
        report = doctor_mod.run_doctor(root=root, skill_dir=skill_dir, min_score=90)
        ok = report.failed and "plan.md" in report.suspicious_root
        return CaseResult(
            "doctor_fails_on_dirty_repo",
            ok,
            f"failed={report.failed} score={report.score} files={report.suspicious_root}",
        )


def main() -> int:
    cases = [
        case_dirty_score,
        case_clean_score,
        case_gitkeep_ignored,
        case_workspace_average,
        case_policy_extends_forbidden,
        case_classify_classes,
        case_pwf_coexistence,
        case_doctor_detects_dirty,
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
