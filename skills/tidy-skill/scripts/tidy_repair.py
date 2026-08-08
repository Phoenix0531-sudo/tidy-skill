#!/usr/bin/env python3
"""DryRun-first safe repairs suggested by tidy_doctor.

Companion to tidy_doctor.py. Closes the diagnose → actionable next-step loop
without silently mutating host configs or deleting formal docs.

Safety contract (mirrors tidy-skill defaults):
  - DryRun by default: print a plan only.
  - --apply is required to create layout dirs or move root process Markdown.
  - Never rewrites host settings, VHDX, Docker data, or git-tracked files.
  - Root process moves go to .agent_tmp/ only (Class C), never delete.
  - Hook wiring stays a printed command (tidy-install-hooks.py); never auto-write.

Exit codes:
  0 = ok (plan printed or applied)
  1 = usage / runtime error
  2 = refused an unsafe apply (e.g. missing confirmation for root moves)
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import audit_agent_artifacts as audit_mod  # noqa: E402
import score_repo_hygiene as score_mod  # noqa: E402
from policy_loader import Policy, discover_policy, is_protected_name  # noqa: E402
from tidy_doctor import detect_host_hook_integration  # noqa: E402


LAYOUT_DIRS = (".agent_tmp", ".agent_reports")


@dataclass
class PlannedAction:
    kind: str  # create_dir | move_root | hook_hint | retention_note | skip
    path: str
    detail: str
    risk: str  # safe | careful | manual
    applied: bool = False


@dataclass
class RepairPlan:
    root: str
    generated_at: str
    dry_run: bool
    actions: list[PlannedAction] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)

    @property
    def safe_count(self) -> int:
        return sum(1 for a in self.actions if a.risk == "safe")

    @property
    def careful_count(self) -> int:
        return sum(1 for a in self.actions if a.risk == "careful")


def _is_git_tracked(root: Path, rel: str) -> bool:
    git_dir = root / ".git"
    if not git_dir.exists():
        return False
    try:
        import subprocess

        proc = subprocess.run(
            ["git", "-C", str(root), "ls-files", "--error-unmatch", rel],
            capture_output=True,
            text=True,
            check=False,
        )
        return proc.returncode == 0
    except (OSError, FileNotFoundError):
        return False


def plan_layout(root: Path) -> list[PlannedAction]:
    actions: list[PlannedAction] = []
    for name in LAYOUT_DIRS:
        target = root / name
        gitkeep = target / ".gitkeep"
        if target.is_dir() and gitkeep.is_file():
            actions.append(
                PlannedAction(
                    kind="skip",
                    path=f"{name}/",
                    detail="already present with .gitkeep",
                    risk="safe",
                )
            )
            continue
        if target.is_dir():
            if not gitkeep.exists():
                actions.append(
                    PlannedAction(
                        kind="create_dir",
                        path=f"{name}/.gitkeep",
                        detail=f"add .gitkeep under existing {name}/",
                        risk="safe",
                    )
                )
            else:
                actions.append(
                    PlannedAction(
                        kind="skip",
                        path=f"{name}/",
                        detail="already present",
                        risk="safe",
                    )
                )
        else:
            actions.append(
                PlannedAction(
                    kind="create_dir",
                    path=f"{name}/",
                    detail=f"create {name}/ with .gitkeep (explicit placement)",
                    risk="safe",
                )
            )
    return actions


def plan_root_moves(root: Path, policy: Policy) -> list[PlannedAction]:
    actions: list[PlannedAction] = []
    audit = audit_mod.audit(root, max_depth=1, report_path=None)
    for path in audit.suspicious_root:
        name = path.name
        if is_protected_name(name, policy):
            actions.append(
                PlannedAction(
                    kind="skip",
                    path=name,
                    detail="protected formal doc — never move",
                    risk="manual",
                )
            )
            continue
        rel = name
        if _is_git_tracked(root, rel):
            actions.append(
                PlannedAction(
                    kind="skip",
                    path=name,
                    detail="git-tracked — refuse automatic move; untrack or move manually",
                    risk="manual",
                )
            )
            continue
        dest = f".agent_tmp/{name}"
        actions.append(
            PlannedAction(
                kind="move_root",
                path=name,
                detail=f"move root process Markdown → {dest} (Class C)",
                risk="careful",
            )
        )
    return actions


def plan_hook_hint(root: Path) -> list[PlannedAction]:
    host_label, config_path, verdict = detect_host_hook_integration(root)
    if verdict == "wired":
        return [
            PlannedAction(
                kind="skip",
                path=config_path or "",
                detail=f"{host_label} stop hook already wired",
                risk="safe",
            )
        ]
    if verdict == "unwired":
        host_key = {
            "Claude Code": "claude",
            "Codex": "codex",
            "Cursor": "cursor",
            "Pi": "pi",
        }.get(host_label or "", "claude")
        return [
            PlannedAction(
                kind="hook_hint",
                path=config_path or "",
                detail=(
                    f"{host_label} config present but unwired. DryRun emitter: "
                    f"python skills/tidy-skill/scripts/tidy-install-hooks.py "
                    f"--root . --host {host_key}"
                ),
                risk="manual",
            )
        ]
    return [
        PlannedAction(
            kind="hook_hint",
            path="",
            detail=(
                "No host hook config detected. Optional: "
                "python skills/tidy-skill/scripts/tidy-install-hooks.py --root . --host claude"
            ),
            risk="manual",
        )
    ]


def plan_retention_note(root: Path, tmp_days: int, report_days: int) -> list[PlannedAction]:
    notes: list[PlannedAction] = []
    now = datetime.now().astimezone()
    for dirname, days, label in (
        (".agent_tmp", tmp_days, "tmp"),
        (".agent_reports", report_days, "report"),
    ):
        folder = root / dirname
        if not folder.is_dir():
            continue
        eligible = 0
        for item in folder.iterdir():
            if not item.is_file() or item.name == ".gitkeep":
                continue
            try:
                mtime = datetime.fromtimestamp(item.stat().st_mtime).astimezone()
            except OSError:
                continue
            age = (now - mtime).days
            if age >= days:
                eligible += 1
        if eligible:
            notes.append(
                PlannedAction(
                    kind="retention_note",
                    path=f"{dirname}/",
                    detail=(
                        f"{eligible} file(s) older than {days}d — preview with "
                        f"clean-agent-artifacts.ps1 -Root . -DryRun "
                        f"(TmpRetentionDays={tmp_days}, ReportRetentionDays={report_days})"
                    ),
                    risk="careful",
                )
            )
    return notes


def build_plan(
    root: Path,
    policy: Policy,
    *,
    tmp_days: int = 7,
    report_days: int = 30,
    include_root_moves: bool = True,
) -> RepairPlan:
    generated = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    plan = RepairPlan(root=str(root.resolve()), generated_at=generated, dry_run=True)
    plan.actions.extend(plan_layout(root))
    if include_root_moves:
        plan.actions.extend(plan_root_moves(root, policy))
    plan.actions.extend(plan_hook_hint(root))
    plan.actions.extend(plan_retention_note(root, tmp_days, report_days))

    # Score context note
    score = score_mod.score_repo(root, report_path=None)
    plan.notes.append(f"Current score: {score.total}/100 ({score.rating})")
    plan.notes.append(
        "Verbs: dryrun (default preview) · careful (root moves need --apply --move-root) · "
        "guard (never auto host/VHDX/config)."
    )
    return plan


def apply_plan(root: Path, plan: RepairPlan, *, move_root: bool) -> int:
    """Apply safe + optionally careful actions. Returns 0 or 2."""
    for action in plan.actions:
        if action.kind == "create_dir":
            # path is either "name/" or "name/.gitkeep"
            rel = action.path.rstrip("/")
            if rel.endswith(".gitkeep"):
                target_dir = root / Path(rel).parent
                gitkeep = root / rel
            else:
                target_dir = root / rel
                gitkeep = target_dir / ".gitkeep"
            target_dir.mkdir(parents=True, exist_ok=True)
            if not gitkeep.exists():
                gitkeep.write_text("", encoding="utf-8")
            action.applied = True
        elif action.kind == "move_root":
            if not move_root:
                continue
            src = root / action.path
            dest_dir = root / ".agent_tmp"
            dest_dir.mkdir(parents=True, exist_ok=True)
            dest = dest_dir / action.path
            if not src.is_file():
                action.detail += " (source missing at apply time)"
                continue
            if dest.exists():
                action.detail += f" (refused: {dest.name} already exists under .agent_tmp/)"
                return 2
            if _is_git_tracked(root, action.path):
                action.detail += " (refused: became git-tracked)"
                return 2
            shutil.move(str(src), str(dest))
            action.applied = True
        # hook_hint / retention_note / skip: never applied as filesystem ops
    plan.dry_run = False
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="DryRun-first safe repairs for tidy-skill (doctor companion)."
    )
    parser.add_argument("--root", default=".", help="Repository root.")
    parser.add_argument("--policy", help="Optional policy JSON path.")
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Apply safe fixes (create layout dirs). Default is DryRun plan only.",
    )
    parser.add_argument(
        "--move-root",
        action="store_true",
        help="With --apply, also move untracked suspicious root Markdown into .agent_tmp/.",
    )
    parser.add_argument("--tmp-days", type=int, default=7, help="Retention window for .agent_tmp note.")
    parser.add_argument(
        "--report-days", type=int, default=30, help="Retention window for .agent_reports note."
    )
    parser.add_argument("--json", action="store_true", help="Print JSON plan.")
    parser.add_argument(
        "--no-root-moves",
        action="store_true",
        help="Omit root-move proposals from the plan (layout + hook + retention only).",
    )
    args = parser.parse_args()

    root = Path(args.root).resolve()
    if not root.is_dir():
        parser.error(f"--root is not a directory: {root}")

    try:
        policy = discover_policy(root, Path(args.policy) if args.policy else None)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        parser.error(f"invalid policy: {exc}")

    plan = build_plan(
        root,
        policy,
        tmp_days=args.tmp_days,
        report_days=args.report_days,
        include_root_moves=not args.no_root_moves,
    )

    exit_code = 0
    if args.apply:
        if args.move_root and any(a.kind == "move_root" for a in plan.actions):
            # careful verb: require both flags
            pass
        elif args.move_root:
            plan.notes.append("--move-root set but no eligible root moves.")
        exit_code = apply_plan(root, plan, move_root=bool(args.move_root))
        if args.move_root is False and any(a.kind == "move_root" for a in plan.actions):
            plan.notes.append(
                "Root moves planned but not applied (careful). Re-run with --apply --move-root."
            )
    else:
        plan.notes.append("DryRun only. Re-run with --apply for safe layout creates.")
        if any(a.kind == "move_root" for a in plan.actions):
            plan.notes.append("Root moves need --apply --move-root (careful verb).")

    payload = {
        "root": plan.root,
        "generated_at": plan.generated_at,
        "dry_run": plan.dry_run,
        "safe_count": plan.safe_count,
        "careful_count": plan.careful_count,
        "actions": [asdict(a) for a in plan.actions],
        "notes": plan.notes,
        "verbs": {
            "dryrun": "default preview; no writes",
            "careful": "root process moves require --apply --move-root",
            "guard": "never auto-write host configs, VHDX, Docker, or git-tracked files",
        },
    }

    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        mode = "APPLY" if args.apply else "DRY RUN"
        print(f"tidy-skill repair ({mode})")
        print(f"root: {plan.root}")
        for action in plan.actions:
            mark = "done" if action.applied else action.risk
            print(f"[{mark:7}] {action.kind:14} {action.path or '-':28} {action.detail}")
        print("notes:")
        for note in plan.notes:
            print(f"- {note}")
        print("verbs: dryrun · careful · guard")

    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
