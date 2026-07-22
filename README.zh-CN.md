# 洁癖.skill（Tidy Skill）

**让 AI Agent 少留痕，留下的都有用、可解释、可回收**

[English](README.md) | [中文](README.zh-CN.md)

![CI](https://github.com/Phoenix0531-sudo/tidy-skill/actions/workflows/ci.yml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)

**洁癖.skill** 教编程 Agent 少堆垃圾文件，并让每一份残留产物都「有意、可解释、可回收」。

以 skill 包布局（`skills/`）为主，`tools/` 提供辅助脚本，可离线使用，面向 CC Switch / 多 Agent 卫生。

## 为什么做这个

Agent 容易留下 `tmp_`、调试 dump、半截笔记。本 skill 固化清理策略与检查，让仓库可审阅。

## 功能

- `skills/` 技能文档  
- `tools/` 辅助脚本  
- 核心文本离线可用  
- 打包期望的测试  

## 安装

```bash
git clone https://github.com/Phoenix0531-sudo/tidy-skill.git
cd Tidy_Skill
# 将 skills/ 拷贝或链接到你的 Agent skill 根目录
```

## 使用

让 Agent 的 skill 加载器指向 `skills/`（或 skill 内文档写明的路径）。

```bash
pytest tests/
```

## 目录结构

```
skills/
tools/
tests/
docs/
```

## 许可证

MIT。可在署名前提下商用。见 [LICENSE](LICENSE)。
