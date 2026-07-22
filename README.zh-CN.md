# Tidy Skill

**让 AI Agent 在干净、可解释、可回收的本地环境里工作。**

[English](README.md) | [中文](README.zh-CN.md)

[![CI](https://github.com/Phoenix0531-sudo/tidy-skill/actions/workflows/ci.yml/badge.svg)](https://github.com/Phoenix0531-sudo/tidy-skill/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Python](https://img.shields.io/badge/python-3.10%2B-blue.svg)](https://www.python.org/)

让 AI Agent 在干净、可解释、可回收的本地环境里工作。

围绕 Agent 工作区卫生的 skills + tools。


## 功能

- 🧹 工作区卫生向 skills
- 🧰 tools/ 辅助
- ✅ skill 打包 / 冒烟 CI

## 快速开始

### 安装

```bash
git clone https://github.com/Phoenix0531-sudo/tidy-skill.git
cd tidy-skill
pip install -r requirements.txt  # if present
```

### 使用

浏览 `skills/` 与 `tools/`。按文档安装到你的 Agent skill 中心。

## 项目结构

```
skills/  tools/
tests/  docs/
```

## 说明

面向 Agent 的元工具 — 非普通消费者应用。

## 许可证

MIT。在注明出处的前提下可商业使用（以 LICENSE 为准）。详见 [LICENSE](LICENSE)。
