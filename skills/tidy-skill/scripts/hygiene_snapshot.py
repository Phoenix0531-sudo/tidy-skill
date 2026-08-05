#!/usr/bin/env python3
"""Save and compare repository hygiene score snapshots (read-only scoring).

Stores JSON under .agent_reports/hygiene-history/ by default so score trends
are auditable without mutating source trees.
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

import score_repo_hygiene as score_mod  # noqa: E402
from policy_loader import discover_policy  # noqa: E402


def default_history_dir(root: Path) -> Path:
    return root / ".agent_reports" / "hygiene-history"


def snapshot_payload(root: Path, label: str | None = None) -> dict:
    result = score_mod.score_repo(root, report_path=None)
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    return {
        "captured_at": now,
        "label": label or now,
        "root": str(result.root),
        "score": result.total,
        "rating": result.rating,
        "dimensions": result.dimensions,
        "suspicious_root_files": [path.name for path in result.suspicious_root_files],
        "has_agent_tmp": result.has_agent_tmp,
        "has_agent_reports": result.has_agent_reports,
    }


def write_snapshot(history_dir: Path, payload: dict) -> Path:
    history_dir.mkdir(parents=True, exist_ok=True)
    stamp = payload["captured_at"].replace(":", "").replace("-", "")
    path = history_dir / f"snapshot_{stamp}.json"
    # Same-second captures must not overwrite each other.
    if path.exists():
        index = 2
        while True:
            candidate = history_dir / f"snapshot_{stamp}_{index}.json"
            if not candidate.exists():
                path = candidate
                break
            index += 1
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    latest = history_dir / "latest.json"
    latest.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return path


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def compare(before: dict, after: dict) -> dict:
    dim_delta = {}
    before_dims = before.get("dimensions") or {}
    after_dims = after.get("dimensions") or {}
    keys = sorted(set(before_dims) | set(after_dims))
    for key in keys:
        dim_delta[key] = int(after_dims.get(key, 0)) - int(before_dims.get(key, 0))
    before_files = set(before.get("suspicious_root_files") or [])
    after_files = set(after.get("suspicious_root_files") or [])
    return {
        "before_score": before.get("score"),
        "after_score": after.get("score"),
        "delta": int(after.get("score", 0)) - int(before.get("score", 0)),
        "dimension_delta": dim_delta,
        "files_added": sorted(after_files - before_files),
        "files_removed": sorted(before_files - after_files),
        "before_label": before.get("label"),
        "after_label": after.get("label"),
    }


def list_snapshots(history_dir: Path) -> list[Path]:
    if not history_dir.is_dir():
        return []
    return sorted(history_dir.glob("snapshot_*.json"))


def main() -> int:
    parser = argparse.ArgumentParser(description="Save/compare hygiene score snapshots.")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_save = sub.add_parser("save", help="Capture current score snapshot.")
    p_save.add_argument("--root", default=".")
    p_save.add_argument("--history-dir", help="Override history directory.")
    p_save.add_argument("--label", help="Optional human label.")
    p_save.add_argument("--json", action="store_true")

    p_cmp = sub.add_parser("compare", help="Compare two snapshots or latest vs previous.")
    p_cmp.add_argument("--root", default=".")
    p_cmp.add_argument("--history-dir")
    p_cmp.add_argument("--before", help="Path to before JSON (default: second latest).")
    p_cmp.add_argument("--after", help="Path to after JSON (default: latest).")
    p_cmp.add_argument("--json", action="store_true")

    p_list = sub.add_parser("list", help="List saved snapshots.")
    p_list.add_argument("--root", default=".")
    p_list.add_argument("--history-dir")
    p_list.add_argument("--json", action="store_true")

    p_gate = sub.add_parser("gate", help="Fail if current score is below policy min_score.")
    p_gate.add_argument("--root", default=".")
    p_gate.add_argument("--policy")
    p_gate.add_argument("--min-score", type=int, help="Override policy min_score.")
    p_gate.add_argument("--json", action="store_true")

    args = parser.parse_args()
    root = Path(getattr(args, "root", "."))
    if not root.is_dir():
        parser.error(f"--root is not a directory: {root}")

    history_dir = Path(args.history_dir) if getattr(args, "history_dir", None) else default_history_dir(root)

    if args.cmd == "save":
        payload = snapshot_payload(root, label=args.label)
        path = write_snapshot(history_dir, payload)
        if args.json:
            print(json.dumps({"path": str(path), "snapshot": payload}, ensure_ascii=False, indent=2))
        else:
            print(f"Saved snapshot score={payload['score']} -> {path}")
        return 0

    if args.cmd == "list":
        items = list_snapshots(history_dir)
        rows = []
        for item in items:
            data = load_json(item)
            rows.append({"path": str(item), "score": data.get("score"), "label": data.get("label")})
        if args.json:
            print(json.dumps(rows, ensure_ascii=False, indent=2))
        else:
            if not rows:
                print("No snapshots yet.")
            for row in rows:
                print(f"{row['score']:>3}  {row['label']}  {row['path']}")
        return 0

    if args.cmd == "compare":
        items = list_snapshots(history_dir)
        before_path = Path(args.before) if args.before else (items[-2] if len(items) >= 2 else None)
        after_path = Path(args.after) if args.after else (items[-1] if items else None)
        if before_path is None or after_path is None:
            parser.error("Need two snapshots. Run `save` twice or pass --before/--after.")
        delta = compare(load_json(before_path), load_json(after_path))
        if args.json:
            print(json.dumps(delta, ensure_ascii=False, indent=2))
        else:
            print(
                f"Score {delta['before_score']} -> {delta['after_score']} "
                f"(delta {delta['delta']:+d})"
            )
            if delta["files_removed"]:
                print("Removed:", ", ".join(delta["files_removed"]))
            if delta["files_added"]:
                print("Added:", ", ".join(delta["files_added"]))
        return 0

    if args.cmd == "gate":
        try:
            policy = discover_policy(root, Path(args.policy) if args.policy else None)
        except (OSError, ValueError, json.JSONDecodeError) as exc:
            parser.error(f"invalid policy: {exc}")
        min_score = args.min_score if args.min_score is not None else policy.min_score
        if min_score is None:
            min_score = 0
        result = score_mod.score_repo(root, report_path=None)
        ok = result.total >= min_score
        if policy.require_agent_dirs:
            ok = ok and result.has_agent_tmp and result.has_agent_reports
        payload = {
            "score": result.total,
            "min_score": min_score,
            "require_agent_dirs": policy.require_agent_dirs,
            "has_agent_tmp": result.has_agent_tmp,
            "has_agent_reports": result.has_agent_reports,
            "passed": ok,
            "policy_source": policy.source,
        }
        if args.json:
            print(json.dumps(payload, ensure_ascii=False, indent=2))
        else:
            status = "PASS" if ok else "FAIL"
            print(f"gate {status}: score={result.total} min={min_score}")
        return 0 if ok else 2

    parser.error(f"unknown command: {args.cmd}")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
