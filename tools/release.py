#!/usr/bin/env python3
"""Prepare and optionally publish a tidy-skill release.

The default mode is a read-only preview. Use ``--apply`` to write release
metadata. Git commit, tag, and push operations are separately opt-in.
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PYPROJECT = ROOT / "pyproject.toml"
CHANGELOG = ROOT / "CHANGELOG.md"
INDEX = ROOT / "docs" / "index.md"
DOCTOR = ROOT / "docs" / "self-audit" / "tidy_doctor.md"
VERSION_RE = re.compile(r'^(version\s*=\s*")(?P<version>\d+\.\d+\.\d+)("\s*)$', re.MULTILINE)
SECTION_RE = re.compile(r"^## \[(?P<version>[^]]+)\].*$", re.MULTILINE)
SEMVER_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")


@dataclass(frozen=True)
class ReleasePlan:
    current: str
    target: str
    pyproject: str
    changelog: str
    index: str


def fail(message: str) -> None:
    print(f"[FAIL] {message}", file=sys.stderr)
    raise SystemExit(1)


def run(command: list[str], *, execute: bool) -> None:
    rendered = " ".join(command)
    print(f"[RUN] {rendered}" if execute else f"[DRY-RUN] {rendered}")
    if not execute:
        return
    try:
        subprocess.run(command, cwd=ROOT, check=True)
    except (OSError, subprocess.CalledProcessError) as exc:
        fail(f"command failed: {rendered}: {exc}")


def read_version() -> str:
    text = PYPROJECT.read_text(encoding="utf-8")
    matches = list(VERSION_RE.finditer(text))
    if len(matches) != 1:
        fail("pyproject.toml must contain exactly one simple version assignment")
    return matches[0].group("version")


def next_version(current: str, bump: str) -> str:
    match = SEMVER_RE.fullmatch(current)
    if not match:
        fail(f"unsupported current version: {current}")
    major, minor, patch = map(int, match.groups())
    if bump == "major":
        return f"{major + 1}.0.0"
    if bump == "minor":
        return f"{major}.{minor + 1}.0"
    return f"{major}.{minor}.{patch + 1}"


def replace_version(text: str, current: str, target: str) -> str:
    needle = f'version = "{current}"'
    if text.count(needle) != 1:
        fail(f"expected exactly one pyproject version assignment for {current}")
    return text.replace(needle, f'version = "{target}"', 1)


def prepare_changelog(text: str, target: str) -> str:
    match = re.search(r"^## \[Unreleased\]\r?\n", text, re.MULTILINE)
    if not match:
        fail("CHANGELOG.md is missing an [Unreleased] section")
    body_start = match.end()
    next_section = re.search(r"^## \[", text[body_start:], re.MULTILINE)
    body_end = body_start + (next_section.start() if next_section else len(text[body_start:]))
    body = text[body_start:body_end].strip("\r\n")
    if not body or body == "_Nothing yet._":
        fail("[Unreleased] has no release notes to publish")
    header = f"## [{target}] - {date.today().isoformat()}"
    replacement = f"## [Unreleased]\n\n_Nothing yet._\n\n{header}\n\n{body}\n\n"
    return text[:match.start()] + replacement + text[body_end:]


def update_index(text: str, target: str) -> str:
    pattern = re.compile(r"(self-audit/tidy_doctor\.md\]\(self-audit/tidy_doctor\.md\) \| One-shot doctor \()v\d+\.\d+\.\d+(\) \|)")
    updated, count = pattern.subn(rf"\g<1>v{target}\g<2>", text)
    if count != 1:
        fail("docs/index.md must contain exactly one doctor version label")
    return updated


def build_plan(target: str) -> ReleasePlan:
    current = read_version()
    pyproject = replace_version(PYPROJECT.read_text(encoding="utf-8"), current, target)
    changelog = prepare_changelog(CHANGELOG.read_text(encoding="utf-8"), target)
    index = update_index(INDEX.read_text(encoding="utf-8"), target)
    return ReleasePlan(current=current, target=target, pyproject=pyproject, changelog=changelog, index=index)


def generate_doctor_report() -> str:
    with tempfile.TemporaryDirectory(prefix="tidy-release-") as temp_dir:
        report = Path(temp_dir) / "tidy_doctor.md"
        run(
            [
                sys.executable,
                "skills/tidy-skill/scripts/tidy_doctor.py",
                "--root",
                ".",
                "--report-path",
                str(report),
                "--strict",
            ],
            execute=True,
        )
        if not report.is_file():
            fail("tidy_doctor completed without writing its report")
        return report.read_text(encoding="utf-8")


def write_plan(plan: ReleasePlan, doctor_report: str) -> None:
    PYPROJECT.write_text(plan.pyproject, encoding="utf-8", newline="\n")
    CHANGELOG.write_text(plan.changelog, encoding="utf-8", newline="\n")
    INDEX.write_text(plan.index, encoding="utf-8", newline="\n")
    DOCTOR.write_text(doctor_report, encoding="utf-8", newline="\n")


def git_dirty() -> bool:
    result = subprocess.run(["git", "status", "--porcelain"], cwd=ROOT, capture_output=True, text=True, check=True)
    return bool(result.stdout.strip())


def main() -> int:
    parser = argparse.ArgumentParser(description="Prepare and optionally publish a tidy-skill release.")
    parser.add_argument("--bump", choices=("patch", "minor", "major"), default="patch")
    parser.add_argument("--version", help="explicit target version, instead of --bump")
    parser.add_argument("--apply", action="store_true", help="write release metadata; default is preview only")
    parser.add_argument("--commit", action="store_true", help="commit applied metadata")
    parser.add_argument("--tag", action="store_true", help="create annotated vX.Y.Z tag after commit")
    parser.add_argument("--push", action="store_true", help="push main and tag after commit")
    args = parser.parse_args()

    if (args.commit or args.tag or args.push) and not args.apply:
        fail("--commit, --tag, and --push require --apply")
    if args.tag and not args.commit:
        fail("--tag requires --commit so the tag cannot point to an uncommitted tree")
    if args.push and not args.tag:
        fail("--push requires --tag so the release commit and tag move together")
    if args.apply and git_dirty():
        fail("working tree is dirty; commit or stash existing changes before releasing")

    current = read_version()
    target = args.version or next_version(current, args.bump)
    target_match = SEMVER_RE.fullmatch(target)
    current_match = SEMVER_RE.fullmatch(current)
    if not target_match:
        fail(f"target version must be MAJOR.MINOR.PATCH: {target}")
    if not current_match or tuple(map(int, target_match.groups())) <= tuple(map(int, current_match.groups())):
        fail(f"target version must be greater than current {current}: {target}")
    if SECTION_RE.search(CHANGELOG.read_text(encoding="utf-8"), pos=0) and re.search(
        rf"^## \[{re.escape(target)}\]", CHANGELOG.read_text(encoding="utf-8"), re.MULTILINE
    ):
        fail(f"CHANGELOG.md already contains a {target} section")
    plan = build_plan(target)
    print(f"Version: {plan.current} -> {plan.target}")
    print("Files: pyproject.toml, CHANGELOG.md, docs/index.md, docs/self-audit/tidy_doctor.md")

    if not args.apply:
        print("Dry run only. Re-run with --apply to write files.")
        return 0

    doctor_report = generate_doctor_report()
    write_plan(plan, doctor_report)
    if args.commit:
        run(["git", "add", "pyproject.toml", "CHANGELOG.md", "docs/index.md", "docs/self-audit/tidy_doctor.md"], execute=True)
        run(["git", "commit", "-m", f"release: v{target}"], execute=True)
    if args.tag:
        run(["git", "tag", "-a", f"v{target}", "-m", f"v{target}"], execute=True)
    if args.push:
        run(["git", "push", "origin", "main", f"v{target}"], execute=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
