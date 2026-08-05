from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_DIR = REPO_ROOT / "skills" / "tidy-skill" / "scripts"


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


policy_loader = load_module("policy_loader", SCRIPTS_DIR / "policy_loader.py")
artifact_audit = load_module("audit_agent_artifacts", SCRIPTS_DIR / "audit_agent_artifacts.py")
repo_score = load_module("score_repo_hygiene", SCRIPTS_DIR / "score_repo_hygiene.py")
dev_audit = load_module("audit_dev_environment", SCRIPTS_DIR / "audit_dev_environment.py")
workspace_audit = load_module("audit_workspace_hygiene", SCRIPTS_DIR / "audit_workspace_hygiene.py")
classify_artifact = load_module("classify_artifact", SCRIPTS_DIR / "classify_artifact.py")
hygiene_snapshot = load_module("hygiene_snapshot", SCRIPTS_DIR / "hygiene_snapshot.py")
tidy_doctor = load_module("tidy_doctor", SCRIPTS_DIR / "tidy_doctor.py")


class PythonAuditTests(unittest.TestCase):
    def test_suspicious_root_and_protected_docs_are_classified(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "plan.md").write_text("temporary plan", encoding="utf-8")
            (root / "README.md").write_text("formal docs", encoding="utf-8")
            (root / "SECURITY.md").write_text("security", encoding="utf-8")
            (root / "docs").mkdir()
            (root / "docs" / "guide.md").write_text("guide", encoding="utf-8")

            result = artifact_audit.audit(root, max_depth=2, report_path=None)

            self.assertEqual(["plan.md"], [path.name for path in result.suspicious_root])
            protected = {path.name for path in result.protected_docs}
            self.assertIn("README.md", protected)
            self.assertIn("SECURITY.md", protected)
            self.assertNotIn("plan.md", protected)

    def test_repo_score_reports_suspicious_root_files(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "plan.md").write_text("temporary plan", encoding="utf-8")
            (root / "README.md").write_text("readme", encoding="utf-8")
            (root / "LICENSE").write_text("MIT", encoding="utf-8")
            (root / ".agent_tmp").mkdir()
            (root / ".agent_reports").mkdir()

            result = repo_score.score_repo(root, report_path=None)

            self.assertLess(result.total, 100)
            self.assertEqual(["plan.md"], [path.name for path in result.suspicious_root_files])

    def test_gitkeep_markers_are_ignored_in_artifact_counts(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / ".agent_tmp").mkdir()
            (root / ".agent_reports").mkdir()
            (root / ".agent_tmp" / ".gitkeep").write_text("", encoding="utf-8")
            (root / ".agent_reports" / ".gitkeep").write_text("", encoding="utf-8")
            (root / ".agent_tmp" / "scratch.md").write_text("tmp", encoding="utf-8")

            result = artifact_audit.audit(root, max_depth=2, report_path=None)

            self.assertEqual(["scratch.md"], [path.name for path in result.agent_tmp])
            self.assertEqual([], [path.name for path in result.agent_reports])

    def test_workspace_audit_finds_nested_git_repos(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            repo = root / "demo"
            repo.mkdir()
            (repo / ".git").mkdir()
            (repo / "plan.md").write_text("plan", encoding="utf-8")
            (repo / "README.md").write_text("readme", encoding="utf-8")
            (repo / "scratch.md").write_text("scratch", encoding="utf-8")
            (repo / ".tidy-skill.json").write_text(
                '{"forbidden_root_globs": ["scratch.md"]}',
                encoding="utf-8",
            )

            repos = workspace_audit.find_repos(root, max_depth=2)
            self.assertEqual(1, len(repos))
            scored = workspace_audit.score_one(repos[0])
            self.assertEqual(["plan.md", "scratch.md"], scored.suspicious_files)
            self.assertLess(scored.score, 100)

    def test_dev_environment_report_has_required_action_buckets(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            cache_dir = root / ".venv"
            cache_dir.mkdir()
            (cache_dir / "placeholder.bin").write_bytes(b"x" * 1024)
            report_path = root / "report.md"

            item = dev_audit.CacheItem(
                category="Project cache",
                owner=".venv",
                path=cache_dir,
                size=1024,
                touch="Review project first",
                next_step="Confirm the project can rebuild it, then clean from that project context.",
            )
            payload = dev_audit.build_payload([item], [root])
            dev_audit.write_report(payload, report_path)
            text = report_path.read_text(encoding="utf-8")

            self.assertIn("## Overview Cards", text)
            self.assertIn("## Top 10 Optimization Plan", text)
            self.assertIn("## Findings", text)
            self.assertIn("## Safe Suggestions", text)
            self.assertIn("## Manual / Risky Operations", text)
            self.assertIn("Can touch?", text)

    def test_policy_loader_extends_forbidden_and_ignore_globs(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            policy_path = root / ".tidy-skill.json"
            policy_path.write_text(
                '{"forbidden_root_globs": ["scratch.md"],'
                ' "ignore_root_globs": ["vendor_plan.md"],'
                ' "min_score": 80, "require_agent_dirs": true}',
                encoding="utf-8",
            )
            (root / "scratch.md").write_text("x", encoding="utf-8")
            (root / "vendor_plan.md").write_text("ok", encoding="utf-8")
            (root / "plan.md").write_text("bad", encoding="utf-8")
            (root / "README.md").write_text("readme", encoding="utf-8")

            policy = policy_loader.discover_policy(root)
            self.assertEqual(80, policy.min_score)
            self.assertTrue(policy.require_agent_dirs)
            self.assertTrue(policy_loader.is_forbidden_name("scratch.md", policy))
            self.assertFalse(policy_loader.is_forbidden_name("vendor_plan.md", policy))

            audit = artifact_audit.audit(root, max_depth=1, report_path=None, policy=policy)
            names = sorted(path.name for path in audit.suspicious_root)
            self.assertEqual(["plan.md", "scratch.md"], names)

    def test_classify_artifact_classes_a_through_e(self) -> None:
        root = Path(".")
        formal = classify_artifact.classify_path(Path("README.md"), root=root)
        self.assertEqual("A", formal.class_id)

        report = classify_artifact.classify_path(Path(".agent_reports/task_2026-08-05.md"), root=root)
        self.assertEqual("B", report.class_id)

        tmp = classify_artifact.classify_path(Path(".agent_tmp/scratch.md"), root=root)
        self.assertEqual("C", tmp.class_id)

        noise = classify_artifact.classify_path(Path("mission_complete.md"), root=root)
        self.assertEqual("D", noise.class_id)
        self.assertFalse(noise.allowed)

        state = classify_artifact.classify_path(Path(".claude/session.json"), root=root)
        self.assertEqual("E", state.class_id)

        root_plan = classify_artifact.classify_path(Path("plan.md"), root=root)
        self.assertIn(root_plan.class_id, {"C", "D"})
        self.assertFalse(root_plan.allowed)

    def test_hygiene_snapshot_save_compare_and_gate(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "README.md").write_text("readme", encoding="utf-8")
            (root / "LICENSE").write_text("MIT", encoding="utf-8")
            (root / ".agent_tmp").mkdir()
            (root / ".agent_reports").mkdir()
            history = root / "history"

            first = hygiene_snapshot.snapshot_payload(root, label="before")
            path1 = hygiene_snapshot.write_snapshot(history, first)
            self.assertTrue(path1.is_file())
            self.assertTrue((history / "latest.json").is_file())

            (root / "plan.md").write_text("plan", encoding="utf-8")
            second = hygiene_snapshot.snapshot_payload(root, label="after")
            # Force a distinct stamp so same-second tests still exercise uniqueness.
            if second["captured_at"] == first["captured_at"]:
                second["captured_at"] = first["captured_at"]  # write_snapshot de-dupes path
            path2 = hygiene_snapshot.write_snapshot(history, second)
            self.assertNotEqual(path1, path2)
            delta = hygiene_snapshot.compare(
                hygiene_snapshot.load_json(path1),
                hygiene_snapshot.load_json(path2),
            )
            self.assertLess(delta["after_score"], delta["before_score"])
            self.assertIn("plan.md", delta["files_added"])

            policy_path = root / "policy.json"
            policy_path.write_text('{"min_score": 100, "require_agent_dirs": true}', encoding="utf-8")
            policy = policy_loader.load_policy(policy_path)
            self.assertEqual(100, policy.min_score)
            dirty_score = repo_score.score_repo(root, report_path=None, policy=policy)
            self.assertLess(dirty_score.total, 100)

    def test_tidy_doctor_reports_skill_and_suspicious_root(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "plan.md").write_text("plan", encoding="utf-8")
            (root / "README.md").write_text("readme", encoding="utf-8")
            skill_dir = REPO_ROOT / "skills" / "tidy-skill"

            report = tidy_doctor.run_doctor(root=root, skill_dir=skill_dir, min_score=95)
            self.assertIsNotNone(report.score)
            self.assertIn("plan.md", report.suspicious_root)
            statuses = {item.name: item.status for item in report.checks}
            self.assertEqual("pass", statuses["skill_package"])
            self.assertEqual("fail", statuses["suspicious_root"])
            self.assertTrue(report.failed)

            payload = tidy_doctor.to_payload(report)
            self.assertTrue(payload["failed"])
            self.assertEqual(str(root.resolve()), payload["root"])


if __name__ == "__main__":
    unittest.main()
