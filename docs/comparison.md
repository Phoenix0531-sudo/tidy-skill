# How tidy-skill compares

Honest positioning against the skills people most often install next to (or instead of) tidy-skill. Stars and install counts are **not** quality claims — they are market context.

中文版：[comparison.zh-CN.md](comparison.zh-CN.md)

| Project | What it optimizes | Default on-disk behavior | Best when |
|---|---|---|---|
| **tidy-skill** (this repo) | Local environment hygiene: repo litter, workspace caches, machine sprawl | Chat-first; Class A–E placement; DryRun cleanup; score/gate; doctor→repair | Agents litter roots, caches grow, you want a measurable gate |
| [planning-with-files](https://github.com/OthmanAdi/planning-with-files) | Long-task survival across `/clear` and compaction | Writes `task_plan.md` / `findings.md` / `progress.md` (or `.planning/<slug>/`) | Multi-step tasks that must resume after context loss |
| [obra/superpowers](https://github.com/obra/superpowers) | Spec → plan → TDD methodology pack | Skill library across many hosts | You want an opinionated engineering workflow, not hygiene |
| [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) | Define → plan → build → verify → review → ship | 24 lifecycle skills | You want process discipline for production code |
| [anthropics/skills](https://github.com/anthropics/skills) | Agent Skills format / reference | Spec + examples | You are authoring or studying the skill standard |
| [affaan-m/ECC](https://github.com/affaan-m/ECC) | Agent harness OS: skills, hooks, memory, security | Large multi-component install; doctor/repair; session retention knobs | You want a full harness, not just hygiene |
| [garrytan/gstack](https://github.com/garrytan/gstack) | Role slash-commands + safety guards for shipping | `/careful` `/freeze` `/guard`; team auto-update | You want CEO/QA/CSO-style productivity roles |
| [mattpocock/skills](https://github.com/mattpocock/skills) | Small composable engineering skills | Plugin subscribe vs editable skills.sh copy | You want failure-mode skills, not environment governance |

## One-liner

> **planning-with-files** keeps long tasks alive across context loss.  
> **tidy-skill** keeps the machine and repo from drowning in agent litter.  
> Use both: put PWF working memory under `.planning/` (preferred) or opt the root triple in via policy; let tidy score, audit, and gate everything else.

## Philosophy clash (and how to resolve it)

| Axis | planning-with-files | tidy-skill default |
|---|---|---|
| Context model | Filesystem = durable disk | Chat = default; files need intent |
| Root process Markdown | Expected (`task_plan.md`, …) | Forbidden patterns (`*_plan.md`, `progress.md`, …) |
| Parallel work | `.planning/YYYY-MM-DD-slug/` | `.agent_tmp/` / `.agent_reports/` |
| Lifecycle | Gitignored working memory | Score / audit / DryRun / retention |
| Safety | Plan hooks, completion gate | Read-only audits; no auto VHDX/config mutation |

**Resolution (pick one):**

1. **Preferred:** keep PWF under `.planning/` — tidy-skill classifies `.planning/**` as intentional Class C working memory (allowed).
2. **Root triple:** add a project policy that opts the PWF names in:

```json
{
  "version": 1,
  "planning_root_globs": ["task_plan.md", "findings.md", "progress.md"],
  "min_score": 80,
  "require_agent_dirs": true
}
```

Copy from [`skills/tidy-skill/references/tidy-skill.policy.pwf.example.json`](../skills/tidy-skill/references/tidy-skill.policy.pwf.example.json) as `.tidy-skill.json`. Those names stop counting as suspicious root litter and are not cleaned by default sweeps. **Still gitignore them.**

3. **Ignore only** (weaker): `ignore_root_globs` hides names from forbidden matching without labeling them as planning memory.

Without an opt-in, a default PWF root triple still looks dirty to tidy-skill — by design. Hygiene and crash-proof planning are different products; coexistence is explicit, not silent.

## What tidy-skill uniquely owns

1. **Three-layer hygiene** — repository artifacts, multi-repo workspace caches, local machine (WSL2 / Docker / VHDX / package / model caches).
2. **Classes A–E + Artifact Intent Check** — placement law before write.
3. **Measurable CI gate** — `score_repo_hygiene`, `hygiene_snapshot gate`, `tidy_doctor` exit codes.
4. **Doctor → repair loop** — diagnose then DryRun-first safe fixes (`tidy_repair`), without auto host/VHDX mutation.
5. **Project policy shared by Python + PowerShell** — `.tidy-skill.json`.
6. **Offline stdlib Python** — no runtime network dependency for core scripts.
7. **Safety verbs** — dryrun / careful / guard (same meaning in docs and CLIs).

## What peers do better (and what we borrowed)

| Peer surface | Who does it well | What tidy-skill took |
|---|---|---|
| Doctor → repair / uninstall path | ECC | `tidy_repair.py` + uninstall section in installation.md |
| Safety as short verbs | gstack (`/careful` `/guard`) | dryrun · careful · guard product language |
| Failure-mode README, not methodology dump | mattpocock/skills | Four failure modes (root litter / cache sprawl / unsafe cleanup / no CI gate) |
| Subscribe vs editable install | mattpocock, ECC | Dual-path install matrix (skills CLI vs clone/local) |
| Session retention knobs | ECC (`ECC_SESSION_RETENTION_DAYS`) | Documented tmp 7d / reports 30d + clean script flags |
| Broad host mirrors / marketplace | PWF, superpowers, addy | Keep thin; expand only with real install paths |
| Recovery-after-wipe narrative | PWF, superpowers | Keep honest self-audit + fixture evals; no fake benchmarks |
| Side-by-side comparison page | addy | This document |

**Still not copying:** 200+ skill harnesses, Memory Vaults, TDD methodology packs, auto host-config writers, star-count marketing.

## Non-goals

- Do not rebrand tidy-skill as a planning or TDD methodology pack.
- Do not auto-delete intentional PWF plan files.
- Do not claim third-party benchmarks or install ranks we did not measure.
- Do not absorb ECC/gstack role libraries or become a full agent harness.

## Related

- Policy schema example: [`skills/tidy-skill/references/tidy-skill.policy.example.json`](../skills/tidy-skill/references/tidy-skill.policy.example.json)
- PWF coexistence policy: [`skills/tidy-skill/references/tidy-skill.policy.pwf.example.json`](../skills/tidy-skill/references/tidy-skill.policy.pwf.example.json)
- Install matrix: [installation.md](installation.md)
