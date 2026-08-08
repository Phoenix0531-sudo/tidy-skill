#!/usr/bin/env python3
"""Classify a path into tidy-skill Classes A–E (read-only, stdlib).

Innovation: agents can ask *before* writing a file whether the proposed path
is formal, deliverable, temporary, noise, or tool state — without deleting
anything.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from policy_loader import (  # noqa: E402
    Policy,
    discover_policy,
    is_forbidden_name,
    is_planning_root_name,
    is_protected_name,
)


STATE_DIR_NAMES = {
    ".codex",
    ".claude",
    ".cursor",
    ".vscode",
    ".idea",
    ".pi",
    ".agents",
    "__pycache__",
    ".pytest_cache",
    ".ruff_cache",
    "node_modules",
    ".venv",
    "venv",
}

NOISE_NAME_PATTERNS = [
    r"^mission_complete",
    r"^task_complete",
    r"^done\.md$",
    r"^finished\.md$",
    r"^success\.md$",
    r"^ai_summary",
    r"^auto_generated",
]


@dataclass
class Classification:
    path: str
    class_id: str
    class_name: str
    placement: str
    allowed: bool
    confidence: str
    reasons: list[str]
    safe_suggestion: str


def classify_path(path: Path, root: Path | None = None, policy: Policy | None = None) -> Classification:
    active = policy or Policy()
    raw = path
    try:
        display = str(path)
        parts = path.parts
        name = path.name
    except Exception:  # noqa: BLE001
        display = str(path)
        parts = Path(str(path)).parts
        name = Path(str(path)).name

    lowered_parts = [p.lower() for p in parts]
    name_l = name.lower()
    reasons: list[str] = []

    # Class E — tool / agent state
    if any(part in STATE_DIR_NAMES for part in lowered_parts):
        return Classification(
            path=display,
            class_id="E",
            class_name="Tool / agent state",
            placement="outside tracked tree or ignored",
            allowed=True,
            confidence="high",
            reasons=["Path includes a known tool/state directory name."],
            safe_suggestion="Keep ignored; do not commit session caches.",
        )

    # Class A — formal docs
    if "docs" in lowered_parts or is_protected_name(name, active):
        return Classification(
            path=display,
            class_id="A",
            class_name="Formal documentation",
            placement="repo root / docs/",
            allowed=True,
            confidence="high",
            reasons=["Matches protected documentation patterns or lives under docs/."],
            safe_suggestion="Edit only when the user explicitly requests documentation changes.",
        )

    # Class B — user deliverables in reports dir
    if ".agent_reports" in lowered_parts:
        return Classification(
            path=display,
            class_id="B",
            class_name="User-requested deliverable",
            placement=".agent_reports/",
            allowed=True,
            confidence="high",
            reasons=["Lives under .agent_reports/."],
            safe_suggestion="Keep dated, task-specific filenames; promote to docs/ only if long-lived.",
        )

    # Class C — temp
    if ".agent_tmp" in lowered_parts:
        return Classification(
            path=display,
            class_id="C",
            class_name="Temporary working artifact",
            placement=".agent_tmp/",
            allowed=True,
            confidence="high",
            reasons=["Lives under .agent_tmp/."],
            safe_suggestion="Delete or expire after the task; never promote to root.",
        )

    # Class C — intentional planning layout (e.g. planning-with-files / PWF)
    # `.planning/` holds gitignored working memory (task_plan / findings /
    # progress). It is not tidy-skill's preferred home but it is a deliberate,
    # recognized layout — allow it so a PWF shop is not falsely flagged as
    # root pollution.
    if ".planning" in lowered_parts:
        return Classification(
            path=display,
            class_id="C",
            class_name="Planning working memory",
            placement=".planning/ (intentional layout)",
            allowed=True,
            confidence="high",
            reasons=[
                "Lives under .planning/ — an intentional, gitignored planning layout.",
                "Recognized as working memory, not root pollution.",
            ],
            safe_suggestion=(
                "Keep .planning/ gitignored; expire slug folders after the task; "
                "promote anything worth keeping into a commit or docs/."
            ),
        )

    # Root-ish process files
    depth = len(parts)
    if root is not None:
        try:
            # Do not require the path to exist yet — agents classify proposed names.
            candidate = raw if raw.is_absolute() else (root / raw)
            try:
                rel = candidate.resolve().relative_to(root.resolve())
            except (OSError, ValueError):
                rel = Path(*parts) if parts else Path(name)
                if len(rel.parts) > 1 or str(raw).replace("\\", "/").count("/") >= 1:
                    rel = Path(str(raw).replace("\\", "/"))
            depth = len(rel.parts)
            display = str(rel).replace("\\", "/")
        except Exception:  # noqa: BLE001
            depth = len(parts)

    if depth == 1 and any(re.match(pat, name_l) for pat in NOISE_NAME_PATTERNS):
        return Classification(
            path=display,
            class_id="D",
            class_name="Self-congratulatory noise",
            placement="do not keep",
            allowed=False,
            confidence="medium",
            reasons=["Name looks like completion fluff or self-congratulatory noise."],
            safe_suggestion="Do not create this file; summarize in chat instead.",
        )

    # Intentional planning layouts (planning-with-files / PWF). Opt-in names may
    # or may not also match the default forbidden list (e.g. findings.md does not).
    if depth == 1 and is_planning_root_name(name, active):
        return Classification(
            path=display,
            class_id="C",
            class_name="Planning working memory",
            placement="repo root (intentional PWF-style triple)",
            allowed=True,
            confidence="high",
            reasons=[
                "Filename matches the project planning_root_globs opt-in.",
                "Working-memory file gitignored by convention, not litter.",
            ],
            safe_suggestion=(
                "Confirm .gitignore excludes this file; review at task end; "
                "promote durable decisions into a commit or docs/."
            ),
        )

    if depth == 1 and is_forbidden_name(name, active):
        return Classification(
            path=display,
            class_id="C",
            class_name="Temporary working artifact (misplaced)",
            placement=".agent_tmp/ (preferred) or chat",
            allowed=False,
            confidence="high",
            reasons=[
                "Filename matches forbidden root process-Markdown patterns.",
                "Root placement is discouraged for process files.",
            ],
            safe_suggestion=f"Prefer chat, or write to `.agent_tmp/{name}` if a file is truly required.",
        )

    if depth == 1 and name_l.endswith(".md"):
        return Classification(
            path=display,
            class_id="B",
            class_name="Possible deliverable / ambiguous root Markdown",
            placement="user-specified path, .agent_reports/, or docs/",
            allowed=False,
            confidence="low",
            reasons=["Root Markdown that is not a known protected formal doc."],
            safe_suggestion="Confirm user intent; avoid generic names; prefer .agent_reports/ or docs/.",
        )

    return Classification(
        path=display,
        class_id="C",
        class_name="Unclassified working file",
        placement="task-appropriate path with explicit lifecycle",
        allowed=True,
        confidence="low",
        reasons=["No strong formal/forbidden signal; treat as working output with a clear owner."],
        safe_suggestion="Run the Artifact Intent Check before creating; set lifetime and reader.",
    )


def _classify_one(path_str: str, root: Path, policy: Policy, *, json_out: bool) -> int:
    """Classify a single path and print the result. Returns 0 (never fails on
    a non-allowed path — the point is to inform the agent, not to block it)."""
    result = classify_path(Path(path_str), root=root, policy=policy)
    payload = asdict(result)
    payload["policy_source"] = policy.source
    if json_out:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        print("tidy-skill - Artifact Classification")
        print(f"Path: {result.path}")
        print(f"Class: {result.class_id} — {result.class_name}")
        print(f"Placement: {result.placement}")
        print(f"Allowed at this path: {'yes' if result.allowed else 'no'}")
        print(f"Confidence: {result.confidence}")
        for reason in result.reasons:
            print(f"- {reason}")
        print(f"Safe suggestion: {result.safe_suggestion}")
    return 0 if result.allowed or result.class_id in {"C", "D"} else 0


def _classify_stdin(root: Path, policy: Policy, *, json_out: bool) -> int:
    """Batch mode: read one path per line from stdin, classify each, and emit
    one NDJSON object per line (or one human report separated by a blank line).
    Blank lines and lines starting with '#' are ignored so callers can paste
    annotated lists. Exit code is 0 unless an input line raises a hard error.

    This lets an agent ask about many candidate paths in a single tool call
    without scripting a loop:
        echo -e 'plan.md\n.agent_tmp/notes.md\ndocs/index.md' | classify_artifact - --json
    """
    exit_code = 0
    first = True
    for raw_line in sys.stdin:
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        try:
            result = classify_path(Path(line), root=root, policy=policy)
            payload = asdict(result)
            payload["policy_source"] = policy.source
        except Exception as exc:  # noqa: BLE001 - never abort the whole batch on one bad line
            payload = {
                "path": line,
                "class_id": "?",
                "class_name": "Classification error",
                "placement": "",
                "allowed": False,
                "confidence": "high",
                "reasons": [str(exc)],
                "safe_suggestion": "Fix or remove this line and rerun.",
            }
            exit_code = 2
        if json_out:
            print(json.dumps(payload, ensure_ascii=False))
        else:
            if not first:
                print()
            first = False
            print(f"Path: {payload['path']}")
            print(f"Class: {payload['class_id']} — {payload['class_name']}")
            print(f"Placement: {payload['placement']}")
            print(f"Allowed at this path: {'yes' if payload['allowed'] else 'no'}")
            print(f"Confidence: {payload['confidence']}")
            for reason in payload.get("reasons", []):
                print(f"- {reason}")
            print(f"Safe suggestion: {payload['safe_suggestion']}")
    return exit_code


def main() -> int:
    parser = argparse.ArgumentParser(description="Classify a path into tidy-skill Classes A–E.")
    parser.add_argument(
        "path",
        nargs="?",
        default=None,
        help=(
            "File or directory path to classify (may not exist yet). "
            "Pass '-' or use '--stdin' to read one path per line from stdin "
            "for batch classification."
        ),
    )
    parser.add_argument(
        "--stdin",
        action="store_true",
        help="Batch mode: read one path per line from stdin and emit NDJSON (with --json).",
    )
    parser.add_argument("--root", default=".", help="Repository root for relative classification.")
    parser.add_argument("--policy", help="Optional policy JSON path.")
    parser.add_argument("--json", action="store_true", help="Print JSON (single) or NDJSON (batch).")
    args = parser.parse_args()

    root = Path(args.root)
    if not root.is_dir():
        parser.error(f"--root is not a directory: {root}")
    try:
        policy = discover_policy(root, Path(args.policy) if args.policy else None)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        parser.error(f"invalid policy: {exc}")

    if args.stdin or args.path == "-":
        return _classify_stdin(root, policy, json_out=args.json)
    if args.path is None:
        parser.error("path is required (or use '--stdin' for batch mode)")
    return _classify_one(args.path, root, policy, json_out=args.json)


if __name__ == "__main__":
    raise SystemExit(main())
