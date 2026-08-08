# Case: guard contract (what tidy_repair refuses to touch)

**Kind:** safety-verb reference case (author-constructed)
**Relevant since:** tidy-skill 1.6.0 (`tidy_repair.py` + safety verbs)

This case documents the **guard** verb — the hard refusal list that `tidy_repair.py`
enforces even when the operator passes `--apply --move-root` (the careful verb).
The guard exists so that "run the repair" can never silently destroy something a
human must approve. Repair is DryRun-first; the guard is the floor below which
even the careful verb will not sink.

## The three safety verbs (recap)

| Verb | Flags | What it does | What it never does |
|---|---|---|---|
| **dryrun** | *(default)* | Prints a plan only | Writes nothing |
| **careful** | `--apply --move-root` | Creates layout dirs; moves *untracked* suspicious root Markdown into `.agent_tmp/` | Touches anything in the guard list |
| **guard** | *(always on)* | Refuses unsafe targets regardless of flags | — |

guard is not an opt-in. It runs on every apply.

## What the guard refuses (concrete cases)

Each case below is backed by a test in `tests/test_python_audits.py` and a
matching PowerShell mirror in `tests/test-policy-ps1.ps1` (`Invoke-TidyRepair`).

### 1. Protected formal docs — never moved

Even if `README.md` somehow matches a forbidden pattern, it is Class A and
protected. The plan emits a `skip` (risk=`manual`) and the file stays in place.

```text
[manual ] skip           README.md   protected formal doc — never move
```

Reproduction: `tidy_repair.py --root . --apply --move-root` on a repo with a
suspicious README never moves it (see
`test_tidy_repair_refuses_to_move_protected_and_git_tracked`).

### 2. Git-tracked process files — never auto-moved

A root `plan.md` that is staged/tracked is skipped, not moved. The detail names
the reason so the operator knows the human step (`untrack or move manually`).

```text
[manual ] skip           plan.md      git-tracked — refuse automatic move; untrack or move manually
```

Rationale: a tracked file is someone's intentional commit candidate. Moving it
on the agent's own initiative would silently create a deleted-tracked-file diff.

### 3. Apply-time recheck — a file that became tracked between plan and apply

The guard re-checks git status **at apply time**, not just at plan time. If
`plan.md` was untracked when the plan was built but `git add`-ed before
`--apply --move-root`, apply must refuse with **exit code 2** and leave the file
in place. This catches the race where a human committed the file while the agent
was reviewing the DryRun plan.

Reproduction: `test_tidy_repair_refuses_became_git_tracked_at_apply_time`.
Exit code 2 = "refused an unsafe apply".

### 4. Destination collision — never overwrite

If `.agent_tmp/plan.md` already exists, apply refuses with **exit code 2**
rather than overwrite. Both files stay byte-identical (root version unchanged,
stale `.agent_tmp/` version unchanged).

Reproduction: `test_tidy_repair_dest_collision_refuses_with_exit_2`.

### 5. Host hook configs — never auto-written

`tidy_repair.py` only *hints* at hook wiring. It prints the
`tidy-install-hooks.py` command for the detected host (Claude/Codex/Cursor/Pi)
as a `hook_hint` action with risk=`manual`. Writing the host config is a separate,
explicit operator step (`tidy-install-hooks.py --write`). The repair never edits
`.claude/settings.json`, `~/.codex/config.toml`, `.cursor/rules/…`, or pi's
agent config on its own.

### 6. VHDX, Docker data, tool state — out of scope

`tidy_repair.py` operates only on the repo root layout and root process
Markdown. It never scans WSL2 VHDXs, Docker volumes, or Class E tool-state
dirs (`.codex/`, `.claude/`, `node_modules/`, `.venv/`, …). Those are reported
by `audit_dev_environment.py` / `audit_workspace_hygiene.py` as read-only
findings and the operator decides.

## Exit codes (what they mean)

| Code | Meaning |
|---|---|
| `0` | Plan printed (DryRun) or applied safely; or careful-apply skipped nothing unsafe. |
| `1` | Usage error (bad `--root`, invalid policy JSON). |
| `2` | **Refused** an unsafe apply (dest collision, or a file became git-tracked after planning). No partial mutation is left behind. |

Exit 2 is the guard saying "I stopped rather than do something you did not
authorize." CI treating this as a hard failure is correct; treating it as a
warning is also defensible since nothing was mutated.

## Non-default scope (what the guard does not extend to without custom policy)

Default forbidden patterns are `.md`-anchored. A stray `notes.txt` at the root
is **not** a default repair move candidate (see
`test_tidy_repair_default_only_targets_markdown_process_files`). To let repair
sweep non-Markdown strays, extend `forbidden_globs` in `.tidy-skill.json`; the
guard (protected/git-tracked/collision rechecks) still applies to any added names.

## Commands to reproduce

```bash
# DryRun plan (dryrun verb) — safe, writes nothing:
python skills/tidy-skill/scripts/tidy_repair.py --root . --json

# Careful apply: layout dirs + move untracked suspicious root Markdown:
python skills/tidy-skill/scripts/tidy_repair.py --root . --apply --move-root

# PowerShell mirror (same guard):
Import-Module skills/tidy-skill/scripts/Policy.ps1
Invoke-TidyRepair -Root . -Apply -MoveRoot

# Tests that pin the guard behavior:
python -m unittest tests.test_python_audits.PythonAuditTests.test_tidy_repair_refuses_to_move_protected_and_git_tracked
python -m unittest tests.test_python_audits.PythonAuditTests.test_tidy_repair_dest_collision_refuses_with_exit_2
python -m unittest tests.test_python_audits.PythonAuditTests.test_tidy_repair_refuses_became_git_tracked_at_apply_time
```

## What this case is not

- Not a substitute for the operator reading the DryRun plan. The guard floors
  behavior; the operator still decides whether a careful apply is wanted.
- Not a deletion tool. Repair only *moves* root process Markdown into
  `.agent_tmp/` (Class C). Actual deletion is retention-bound and DryRun-first
  in `clean-agent-artifacts.ps1`.
- Not host-config automation. Hook wiring is always a separate, explicit step.
