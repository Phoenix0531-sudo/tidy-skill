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


artifact_audit = load_module("audit_agent_artifacts", SCRIPTS_DIR / "audit_agent_artifacts.py")
repo_score = load_module("score_repo_hygiene", SCRIPTS_DIR / "score_repo_hygiene.py")
dev_audit = load_module("audit_dev_environment", SCRIPTS_DIR / "audit_dev_environment.py")


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


if __name__ == "__main__":
    unittest.main()
