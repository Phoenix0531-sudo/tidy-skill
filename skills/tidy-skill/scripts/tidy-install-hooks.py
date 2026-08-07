#!/usr/bin/env python3
"""Print (and optionally write) host hook config snippets for tidy-skill.

This is the executable next step after `tidy_doctor.py` reports an `unwired`
host integration. It emits the JSON config a host needs to wire the read-only
`stop-hygiene-check.py` hook, without auto-modifying any host file.

Safety contract (mirrors tidy-skill defaults):
  - DryRun by default: print the snippet and the intended path only.
  - `-W/--write` is required to actually write the file.
  - Never overwrite an existing host config without `--force`.
  - Never delete, compact, or rewrite unrelated settings.

Exit codes:
  0 = ok (snippet printed, or written)
  1 = usage / runtime error
  2 = refused to overwrite an existing file without --force
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from tidy_doctor import HOST_HOOK_CONFIGS  # noqa: E402

HOOK_MARKER = "stop-hygiene-check"


def snippet_for(host: str, hook_path: str, root_var: str = ".") -> tuple[str, str]:
    """Return (relative_config_path, config_text) for the host.

    hook_path is the path to stop-hygiene-check.py to embed.
    root_var is the `--root` value to pass to the hook; "." by default so the
    hook audits the current working directory of the host session.
    """
    host = host.lower()
    candidates = {
        "claude": (
            ".claude/settings.json",
            json.dumps(
                {
                    "$comment": "EXAMPLE ONLY. Tidy-skill read-only stop hook. Merge into existing settings.",
                    "hooks": {
                        "Stop": [
                            {
                                "type": "command",
                                "command": f'python "{hook_path}" --root "{root_var}"',
                            }
                        ]
                    },
                },
                indent=2,
                ensure_ascii=False,
            ),
        ),
        "codex": (
            ".codex/config.json",
            json.dumps(
                {
                    "$comment": "EXAMPLE ONLY. Tidy-skill read-only stop hook.",
                    "name": "tidy-skill-stop-check",
                    "event": "stop",
                    "command": ["python", hook_path, "--root", root_var],
                },
                indent=2,
                ensure_ascii=False,
            ),
        ),
        "cursor": (
            ".cursor/hooks.json",
            json.dumps(
                {
                    "version": 1,
                    "$comment": "EXAMPLE ONLY. Tidy-skill read-only stop hook.",
                    "hooks": {
                        "stop": [{"command": ["python", hook_path, "--root", root_var]}]
                    },
                },
                indent=2,
                ensure_ascii=False,
            ),
        ),
        "pi": (
            ".pi/config.json",
            json.dumps(
                {
                    "$comment": "EXAMPLE ONLY. Tidy-skill read-only stop hook.",
                    "hooks": {
                        "stop": {"command": f'python "{hook_path}" --root "{root_var}"'}
                    },
                },
                indent=2,
                ensure_ascii=False,
            ),
        ),
    }
    if host not in candidates:
        raise ValueError(f"unsupported host: {host} (try claude|codex|cursor|pi)")
    return candidates[host]


def main() -> int:
    parser = argparse.ArgumentParser(description="Emit host hook config for tidy-skill (DryRun-first).")
    parser.add_argument("--root", default=".", help="Repository root to target.")
    parser.add_argument("--host", required=True, help="Host label: claude|codex|cursor|pi")
    parser.add_argument(
        "--hook-path",
        help="Path to stop-hygiene-check.py to embed. Default: skills/tidy-skill/hooks/stop-hygiene-check.py under --root.",
    )
    parser.add_argument(
        "--root-var",
        default=".",
        help="Value to pass as --root to the hook (default '.'). Use a host var like ${CLAUDE_PROJECT_DIR}.",
    )
    parser.add_argument("-W", "--write", action="store_true", help="Actually write the config file (default: DryRun print only).")
    parser.add_argument("--force", action="store_true", help="Overwrite an existing config file. Dangerous: review diff first.")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    if not root.is_dir():
        parser.error(f"--root is not a directory: {root}")

    hook_path = args.hook_path or "skills/tidy-skill/hooks/stop-hygiene-check.py"
    rel_config, text = snippet_for(args.host, hook_path, args.root_var)
    target = root / rel_config

    if args.write:
        if target.exists() and not args.force:
            print(f"refuse to overwrite existing {target} (use --force after reviewing the diff)", file=sys.stderr)
            return 2
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text + "\n", encoding="utf-8")
        print(f"wrote {target}")
        print(f"Verify it references the hook marker: {HOOK_MARKER}")
    else:
        print(f"# DryRun: would write {target}")
        print(f"# Host: {args.host}")
        print(f"# Review the below snippet before applying. It is read-only (never deletes).")
        print(text)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
