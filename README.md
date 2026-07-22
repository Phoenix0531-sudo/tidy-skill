# Tidy Skill (洁癖.skill)

**Make AI agent artifacts intentional, explainable, and reclaimable**

[English](README.md) | [中文](README.zh-CN.md)

![CI](https://github.com/Phoenix0531-sudo/tidy-skill/actions/workflows/ci.yml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)

**Tidy Skill** teaches coding agents to leave fewer junk files and to make every leftover artifact intentional.

Layout is skill-pack oriented (`skills/`) with helper tools under `tools/`, offline-friendly, aimed at CC Switch / multi-agent hygiene.

Chinese product name: **洁癖.skill**.

## Why this exists

Agents litter `tmp_`, debug dumps, and half-written notes. This skill codifies cleanup policy and checks so repos stay reviewable.

## Features

- Skill documents under `skills/`
- Helper scripts in `tools/`
- Offline operation (no network required for core skill text)
- CI-friendly tests for packaging expectations

## Install

```bash
git clone https://github.com/Phoenix0531-sudo/tidy-skill.git
cd Tidy_Skill
# copy or link skills/ into your agent skill root (Claude / Codex / Hermes as you use)
```

## Usage

Point your agent skill loader at `skills/` (or the nested tidy skill path documented in the skill README). Run tool checks:

```bash
pytest tests/
```

## Project layout

```
skills/
tools/
tests/
docs/
```

## License

MIT. Free for commercial use with attribution. See [LICENSE](LICENSE).
