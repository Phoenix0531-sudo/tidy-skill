<div align="center">
<img src="docs/screenshots/banner.png" alt="洁癖.skill：三层卫生模型" width="100%">
</div>

<h1 align="center">洁癖.skill</h1>

<p align="center">
  <strong>让 AI Agent 在干净、可解释、可回收的本地环境里工作。</strong>
</p>

<p align="center">
  <a href="https://github.com/Phoenix0531-sudo/Tidy_Skill/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/Phoenix0531-sudo/Tidy_Skill/ci.yml?label=CI" alt="CI"></a>
  <a href="https://github.com/Phoenix0531-sudo/Tidy_Skill/actions/workflows/validate.yml"><img src="https://img.shields.io/github/actions/workflow/status/Phoenix0531-sudo/Tidy_Skill/validate.yml?label=Validate" alt="Validate"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License"></a>
  <img src="https://img.shields.io/badge/Python-3.11-3776AB.svg" alt="Python">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-5391FE.svg" alt="PowerShell">
  <img src="https://img.shields.io/badge/network-offline-lightgrey.svg" alt="offline">
</p>

<p align="center">
  <a href="#前后对照">前后对照</a> ·
  <a href="#三层卫生模型">三层模型</a> ·
  <a href="#快速开始">快速开始</a> ·
  <a href="#自审证据">自审证据</a> ·
  <a href="#产物分类">产物分类</a> ·
  <a href="#范围">范围</a> ·
  <a href="#常见问题">常见问题</a>
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.zh-CN.md">中文</a>
</p>

---

## 前后对照

<table>
<tr>
<td width="50%" valign="top">

**没有卫生治理时**

> Agent 把 `plan.md`、`todo.md`、`final_report.md` 直接丢在仓库根目录。
> 下一轮会话重新扫仓库，又让你把目标再说一遍。
> 看到体积很大的 `.venv` 或 `node_modules` 就想直接删。

</td>
<td width="50%" valign="top">

**有洁癖.skill 时**

> 计划留在对话里；报告进 `.agent_reports/`；临时文件进 `.agent_tmp/`。
> 审计只列路径、体积、风险与**安全建议**——不自动删除。
> 清理默认 **DryRun**；迁移、压缩、改配置一律只给建议。

</td>
</tr>
</table>

## 三层卫生模型

| 层级 | 治理对象 | 典型问题 | 工具 |
|---|---|---|---|
| **Repository** | Agent 产物 | `plan.md`、`todo.md` 堆在仓库根目录 | `audit_agent_artifacts.py`、`score_repo_hygiene.py` |
| **Workspace** | 开发缓存 | `node_modules`、`.venv`、`target`、构建缓存膨胀 | `audit-workspace-hygiene.ps1` |
| **Local machine** | 本机环境足迹 | WSL2/Docker VHDX 增长，包缓存/模型缓存膨胀 | `audit-dev-environment.ps1`、`audit_dev_environment.py` |

<p align="center">
  <img src="docs/screenshots/preview.png" alt="终端自审：score_repo_hygiene 与 audit_agent_artifacts" width="90%">
</p>

## 快速开始

```bash
git clone https://github.com/Phoenix0531-sudo/Tidy_Skill.git
cd Tidy_Skill
uv sync --extra dev

# 给本仓库打卫生分
uv run python skills/tidy-skill/scripts/score_repo_hygiene.py --root . --json
# {"score": 77, "rating": "Mostly clean", ...}

# 审计 agent 产物
uv run python skills/tidy-skill/scripts/audit_agent_artifacts.py --root . --json

# 审计本机开发环境（只读）
uv run python skills/tidy-skill/scripts/audit_dev_environment.py --root . --json

# Windows 深度审计（WSL2/Docker/VHDX）
pwsh skills/tidy-skill/scripts/audit-dev-environment.ps1 -Roots .

# 清理预览（DryRun，不删除任何文件）
pwsh skills/tidy-skill/scripts/clean-agent-artifacts.ps1 -Root . -DryRun

# 测试
uv run pytest tests/
uv run ruff check . --select E9,F63,F7,F82
```

### 安装矩阵

| 档位 | 你得到什么 | 怎么做 |
|---|---|---|
| **Enhanced** | Windows 深度审计：WSL2、Docker VHDX、包/模型缓存 + DryRun 清理 | `skills/tidy-skill/scripts/*.ps1` |
| **Standard** | 可移植的仓库打分 + 产物审计 + 环境基线（跨平台） | `uv run python skills/tidy-skill/scripts/*.py` |
| **Manual** | 多 Agent 项目共用的卫生规则模板 | `install-rule-template.ps1` 或复制 `templates/AGENTS.md`、`CLAUDE.md`、`cursor-rule.mdc` |

把 skill 包安装到本地 Agent 目录（先预览）：

```powershell
pwsh skills/tidy-skill/scripts/install-local.ps1
# 真正复制需要显式确认：
pwsh skills/tidy-skill/scripts/install-local.ps1 -DryRun:$false -Force
```

## 自审证据

本仓库用自己的脚本审计自己。最近一次作者本地运行报告：

| 报告 | 路径 | 快照 |
|---|---|---|
| 仓库卫生打分 | [docs/self-audit/repo_hygiene_score.md](docs/self-audit/repo_hygiene_score.md) | **77 / 100** — Mostly clean |
| Agent 产物审计 | [docs/self-audit/agent_artifacts_audit.md](docs/self-audit/agent_artifacts_audit.md) | **0** 可疑根文件 |
| 开发环境审计 | [docs/self-audit/dev_environment_audit.md](docs/self-audit/dev_environment_audit.md) | **90 / 100** — Highly controlled |

重新生成：

```bash
uv run python skills/tidy-skill/scripts/score_repo_hygiene.py --root . --report-path docs/self-audit/repo_hygiene_score.md
uv run python skills/tidy-skill/scripts/audit_agent_artifacts.py --root . --max-depth 3 --report-path docs/self-audit/agent_artifacts_audit.md
uv run python skills/tidy-skill/scripts/audit_dev_environment.py --root . --report-path docs/self-audit/dev_environment_audit.md
```

> **方法学注脚。** 自审由本仓库脚本完成，不是独立第三方审计。Internal v1，作者在单台 Windows 机器上跑通；不是独立对照实验，也不是第三方基准。

## 产物分类

五级放置模型（详见 [SKILL.md](skills/tidy-skill/SKILL.md)）：

| 级别 | 类型 | 放置位置 | 示例 |
|---|---|---|---|
| **A** | 正式文档 | 仓库根 / `docs/` | `README.md`、`CHANGELOG.md`、设计说明 |
| **B** | 用户交付物 | 约定输出路径 | 用户明确要求的最终报告 |
| **C** | 临时产物 | `.agent_tmp/` | 草稿、中间笔记 |
| **D** | 自贺噪声 | 不保留 | 「任务完成」类空话文档 |
| **E** | 工具 / Agent 状态 | 跟踪树外或已忽略 | IDE 状态、会话缓存 |

## 命令表

| 脚本 | 用途 | 调用 |
|---|---|---|
| `score_repo_hygiene.py` | 仓库卫生 0–100 分（6 维度） | `uv run python skills/tidy-skill/scripts/score_repo_hygiene.py --root . --json` |
| `audit_agent_artifacts.py` | 列出可疑根文件与受保护文档 | `uv run python skills/tidy-skill/scripts/audit_agent_artifacts.py --root . --json` |
| `audit_dev_environment.py` | 可移植本机缓存 / 环境基线 | `uv run python skills/tidy-skill/scripts/audit_dev_environment.py --root . --json` |
| `audit-dev-environment.ps1` | Windows 深度审计（WSL2 / Docker / VHDX） | `pwsh skills/tidy-skill/scripts/audit-dev-environment.ps1 -Roots .` |
| `audit-workspace-hygiene.ps1` | 多仓库工作区缓存扫描 | `pwsh skills/tidy-skill/scripts/audit-workspace-hygiene.ps1 -Root <path>` |
| `clean-agent-artifacts.ps1` | 清理过期 agent 临时/报告文件 | `pwsh skills/tidy-skill/scripts/clean-agent-artifacts.ps1 -Root . -DryRun` |
| `install-local.ps1` | 安装 skill 到 Codex / Claude 目录 | `pwsh skills/tidy-skill/scripts/install-local.ps1` |
| `install-rule-template.ps1` | 安装 AGENTS / CLAUDE / Cursor 模板 | `pwsh skills/tidy-skill/scripts/install-rule-template.ps1 -TargetRoot <path>` |

Python 脚本纯标准库（无网络、无第三方运行时依赖）。清理与安装脚本默认 DryRun。

## 范围

**在范围内**

- 对 agent 产物、仓库卫生、本机缓存足迹的只读审计
- 对 `.agent_tmp/` / `.agent_reports/` 的 DryRun 清理预览
- 让多个 Agent 共享同一放置策略的规则模板
- 纯本地、离线运行

**不在范围内**

- 自动删除正式文档、源码或 Git 跟踪文件
- 自动迁移 WSL 发行版、压缩 VHDX、搬迁 Docker 数据
- 读取 token / 凭证 / 数据库 / 私有日志
- 未指定 root 的全盘扫描
- 网络调用或上传

## 常见问题

<details>
<summary>清理会默认删我的文件吗？</summary>

不会。`clean-agent-artifacts.ps1` 默认 **DryRun**，只预览 agent 临时/报告目录下的候选。真正删除需要显式确认参数。审计脚本永不删除。

</details>

<details>
<summary>为什么同时有 Python 和 PowerShell？</summary>

Python 负责跨平台、无依赖的仓库检查与环境基线。PowerShell 补充 Windows 深度能力：WSL2、Docker Desktop VHDX、用户配置目录缓存等，这些纯 Python 难以以同等安全方式探查。

</details>

<details>
<summary>什么时候不该用这个 skill？</summary>

不要把它当成通用磁盘清理器、安全扫描器或备份替代品。它不会自动修整整个 C 盘、压缩 VHDX，也不会改写 agent 配置。若需要这些操作，请按厂商文档执行，并把本 skill 的输出仅当作建议。

</details>

## 目录结构

```text
Tidy_Skill/
├─ skills/tidy-skill/
│  ├─ SKILL.md                 # skill 定义（三层模型、A–E 分类）
│  ├─ scripts/                 # Python + PowerShell 工具
│  ├─ templates/               # AGENTS.md / CLAUDE.md / cursor-rule
│  ├─ references/              # 更细的使用说明
│  └─ examples/
├─ tools/validate_skill.py     # skill 包校验
├─ tests/                      # pytest + PowerShell 安全测试
├─ docs/
│  ├─ screenshots/             # banner + 终端预览
│  └─ self-audit/              # 作者本地自审报告
├─ .github/workflows/          # ci.yml + validate.yml
├─ pyproject.toml
└─ README.md / README.zh-CN.md
```

## 许可证

MIT。详见 [LICENSE](LICENSE)。
