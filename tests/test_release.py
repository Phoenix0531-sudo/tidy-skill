from __future__ import annotations

import importlib.util
import subprocess
import sys
import unittest
from datetime import date
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
RELEASE_PATH = REPO_ROOT / "tools" / "release.py"


def load_release_module():
    spec = importlib.util.spec_from_file_location("release_tool", RELEASE_PATH)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


release = load_release_module()


class ReleaseToolTests(unittest.TestCase):
    def test_next_version(self) -> None:
        self.assertEqual(release.next_version("1.7.1", "patch"), "1.7.2")
        self.assertEqual(release.next_version("1.7.1", "minor"), "1.8.0")
        self.assertEqual(release.next_version("1.7.1", "major"), "2.0.0")

    def test_prepare_changelog_moves_unreleased_notes(self) -> None:
        source = "# Changelog\n\n## [Unreleased]\n\n### Added\n- Release helper.\n\n## [1.7.1] - 2026-08-08\n"
        updated = release.prepare_changelog(source, "1.7.2")
        expected_header = f"## [1.7.2] - {date.today().isoformat()}"
        self.assertIn("## [Unreleased]\n\n_Nothing yet._", updated)
        self.assertIn(expected_header, updated)
        self.assertIn("### Added\n- Release helper.", updated)
        self.assertLess(updated.index("## [Unreleased]"), updated.index(expected_header))
        self.assertLess(updated.index(expected_header), updated.index("## [1.7.1]"))

    def test_prepare_changelog_rejects_empty_unreleased(self) -> None:
        source = "# Changelog\n\n## [Unreleased]\n\n_Nothing yet._\n\n## [1.7.1] - 2026-08-08\n"
        with self.assertRaises(SystemExit):
            release.prepare_changelog(source, "1.7.2")

    def test_update_index_replaces_exactly_one_doctor_version(self) -> None:
        source = (
            "| [self-audit/tidy_doctor.md](self-audit/tidy_doctor.md) "
            "| One-shot doctor (v1.7.1) |\n"
        )
        self.assertIn("(v1.8.0)", release.update_index(source, "1.8.0"))

    def test_default_cli_is_read_only(self) -> None:
        """Whatever the tool decides (plan, or reject on empty [Unreleased]),
        it must not touch any release file."""
        paths = [release.PYPROJECT, release.CHANGELOG, release.INDEX, release.DOCTOR]
        before = {path: path.read_bytes() for path in paths}
        result = subprocess.run(
            [sys.executable, str(RELEASE_PATH), "--bump", "patch"],
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        # Exit may be 0 (dry-run preview) or 1 (empty [Unreleased] rejection);
        # either way no release file bytes may change.
        self.assertIn(result.returncode, (0, 1), result.stderr or result.stdout)
        self.assertEqual(before, {path: path.read_bytes() for path in paths})

    def test_cli_guards_require_apply_commit_tag_chain(self) -> None:
        cases = [
            (["--commit"], "--apply"),
            (["--apply", "--tag"], "--commit"),
            (["--apply", "--commit", "--push"], "--tag"),
        ]
        for extra, needle in cases:
            with self.subTest(args=extra):
                result = subprocess.run(
                    [sys.executable, str(RELEASE_PATH), *extra],
                    cwd=REPO_ROOT,
                    capture_output=True,
                    text=True,
                    check=False,
                )
                self.assertEqual(result.returncode, 1, result.stderr or result.stdout)
                self.assertIn(needle, result.stderr)


if __name__ == "__main__":
    unittest.main()
