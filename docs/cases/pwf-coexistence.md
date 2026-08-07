# Case: planning-with-files (PWF) coexistence repo

**Kind:** pattern scenario (author-constructed)  
**Relevant since:** tidy-skill 1.5.0 (`planning_root_globs` + `.planning/` recognition)

This case shows how a repository that follows the
[planning-with-files](https://github.com/OthmanAdi/planning-with-files) layout
(`task_plan.md` / `findings.md` / `progress.md` triple, or a `.planning/`
working-memory tree) **coexists** with tidy-skill without being flagged as
root pollution.

## The tension

PWF's core practice is a root-level process-Markdown triple that persists an
agent's plan, findings, and progress across turns. tidy-skill's default policy
treats root process Markdown (`plan.md`, `progress.md`, `*summary.md`, …) as
suspicious root litter, because that is exactly the pattern undisciplined
agents leave behind.

So a naive tidy-skill run on a clean PWF shop marks its intentional, gitignored
working memory as "artifact landfill".

## Resolution (two opt-in routes)

### Route A — `.planning/` working-memory tree (recognized automatically)

Move the triple under a `.planning/<slug>/` tree. tidy-skill 1.5.0+ classifies
everything under `.planning/` as **Class C — Planning working memory** (allowed)
with no policy change. Keep `.planning/` gitignored.

```text
.planning/2026-08-07-feature-x/
├─ task_plan.md
├─ findings.md
└─ progress.md
```

### Route B — root triple opted in via policy

If the PWF shop insists on the root triple, add a `.tidy-skill.json`:

```json
{
  "planning_root_globs": ["task_plan.md", "findings.md", "progress.md"]
}
```

The opt-in exempts those exact names from the forbidden check **and** the
score/audit suspicious-root sweep, and the classifier reports them as Class C
(Planning working memory, allowed). Non-opted names like `plan.md` remain
forbidden.

See `references/tidy-skill.policy.pwf.example.json` for a ready-made policy.

## Before / after (Route B, fixture)

Reproduce with `tools/run_evals.py` case `planning_with_files_coexistence`.

| Run | Root layout | Score | Suspicious root |
|---|---|---:|---|
| Before (no policy) | `task_plan.md` `findings.md` `progress.md` `plan.md` | 45 | flagged as landfill |
| After (`planning_root_globs` opt-in) | same | 45 (only `plan.md`) | `plan.md` still flagged |

The opt-in does **not inflate** the score: PWF files stop counting against
"Root cleanliness", but tidy-skill does not award bonus points for them —
they are merely recognized, not rewarded. A clean PWF shop still needs
`.agent_tmp/`, `.agent_reports/`, LICENSE, CHANGELOG, docs/ to reach 100.

## What this case is not

- Not endorsement of PWF over tidy-skill's preferred "prefer chat" stance.
- Not automatic deletion of PWF plan files (cleanup is retention-bound and
  DryRun-first; `.planning/` files are not swept).
- Not a score boost. Recognition only.

## Commands to reproduce

```bash
# Classify a proposed PWF root file before writing it:
python skills/tidy-skill/scripts/classify_artifact.py task_plan.md --root . --policy .tidy-skill.json

# Audit a PWF repo (shows the planning_working_memory bucket):
python skills/tidy-skill/scripts/audit_agent_artifacts.py --root . --json

# Doctor on a PWF repo:
python skills/tidy-skill/scripts/tidy_doctor.py --root .
```
