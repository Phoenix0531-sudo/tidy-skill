# Tidy Skill Docs

Portfolio and operator notes for **Tidy Skill** (`洁癖.skill`).

## Start here

| Doc | Purpose |
|---|---|
| [../README.md](../README.md) | English product README |
| [../README.zh-CN.md](../README.zh-CN.md) | Chinese product README |
| [branding.md](branding.md) | Logo, asset usage, and concept history |
| [installation.md](installation.md) | Install matrix, doctor→repair, retention, uninstall |
| [comparison.md](comparison.md) | Peer positioning + PWF coexistence + learn-from table |
| [skills-cli-verify.md](skills-cli-verify.md) | Author-run `npx skills add` verification |
| [../skills/tidy-skill/SKILL.md](../skills/tidy-skill/SKILL.md) | Skill definition (three-layer model, classes A–E) |
| [../skills/tidy-skill/commands/TRIGGERS.md](../skills/tidy-skill/commands/TRIGGERS.md) | Slash / natural-language triggers |
| [../skills/tidy-skill/hooks/HOOKS.md](../skills/tidy-skill/hooks/HOOKS.md) | Read-only stop hook notes |
| [../skills/tidy-skill/references/tidy-skill.policy.example.json](../skills/tidy-skill/references/tidy-skill.policy.example.json) | Optional project policy schema |
| [../skills/tidy-skill/references/tidy-skill.policy.pwf.example.json](../skills/tidy-skill/references/tidy-skill.policy.pwf.example.json) | Policy for coexisting with planning-with-files |
| [../CHANGELOG.md](../CHANGELOG.md) | Release history |

## Platforms

| Platform | Guide |
|---|---|
| Claude Code | [platforms/claude.md](platforms/claude.md) |
| Codex | [platforms/codex.md](platforms/codex.md) |
| Cursor | [platforms/cursor.md](platforms/cursor.md) |
| Pi | [platforms/pi.md](platforms/pi.md) |
| OpenCode | [platforms/opencode.md](platforms/opencode.md) |

Optional host wiring samples: [host-samples/](host-samples/).

## Self-audit, evals, cases (author-run)

| Report | Snapshot |
|---|---|
| [self-audit/repo_hygiene_score.md](self-audit/repo_hygiene_score.md) | Repo hygiene score |
| [self-audit/agent_artifacts_audit.md](self-audit/agent_artifacts_audit.md) | Agent artifact audit |
| [self-audit/dev_environment_audit.md](self-audit/dev_environment_audit.md) | Portable dev-environment audit |
| [self-audit/tidy_doctor.md](self-audit/tidy_doctor.md) | One-shot doctor (v1.11.0) |
| [evals/latest.md](evals/latest.md) | Deterministic fixture evals |
| [cases/](cases/) | Before/after case studies |

These reports are produced by this repository’s own scripts. They are **not** an independent third-party audit.

## Screenshots

| Asset | Use |
|---|---|
| [screenshots/banner.png](screenshots/banner.png) | README banner (three-layer model) |
| [screenshots/banner.svg](screenshots/banner.svg) | Vector source for the banner |
| [screenshots/preview.png](screenshots/preview.png) | Terminal self-audit preview |

## Validate / eval

```bash
uv run python tools/validate_skill.py --skill-dir skills/tidy-skill
uv run python tools/run_evals.py
uv run pytest tests/
uv run python skills/tidy-skill/scripts/tidy_doctor.py --root . --json
uv run python skills/tidy-skill/scripts/tidy_repair.py --root .
```

## License

MIT. See [../LICENSE](../LICENSE).
