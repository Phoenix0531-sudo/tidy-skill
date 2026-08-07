#!/usr/bin/env python3
"""Load optional project policy for tidy-skill audits (stdlib only).

Policy file schema (.tidy-skill.json or --policy path):

{
  "version": 1,
  "forbidden_root_globs": ["scratch.md", "tmp_*.md"],
  "forbidden_root_regex": ["^wip_.+\\.md$"],
  "protected_root_globs": ["OWNERS.md"],
  "ignore_root_globs": ["vendor_plan.md"],
  "planning_root_globs": ["task_plan.md", "findings.md", "progress.md"],
  "min_score": 80,
  "require_agent_dirs": true
}

All fields optional. Defaults match built-in skill patterns when omitted.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from fnmatch import fnmatch
from pathlib import Path


DEFAULT_FORBIDDEN_REGEX = [
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

DEFAULT_PROTECTED_REGEX = [
    r"^readme\.md$",
    r"^readme\..+\.md$",
    r"^changelog\.md$",
    r"^license$",
    r"^license\..+$",
    r"^contributing\.md$",
    r"^code_of_conduct\.md$",
    r"^security\.md$",
]


@dataclass
class Policy:
    version: int = 1
    forbidden_regex: list[str] = field(default_factory=lambda: list(DEFAULT_FORBIDDEN_REGEX))
    protected_regex: list[str] = field(default_factory=lambda: list(DEFAULT_PROTECTED_REGEX))
    forbidden_globs: list[str] = field(default_factory=list)
    protected_globs: list[str] = field(default_factory=list)
    ignore_globs: list[str] = field(default_factory=list)
    # Intentional planning-layout root filenames (e.g. planning-with-files).
    # When a name is forbidden *and* listed here, classifiers treat it as
    # recognized working memory instead of root pollution. Use with .gitignore.
    planning_root_globs: list[str] = field(default_factory=list)
    min_score: int | None = None
    require_agent_dirs: bool = False
    source: str | None = None


def _as_str_list(value: object, field_name: str) -> list[str]:
    if value is None:
        return []
    if not isinstance(value, list):
        raise ValueError(f"{field_name} must be a list of strings")
    out: list[str] = []
    for item in value:
        if not isinstance(item, str):
            raise ValueError(f"{field_name} entries must be strings")
        out.append(item)
    return out


def load_policy(path: Path | None) -> Policy:
    if path is None:
        return Policy()
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        raise ValueError("policy must be a JSON object")

    policy = Policy(source=str(path))
    if "version" in raw:
        policy.version = int(raw["version"])

    extra_regex = _as_str_list(raw.get("forbidden_root_regex"), "forbidden_root_regex")
    if extra_regex:
        policy.forbidden_regex = list(DEFAULT_FORBIDDEN_REGEX) + extra_regex
    if "replace_forbidden_root_regex" in raw:
        policy.forbidden_regex = _as_str_list(
            raw.get("replace_forbidden_root_regex"),
            "replace_forbidden_root_regex",
        )

    policy.forbidden_globs = _as_str_list(raw.get("forbidden_root_globs"), "forbidden_root_globs")
    policy.protected_globs = _as_str_list(raw.get("protected_root_globs"), "protected_root_globs")
    policy.ignore_globs = _as_str_list(raw.get("ignore_root_globs"), "ignore_root_globs")
    policy.planning_root_globs = _as_str_list(
        raw.get("planning_root_globs"), "planning_root_globs"
    )

    extra_protected = _as_str_list(raw.get("protected_root_regex"), "protected_root_regex")
    if extra_protected:
        policy.protected_regex = list(DEFAULT_PROTECTED_REGEX) + extra_protected

    if "min_score" in raw and raw["min_score"] is not None:
        policy.min_score = int(raw["min_score"])
    if "require_agent_dirs" in raw:
        policy.require_agent_dirs = bool(raw["require_agent_dirs"])
    return policy


def discover_policy(root: Path, explicit: Path | None = None) -> Policy:
    if explicit is not None:
        return load_policy(explicit)
    for name in (".tidy-skill.json", "tidy-skill.policy.json"):
        candidate = root / name
        if candidate.is_file():
            return load_policy(candidate)
    return Policy()


def is_ignored(name: str, policy: Policy) -> bool:
    lowered = name.lower()
    return any(fnmatch(lowered, pattern.lower()) for pattern in policy.ignore_globs)


def is_forbidden_name(name: str, policy: Policy | None = None) -> bool:
    active = policy or Policy()
    if is_ignored(name, active):
        return False
    lowered = name.lower()
    if any(fnmatch(lowered, pattern.lower()) for pattern in active.forbidden_globs):
        return True
    return any(re.match(pattern, lowered) for pattern in active.forbidden_regex)


def is_planning_root_name(name: str, policy: Policy | None = None) -> bool:
    """True when name is an intentional planning-layout opt-in (e.g. PWF)."""
    active = policy or Policy()
    if not active.planning_root_globs:
        return False
    lowered = name.lower()
    return any(
        lowered == pattern.lower() or fnmatch(lowered, pattern.lower())
        for pattern in active.planning_root_globs
    )


def is_suspicious_root_name(name: str, policy: Policy | None = None) -> bool:
    """Forbidden root process name that is *not* an intentional planning opt-in.

    Use this for scoring, artifact audit, and cleanup decisions. Classification
    still consults is_forbidden_name + is_planning_root_name so opt-in names can
    be labeled as planning working memory rather than silent ignore.
    """
    active = policy or Policy()
    if is_planning_root_name(name, active):
        return False
    return is_forbidden_name(name, active)


def is_protected_name(name: str, policy: Policy | None = None) -> bool:
    active = policy or Policy()
    lowered = name.lower()
    if any(fnmatch(lowered, pattern.lower()) for pattern in active.protected_globs):
        return True
    return any(re.match(pattern, lowered) for pattern in active.protected_regex)
