# Case: tidy-skill repository self-audit

**Kind:** real product repository  
**Root:** this repo (`Phoenix0531-sudo/tidy-skill`)  
**Scripts:** own portable auditors  
**Snapshot:** 2026-08-05 author-run (paths redacted in stored reports)

## Before portfolio hardening (historical)

Early public docs state was effectively:

- Root README pair acted as thin placeholders while the long English body lived in a side file
- No committed self-audit reports under `docs/self-audit/`
- No banner / terminal preview assets
- Missing tracked `.agent_tmp/` / `.agent_reports/` layout markers → hygiene score sat around **77 / 100** on author runs

## After hardening + P0–P2 upgrades

| Report | Result |
|---|---|
| [Repo hygiene score](../self-audit/repo_hygiene_score.md) | **100 / 100 — Clean** |
| [Agent artifact audit](../self-audit/agent_artifacts_audit.md) | **0** suspicious root files |
| [Dev environment audit](../self-audit/dev_environment_audit.md) | **90 / 100 — Highly controlled** |
| [Fixture evals](../evals/latest.md) | **4 / 4 PASS** |

Additional product surface now present:

- Bilingual portfolio README
- `npx skills add Phoenix0531-sudo/tidy-skill --skill tidy-skill` verified discoverable
- Optional host samples under `docs/host-samples/`
- Per-platform install notes under `docs/platforms/`

## What changed operationally

1. Process files stay out of root (rule templates + skill guidance).
2. Layout directories exist with `.gitkeep` and are **not** counted as agent litter.
3. Self-audit reports are redacted and committed as evidence, with methodology footnotes.
4. Cleanup remains DryRun-first; no auto-destructive environment operations.

## Limits

- Self-audit by own scripts, not an independent lab.
- Dev-environment score reflects one Windows author machine.
- Marketplace plugin listings for Claude/Codex are still not claimed.
