# 洁癖.skill / Tidy Skill

别让 AI Agent 把你的项目根目录变成 Markdown 垃圾场。

> 给代码环境洁癖用户的 Agent 产物治理 Skill。

[English](README.md)

---

## 这是什么？

**洁癖.skill**（Tidy Skill）是一个 **AI Agent 产物治理工具包**，专门为在意代码环境整洁的开发者设计。它做三件事：

1. **让 Agent 先想再写** — 这个文件必须创建吗？应该放哪里？什么时候删？
2. **审计并打分** — 你的仓库有多干净？Agent 产物有没有乱放？
3. **安全清理** — 只清理临时文件和过期报告，**绝不碰**你的正式文档。

---

## 为什么需要它？

AI coding agent 很能干。但它们也很脏。

一次对话产生 `plan.md`、`todo.md`、`progress.md`、`summary.md`、`final_report.md`…… 很快你的项目根目录就堆满了没人要也没人维护的一次性文件。

更糟的是，不同 Agent（Claude Code、Codex、Cursor）各自写各自的垃圾。问题不是 Markdown 本身。问题是这些文件**没有用途、没有归属、没有生命周期、没有复用价值**。

洁癖.skill 不禁止 Markdown。它让每个 Agent 产物都有目的、有归属、有生命周期。

---

## 它能做什么？

| 能力             | 说明                                              |
| -------------- | ----------------------------------------------- |
| **产物意图检查**     | 强制 Agent 在创建文件前先过 Artifact Intent Check         |
| **文件生成规则**     | 禁止泛名 Markdown 进入项目根目录                           |
| **仓库洁癖评分**     | 六维度评分 0–100 分                                   |
| **工作区洁癖审计**    | 授权后扫描多个仓库的 Agent 产物                             |
| **保守清理**       | 默认 DryRun；只清理 `.agent_tmp/` 和 `.agent_reports/` |
| **Agent 规则模板** | AGENTS.md、CLAUDE.md、Cursor Rules — 复制即用         |

---

## 核心理念

一个文件不是因为是 Markdown 所以是垃圾。它成为垃圾，是因为它**没有意图、没有归属、没有读者、没有生命周期、没有复用价值**。

> This is not a Markdown deleter. It governs agent-generated artifacts that have no ownership, no lifecycle, and no reusable value.

---

## 快速开始

### 1. 审计一个仓库

```powershell
cd scripts/
.\audit-agent-artifacts.ps1 -Root "C:\path\to\your\project"
```

生成 Markdown 报告，不修改任何文件。

### 2. 仓库洁癖评分

```powershell
.\score-repo-hygiene.ps1 -Root "C:\path\to\your\project"
```

获得 0–100 分的洁癖评分与分项明细。

### 3. DryRun 清理预览

```powershell
.\clean-agent-artifacts.ps1 -Root "C:\path\to\your\project"
```

预览将要清理的内容，不删除任何文件。

### 4. 为你的项目添加 Agent 规则

```bash
cp templates/AGENTS.md /path/to/project/AGENTS.md
cp templates/CLAUDE.md /path/to/project/CLAUDE.md
```

---

## 作为 Skill 安装

如果你的 Agent 平台支持 Skills，链接或复制本目录：

```bash
# macOS / Linux
ln -s /path/to/tidy-skill ~/.your-agent/skills/tidy-skill

# 或直接复制
cp -r /path/to/tidy-skill ~/.your-agent/skills/tidy-skill
```

---

## 手动安装路径

### Claude Code

```bash
cp templates/CLAUDE.md /path/to/your/project/CLAUDE.md
```

### Cursor

```bash
cp templates/cursor-rule.mdc /path/to/your/project/.cursor/rules/agent-tidy.mdc
```

### 通用 Agent

```bash
cp templates/AGENTS.md /path/to/your/project/AGENTS.md
```

### 完整政策文档

```bash
cp templates/artifact-governance-policy.md /path/to/your/project/docs/
```

---

## 在项目中使用

推荐 `.gitignore` 条目：

```gitignore
.agent_tmp/
.agent_reports/
```

推荐项目结构：

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

## Artifact Intent Check / 产物意图检查

在创建任何文件之前，Agent 必须先过这道检查：

```
产物意图检查 / Artifact Intent Check
────────────────────────────────────
1. 用户是否明确要求了文件？       是 / 否
2. 用途：
3. 读者：
4. 预期生命周期：                   会话 / 天 / 持久 / 正式文档
5. 目标路径：
6. 为什么聊天回复不够？
7. 分类：                           临时 / 持久报告 / 正式文档
8. 应该被 Git 忽略吗？              是 / 否
```

任何一项无法回答，**就不要创建文件。**

---

## 仓库洁癖评分

Tidy Skill 可以从六个维度给你的仓库打分（0–100 分）：

| 维度         | 权重  | 衡量什么                                           |
| ---------- | --- | ---------------------------------------------- |
| 根目录清洁度     | 25% | 根目录是否堆满了 plan/todo/summary 文件？                 |
| 产物归属       | 20% | 临时文件在 `.agent_tmp/` 吗？报告在 `.agent_reports/` 吗？ |
| 正式文档清晰度    | 15% | README、LICENSE、docs/ 是否结构清晰？                   |
| Git 卫生     | 15% | Agent 产物目录是否被 gitignore？                       |
| Agent 状态隔离 | 15% | 工具状态目录是否与项目文件分离？                               |
| 可清理性       | 10% | 是否有明确的清理路径和生命周期？                               |

| 分数     | 评级          |
| ------ | ----------- |
| 90–100 | 很干净         |
| 70–89  | 基本干净        |
| 50–69  | 需要整理        |
| 0–49   | Agent 产物垃圾场 |

---

## 工作区洁癖审计

如果你有多个仓库，`audit-workspace-hygiene.ps1` 可以扫描整个工作区：

```powershell
.\audit-workspace-hygiene.ps1 -Root "E:\1_Code\Projects"
```

报告内容：

- 每个仓库的洁癖评分
- 最脏的前 10 个仓库
- 最常见的可疑文件名
- `.agent_tmp` / `.agent_reports` 使用统计
- 全局优化建议

**隐私保障：** 必须显式指定根目录。脚本永远不会默认扫描 `C:\` 或 `$HOME`。不读取文件正文。不上传任何数据。

---

## 安全清理

所有清理脚本遵循以下规则：

1. **先 DryRun。** 预览将要删除的内容，确认后才执行。
2. **默认范围。** 只清理 `.agent_tmp/`（超过 7 天）和 `.agent_reports/`（超过 30 天）。
3. **根目录可疑文件？** 只报告，不自动删除。用 `-ConfirmClean` 参数才处理。
4. **受保护文件？** 永远不会碰。

---

## 默认绝不会删除什么？

```
README.md, README.*.md
CHANGELOG.md
LICENSE, LICENSE.*
CONTRIBUTING.md
CODE_OF_CONDUCT.md
SECURITY.md
docs/ 下的所有文件
.git 跟踪的文件（.agent_tmp/ 和 .agent_reports/ 除外）
源代码（src/、lib/、app/）
工具状态目录（.claude/、.cursor/、.codex/、.vscode/、*.sqlite）
```

---

## 示例

详见 [examples/bad-artifacts.md](examples/bad-artifacts.md) 和 [examples/good-artifacts.md](examples/good-artifacts.md)。

### 坏文件

```
./plan.md                 → 泛名，无生命周期，应该在聊天里
./summary.md              → 自嗨，没有读者
./final_report.md         → 同上
./implementation_plan.md  → 分类错误，没有归属目录
```

### 好文件

```
.agent_reports/migration_plan_2026-06-03.md  → 用户要求，有范围，有日期
docs/deployment.md                            → 正式文档，正确位置
.agent_tmp/refactor_steps_2026-06-03.md       → 临时文件，任务结束后清理
```

---

## 脚本说明

| 脚本                            | 作用            | 安全性        |
| ----------------------------- | ------------- | ---------- |
| `audit-agent-artifacts.ps1`   | 只读审计一个仓库      | 从不修改文件     |
| `score-repo-hygiene.ps1`      | 仓库洁癖评分（0–100） | 只读         |
| `audit-workspace-hygiene.ps1` | 多仓库工作区扫描      | 只读，需显式指定目录 |
| `clean-agent-artifacts.ps1`   | 保守清理          | 默认 DryRun  |
| `clean-agent-artifacts.bat`   | Windows 双击包装器 | 默认 DryRun  |

所有脚本基于 PowerShell，零依赖，离线运行，不上传数据。

---

## 推荐项目结构

```
project/
├─ AGENTS.md
├─ .agent_tmp/          # Agent 临时文件 — Git 忽略，可自动清理
├─ .agent_reports/      # 用户要求的报告 — Git 忽略，30 天保留期
├─ README.md
├─ docs/                # 正式文档 — 受版本控制，受保护
└─ src/
```

---

## 常见问题

**问：它会删除团队文档吗？**  
不会。`docs/`、`README.md`、`CHANGELOG.md`、`LICENSE` 等全部受保护。

**问：我想永久保留一份报告怎么办？**  
从 `.agent_reports/` 移动到 `docs/`，或移出 `.gitignore`。

**问：可以同时扫描多个仓库吗？**  
可以。`audit-workspace-hygiene.ps1` 扫描指定目录下的所有仓库。你必须指定根路径。

**问：支持 Mac/Linux 吗？**  
支持。PowerShell 7+ 跨平台。所有脚本兼容 macOS 和 Linux。

**问：可以设置每周自动清理吗？**  
脚本安全可用于定时任务。你可以手动配置 Windows Task Scheduler 或 cron — 洁癖.skill **绝不会**替你注册。

**问：为什么用 PowerShell 而不是 Python？**  
零依赖。Windows 自带 PowerShell，PowerShell 7 跨平台。无需 pip install、无需 virtualenv、无需配置运行时。

---

## 路线图

- **Pre-commit hook 集成** — 提交前自动审计
- **CI/CD 集成** — GitHub Actions 中的卫生检查
- **Bash/Python 脚本移植** — 非 PowerShell 环境
- **自定义评分权重** — 用户可配置的评分维度
- **MCP 插件** — 实时 Agent 治理

---

## License

MIT — 详见 [LICENSE](LICENSE)。

Copyright (c) 2026 Tidy Skill contributors
