# 洁癖.skill / Tidy Skill

**让 AI Agent 在干净、可解释、可回收的本地环境里工作**

[English](README.md) | [中文](README.zh-CN.md)

![CI](https://github.com/Phoenix0531-sudo/tidy-skill/actions/workflows/ci.yml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)

让 AI Agent 少留痕，留下的都有用：技能包、工具脚本与环境洁癖策略。

> 作者：[Phoenix0531-sudo](https://github.com/Phoenix0531-sudo) · 欢迎学习、二次开发与**商业使用**，请保留本仓库署名与许可证声明。

## 技术栈

Markdown skills · Python tools

## 功能特性

- 面向 Agent 的「洁癖」技能与约定
- 可回收、可解释的本地工作区策略
- tools/ 辅助脚本与 skills/ 技能包

## 快速开始

```bash
git clone https://github.com/Phoenix0531-sudo/tidy-skill.git
cd tidy-skill
```

将 `skills/` 下的技能安装/链接到你的 Agent 技能目录（Claude / Codex / Hermes 等），按各 skill 说明启用。

```bash
pip install pytest
pytest -q
```

## 测试

`tests/test_smoke.py` 提供基础 smoke；有更多测试时以 CI 为准。

## CI

push / pull_request 会安装依赖并 **硬失败** 运行 pytest。

## 许可证

[MIT](LICENSE) — 可自由使用、修改、分发与**商用**，需保留版权与许可声明。

## 关于

维护者：[Phoenix0531-sudo](https://github.com/Phoenix0531-sudo)
