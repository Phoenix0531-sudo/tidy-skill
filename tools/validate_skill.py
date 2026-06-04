#!/usr/bin/env python3
"""Repository validation for the packaged tidy-skill skill."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


REQUIRED_SKILL_FILES = [
    "SKILL.md",
    "agents/openai.yaml",
    "scripts/score_repo_hygiene.py",
    "scripts/audit_agent_artifacts.py",
    "scripts/audit-agent-artifacts.ps1",
    "scripts/audit-dev-environment.ps1",
    "scripts/audit-workspace-hygiene.ps1",
    "scripts/clean-agent-artifacts.ps1",
    "references/script-usage.md",
    "references/wsl2-docker-hygiene.md",
    "references/artifact-classification.md",
    "references/hygiene-scoring-model.md",
    "references/safety-boundaries.md",
    "templates/AGENTS.md",
    "templates/CLAUDE.md",
    "templates/cursor-rule.mdc",
]

REFERENCE_PATTERN = re.compile(r"(?:\[[^\]]+\]\(([^)]+)\)|`([^`]+)`)")


def fail(message: str) -> None:
    print(f"[FAIL] {message}", file=sys.stderr)
    raise SystemExit(1)


def parse_frontmatter(skill_md: Path) -> dict[str, str]:
    text = skill_md.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        fail("SKILL.md must start with YAML frontmatter")
    try:
        _, raw_frontmatter, _ = text.split("---", 2)
    except ValueError:
        fail("SKILL.md frontmatter is not closed")

    values: dict[str, str] = {}
    for line in raw_frontmatter.splitlines():
        line = line.strip()
        if not line:
            continue
        if ":" not in line:
            fail(f"Invalid frontmatter line: {line}")
        key, value = line.split(":", 1)
        values[key.strip()] = value.strip().strip('"')
    return values


def validate_frontmatter(skill_dir: Path) -> None:
    values = parse_frontmatter(skill_dir / "SKILL.md")
    name = values.get("name")
    description = values.get("description")
    if name != skill_dir.name:
        fail(f"frontmatter name must match folder name: {skill_dir.name}")
    if not description:
        fail("frontmatter description is required")
    if len(description) > 1024:
        fail("frontmatter description must be under 1024 characters")
    if not re.fullmatch(r"[a-z0-9-]+", name or ""):
        fail("frontmatter name must use lowercase kebab-case")


def validate_required_files(skill_dir: Path) -> None:
    for relative in REQUIRED_SKILL_FILES:
        if not (skill_dir / relative).exists():
            fail(f"missing required file: {relative}")
    nested_readmes = list(skill_dir.rglob("README.md"))
    if nested_readmes:
        names = ", ".join(str(path.relative_to(skill_dir)) for path in nested_readmes)
        fail(f"README.md should not live inside the skill folder: {names}")


def validate_ascii_scripts(skill_dir: Path) -> None:
    scripts_dir = skill_dir / "scripts"
    for path in list(scripts_dir.glob("*.ps1")) + list(scripts_dir.glob("*.bat")):
        data = path.read_bytes()
        if data.startswith(b"\xef\xbb\xbf"):
            data = data[3:]
        try:
            data.decode("ascii")
        except UnicodeDecodeError:
            fail(f"PowerShell/batch script must be ASCII-safe for Windows parsing: {path}")


def validate_skill_references(skill_dir: Path) -> None:
    skill_text = (skill_dir / "SKILL.md").read_text(encoding="utf-8")
    candidates: set[str] = set()
    for match in REFERENCE_PATTERN.finditer(skill_text):
        target = match.group(1) or match.group(2)
        if not target:
            continue
        if target.startswith(("http://", "https://", "#", "$", ".")):
            continue
        if target.startswith(("references/", "scripts/", "templates/", "examples/")):
            candidates.add(target)

    for target in sorted(candidates):
        if not (skill_dir / target).exists():
            fail(f"SKILL.md references missing file: {target}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate the tidy-skill package.")
    parser.add_argument("--skill-dir", default="skills/tidy-skill")
    args = parser.parse_args()

    skill_dir = Path(args.skill_dir)
    if not skill_dir.is_dir():
        fail(f"skill directory not found: {skill_dir}")

    validate_required_files(skill_dir)
    validate_frontmatter(skill_dir)
    validate_ascii_scripts(skill_dir)
    validate_skill_references(skill_dir)
    print(f"[OK] Validated {skill_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
