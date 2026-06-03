# Agent Tidy Skill

别让 AI Agent 把你的项目根目录变成 Markdown 垃圾场。

**本项目不是 Markdown 删除器。** 它治理的是没有生命周期、没有归属、没有复用价值的 Agent 产物。

[English](README.md)

---

## 为什么需要 Agent 产物治理？

AI coding agent 很喜欢留下痕迹。一次对话产生 `plan.md`、`todo.md`、`progress.md`、`summary.md`、`final_report.md`…… 很快你的项目根目录就堆满了没人要也每人维护的一次性文件。

本项目不禁止 Markdown。它建立了一套框架，让 Agent 能够判断：

1. 这个文件应该存在吗？
2. 它属于哪一类？
3. 应该放在哪里？
4. 应该保留多久？
5. 什么时候应该删除？

## 它解决什么问题

- Agent 在项目根目录随意生成泛名 Markdown。
- 临时过程文件和正式文档混在一起，没有区分。
- 过程产物没有生命周期。
- Agent 留下了什么文件，没有人审计。
- 没有可重复执行的规则。
- 多个 Agent（Claude + Codex + Cursor）互相污染项目目录。

## 它不解决什么问题

- 删除正式项目文档。
- 清理源代码。
- 管理工具状态目录（`.claude/`、`.cursor/`、`.vscode/`、`*.sqlite` 等）。
- 替代版本控制、Issue 跟踪或正式文档流程。
- 全盘扫描或清理用户个人文件夹。

---

## 快速开始

### 1. 将 Agent 规则复制到你的项目

```bash
cp templates/AGENTS.md /path/to/your/project/AGENTS.md
```

对 Claude Code：

```bash
cp templates/CLAUDE.md /path/to/your/project/CLAUDE.md
```

对 Cursor：

```bash
cp templates/cursor-rule.mdc /path/to/your/project/.cursor/rules/agent-tidy.mdc
```

### 2. 运行审计

```powershell
# 检查项目中存在哪些 Agent 产物
powershell -ExecutionPolicy Bypass -File scripts/audit-agent-artifacts.ps1 -Root "C:\path\to\your\project"
```

这会生成一份 Markdown 审计报告。不会修改任何文件。

### 3. 运行 DryRun 清理

```powershell
# 查看将会清理什么，但不删除任何文件
powershell -ExecutionPolicy Bypass -File scripts/clean-agent-artifacts.ps1 -Root "C:\path\to\your\project" -DryRun
```

### 4. 添加 `.gitignore` 条目

在你的项目 `.gitignore` 中添加：

```gitignore
.agent_tmp/
.agent_reports/
```

---

## 文件分类

| 类别 | 示例 | 存放位置 | 生命周期 | 可自动删除？ |
|---|---|---|---|---|
| **正式文档** | `README.md`、`docs/`、`LICENSE` | 项目文档结构 | 永久 | 永不 |
| **用户要求的交付物** | 审计报告、迁移方案 | `.agent_reports/` | 30 天（可配置） | 超期后可删 |
| **临时过程产物** | plan、todo、notes、progress | `.agent_tmp/` | 7 天（可配置） | 超期后可删 |
| **Agent 自嗨文件** | summary、final_report、work_summary | **不要创建** | 不适用 | 不适用 |
| **工具状态文件** | `.claude/`、`.cursor/`、`*.sqlite` | 工具自有目录 | 不适用 | 永不 |

完整分类请见 [references/artifact-classification.md](references/artifact-classification.md)。

---

## 推荐项目结构

```
project/
├─ AGENTS.md
├─ .agent_tmp/          # 临时 Agent 文件 — 可自动清理
├─ .agent_reports/      # 用户要求的报告 — 30 天保留期
├─ README.md
├─ docs/                # 正式文档 — 受保护
└─ src/
```

---

## 安全原则

1. **先 DryRun。** 所有清理脚本默认只读模式。
2. **不自动删除正式文档。** `README.md`、`CHANGELOG.md`、`LICENSE`、`CONTRIBUTING.md`、`docs/` 受保护。
3. **根目录可疑文件只报告，不自动删除。** 由用户决策。
4. **不修改系统。** 不注册计划任务、不修改注册表、不需要管理员权限。
5. **不联网。** 清理脚本完全离线运行。
6. **不上传。** 无遥测、无日志上报、无环境捕获。
7. **无依赖。** 纯 PowerShell 和 Batch——零 npm/pip 安装。

---

## 常见问题

**问：这个工具会删除团队的文档吗？**  
不会。正式文档（`docs/`、`README.md`、`CHANGELOG.md`、`LICENSE` 等）受保护。

**问：如果我想要永久保留一份报告呢？**  
将其从 `.agent_reports/` 移动到 `docs/` 或移出 `.gitignore`。

**问：非 Markdown 的 Agent 产物也能治理吗？**  
分类系统和 Artifact Intent Check 适用于任何文件类型。审计脚本专注于 Markdown，因为它是 Agent 最常见的垃圾来源。

**问：可以每周自动运行清理吗？**  
脚本可以安全地用于定时执行。如果你需要，可以自行注册 Windows Task Scheduler——但本项目**不会**替你注册。详见 [scripts/README.md](scripts/README.md)。

**问：支持 Mac/Linux 吗？**  
审计和清理脚本基于 PowerShell，兼容 macOS 和 Linux 上的 PowerShell 7+。

---

## License

MIT — 详见 [LICENSE](LICENSE)。

Copyright (c) 2026 Agent Tidy Skill contributors
