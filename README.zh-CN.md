# 洁癖.skill

**让 AI Agent 少留痕，留下的都有用**

[English](README.md) | [中文](README.zh-CN.md)

![CI](https://github.com/Phoenix0531-sudo/tidy-skill/actions/workflows/ci.yml/badge.svg)

让 AI Agent 少留痕，留下的都有用。

> 作品集 / 科研 / 工程项目。生产环境使用前请自行评估风险。

## 语言

- English: [README.md](README.md)
- 中文: [README.zh-CN.md](README.zh-CN.md)

## 项目截图

> 界面截图将放在 `docs/screenshots/`，待可用截图就绪后补充。


## 功能特性

- 清晰的项目入口与可复现流程
- 面向真实数据 / 真实任务的实用工具
- 优先本地可运行（如适用）
- 推送与 PR 触发的 CI 自动检查

## 快速开始

```bash
git clone https://github.com/Phoenix0531-sudo/tidy-skill.git
cd tidy-skill
```

随后按本仓库的安装/运行方式启动（Python / Go / Node / Docker 视技术栈而定）。

### 常见 Python 路径

```bash
python -m venv .venv
# Windows: .venv\Scripts\activate
source .venv/bin/activate
pip install -r requirements.txt  # 或: pip install -e .
```

### 常见 Docker 路径（若存在 Dockerfile）

```bash
docker build -t tidy-skill:local .
```

## 仓库结构

```
tidy-skill/
├─ README.md
├─ README.zh-CN.md
├─ .github/workflows/ci.yml
└─ 源码 / 文档 / 测试（因项目而异）
```

## CI

GitHub Actions 会在 `push` / `pull_request` 到 `main` 以及 `main`/`master` 时运行：

- 依赖安装
- 静态检查（尽力）
- 测试（尽力）

## 贡献

欢迎 Issue 与 PR。请保持改动聚焦，并简要说明动机。

## 许可证

若存在 `LICENSE` 文件请以其为准；否则版权归作者所有。

## 关于

维护者：[Phoenix0531-sudo](https://github.com/Phoenix0531-sudo)。
