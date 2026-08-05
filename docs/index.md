# Tidy Skill Docs

Portfolio and operator notes for **Tidy Skill** (`洁癖.skill`).

## Start here

| Doc | Purpose |
|---|---|
| [../README.md](../README.md) | English product README |
| [../README.zh-CN.md](../README.zh-CN.md) | Chinese product README |
| [../skills/tidy-skill/SKILL.md](../skills/tidy-skill/SKILL.md) | Skill definition (three-layer model, classes A–E) |
| [../skills/tidy-skill/commands/TRIGGERS.md](../skills/tidy-skill/commands/TRIGGERS.md) | Slash / natural-language triggers |
| [../skills/tidy-skill/hooks/HOOKS.md](../skills/tidy-skill/hooks/HOOKS.md) | Read-only stop hook notes |
| [../CHANGELOG.md](../CHANGELOG.md) | Release history |

## Self-audit and evals (author-run)

| Report | Snapshot |
|---|---|
| [self-audit/repo_hygiene_score.md](self-audit/repo_hygiene_score.md) | Repo hygiene score |
| [self-audit/agent_artifacts_audit.md](self-audit/agent_artifacts_audit.md) | Agent artifact audit |
| [self-audit/dev_environment_audit.md](self-audit/dev_environment_audit.md) | Portable dev-environment audit |
| [evals/latest.md](evals/latest.md) | Deterministic fixture evals |

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
```

## License

MIT. See [../LICENSE](../LICENSE).
