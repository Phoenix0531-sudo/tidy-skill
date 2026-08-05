# Tidy Skill Docs

Portfolio and operator notes for **Tidy Skill** (`洁癖.skill`).

## Start here

| Doc | Purpose |
|---|---|
| [../README.md](../README.md) | English product README |
| [../README.zh-CN.md](../README.zh-CN.md) | Chinese product README |
| [../skills/tidy-skill/SKILL.md](../skills/tidy-skill/SKILL.md) | Skill definition (three-layer model, classes A–E) |
| [../CHANGELOG.md](../CHANGELOG.md) | Release history |

## Self-audit (author-run)

| Report | Snapshot |
|---|---|
| [self-audit/repo_hygiene_score.md](self-audit/repo_hygiene_score.md) | Repo hygiene score |
| [self-audit/agent_artifacts_audit.md](self-audit/agent_artifacts_audit.md) | Agent artifact audit |
| [self-audit/dev_environment_audit.md](self-audit/dev_environment_audit.md) | Portable dev-environment audit |

These reports are produced by this repository’s own scripts. They are **not** an independent third-party audit.

## Screenshots

| Asset | Use |
|---|---|
| [screenshots/banner.png](screenshots/banner.png) | README banner (three-layer model) |
| [screenshots/banner.svg](screenshots/banner.svg) | Vector source for the banner |
| [screenshots/preview.png](screenshots/preview.png) | Terminal self-audit preview |

## Validate the skill package

```bash
uv run python tools/validate_skill.py --skill-dir skills/tidy-skill
```

## License

MIT. See [../LICENSE](../LICENSE).
