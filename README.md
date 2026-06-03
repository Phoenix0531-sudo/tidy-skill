<h1 align="center">洁癖.skill</h1>

<p align="center">你想协作的下一个 AI Agent，何必自带垃圾生产线？</p>

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="license">
  <img src="https://img.shields.io/badge/Agent_Skills-compatible-blueviolet.svg" alt="agent skills">
  <img src="https://img.shields.io/badge/Standard_Skills-compatible-success.svg" alt="standard skills">
  <img src="https://img.shields.io/badge/skills.sh-runtime-orange.svg" alt="skills.sh runtime">
</p>

---

基于开放的 **Agent Skills** 协议，**洁癖.skill** 可以在任何兼容该规范的 AI Agent 运行环境（如 Claude Code, Cursor, Codex 等）中直接加载。它能在 Agent 运行期间自动约束其文件生成，并在根目录下进行全方位的洁癖审计、评分与安全清理，让你的代码环境始终干净如初。

[English Edition](README.en.md)

---

## 📖 目录
* [🎯 核心特性](#-核心特性)
* [⚡ 效果示例](#-效果示例)
* [📦 安装与配置](#-安装与配置)
* [🛡️ 产物安全边界](#-产物安全边界)
* [🛠️ 脚本说明](#-脚本说明)
* [🗺️ 路线图](#-路线图)
* [📄 开源协议](#-开源协议)

---

## 🎯 核心特性

* 🔍 **产物意图检查 (Artifact Intent Check)**：强制 Agent 在创建任何文件前自审：此文件必须创建吗？为什么回复不够？
* 🚫 **根目录防污染**：自动拦截 `plan.md`、`todo.md` 等无归属的临时 Markdown 文件进入项目根目录。
* 💯 **仓库洁癖评分**：基于六大维度（0–100 分），深度诊断你的仓库文件整洁程度。
* 📂 **工作区批量审计**：一键扫描并生成多个仓库的 Agent 垃圾产物汇总报告。
* 🧹 **保守安全清理**：默认 DryRun 模式预览；仅清理过期的临时文件与报告，绝不触碰你的正式文档。

---

## ⚡ 效果示例

### 1. 洁癖评分与分析
运行 `score-repo-hygiene.ps1` 可以得到直观的评分和建议报告：

```
Tidy Skill — Repo Hygiene Score
Scoring: D:\3_Code_Projects\MyAwesomeProject

Score: 71 / 100 — Mostly clean (基本干净)
Report: D:\3_Code_Projects\MyAwesomeProject\.agent_reports\hygiene_score_2026-06-03_222912.md

Dimension Breakdown:
- Root cleanliness       : 18 / 25  (发现了 plan.md, todo.md)
- Artifact placement     : 15 / 20  (临时文件未集中隔离)
- Protected docs clarity : 12 / 15
- Git hygiene            : 11 / 15
- Agent state isolation  : 15 / 15
- Cleanup readiness      : 0 / 10
```

### 2. 产物意图自审流程 (Artifact Intent Check)
在你的项目里集成 Tidy Skill 后，Agent 在尝试写文件前必须运行以下自审：
```
产物意图检查 / Artifact Intent Check
────────────────────────────────────
1. 用户是否明确要求了文件？       是 / 否
2. 用途：记录多模块重构步骤
3. 读者：本次会话的 Agent
4. 预期生命周期：                 会话级 (Session)
5. 目标路径：                     .agent_tmp/refactor_steps.md
6. 为什么聊天回复不够？           信息量过大，需要作为上下文持续引用
7. 分类：                         Class C (临时工作产物)
8. 应该被 Git 忽略吗？            是 (已在 .gitignore 中)
```
任何一项无法回答，**就不要创建文件。**

---

## 📦 安装与配置

### 1. 作为 Skill 安装
如果你使用的是兼容 Agent Skills 协议的 AI 平台，可以直接链接或复制本项目：
```bash
# 链接本项目作为全局 Skill
ln -s /path/to/tidy-skill ~/.your-agent/skills/tidy-skill

# 或直接拷贝
cp -r /path/to/tidy-skill ~/.your-agent/skills/tidy-skill
```

### 2. 手动集成到各开发环境
你可以直接将对应的模板复制到项目中：

#### 🤖 Claude Code
```bash
cp templates/CLAUDE.md /path/to/your/project/CLAUDE.md
```

#### 🎨 Cursor
```bash
# 复制 cursor 规则规则文件
cp templates/cursor-rule.mdc /path/to/your/project/.cursor/rules/agent-tidy.mdc
```

#### 🌐 通用 Agent (如 Codex 等)
```bash
cp templates/AGENTS.md /path/to/your/project/AGENTS.md
```

#### 📄 完整治理政策文档
```bash
cp templates/artifact-governance-policy.md /path/to/your/project/docs/
```

### 3. 项目最佳实践
推荐在你的项目 `.gitignore` 中加入以下配置，把 Agent 产生的临时文件彻底隔离在版本控制之外：
```gitignore
.agent_tmp/
.agent_reports/
```

推荐的项目结构如下：
```
project/
├─ AGENTS.md            # Agent 自律准则 (Class A)
├─ .agent_tmp/          # 临时 Agent 文件 (Class C - 自动清理)
├─ .agent_reports/      # 用户要求的报告 (Class B - 30 天后自动清理)
├─ README.md            # 正式文档 (Class A - 绝不触碰)
├─ docs/                # 正式文档目录 (Class A - 绝不触碰)
└─ src/
```

---

## 🛡️ 产物安全边界

所有的审计与清理操作都具备极高的安全保障：
1. **只读审计**：审计脚本只扫描文件元数据（名称、大小、修改时间），不读取或上传文件正文。
2. **默认 DryRun**：清理脚本默认只做预览，不会强行删除任何文件。
3. **根目录安全**：根目录下的可疑文件仅做报告，不自动清理（除非使用 `-ConfirmClean` 参数）。
4. **受保护名单（绝不删除）**：
   - 项目核心文件：`README.md`、`LICENSE`、`CHANGELOG.md` 等。
   - `docs/` 下的所有文档。
   - Git 已跟踪的任何文件。
   - 源代码（`src/`、`lib/`）与工具状态目录（`.claude/`、`.cursor/`、`.vscode/`）。

---

## 🛠️ 脚本说明

本项目提供了零依赖的 PowerShell 脚本，可在 Windows (自带) 和 macOS/Linux (运行 pwsh) 上原生执行：

| 脚本 | 作用 | 安全性 |
|---|---|---|
| `audit-agent-artifacts.ps1` | 只读审计单个仓库中的 Agent 产物 | 只读，不改动任何文件 |
| `score-repo-hygiene.ps1` | 按照六个维度给仓库整洁度评分 (0-100) | 只读 |
| `audit-workspace-hygiene.ps1` | 扫描整个工作区内的多个 Git 仓库 | 只读，要求显式提供目录 |
| `clean-agent-artifacts.ps1` | 清理过期的临时文件与报告 | 默认 DryRun |
| `clean-agent-artifacts.bat` | Windows 双击一键清理工具包 | 默认 DryRun |

---

## 🗺️ 路线图

- [ ] **Pre-commit 集成**：在代码 commit 前自动进行洁癖审计。
- [ ] **CI/CD 集成**：GitHub Actions 中自动进行仓库整洁度卫生检查。
- [ ] **多语言脚本移植**：提供原生 Bash / Python 版本的脚本，免去 PowerShell 依赖。
- [ ] **自定义权重**：允许用户自定义各个洁癖维度的扣分和计分权重。
- [ ] **实时 MCP 插件**：开发 MCP server，实现 Agent 的实时产物治理。

---

## 📄 开源协议

MIT License — 详见 [LICENSE](LICENSE) 文件。

Copyright (c) 2026 Tidy Skill Contributors.
