<div align="center">
<img src="docs/screenshots/banner.png" alt="洁癖.skill：三层卫生模型" width="100%">
</div>

<h1 align="center">洁癖.skill</h1>

<p align="center">
  <strong>让 AI Agent 在干净、可解释、可回收的本地环境里工作。</strong>
</p>

<p align="center">
  <a href="https://github.com/Phoenix0531-sudo/tidy-skill/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/Phoenix0531-sudo/tidy-skill/ci.yml?label=CI" alt="CI"></a>
  <a href="https://github.com/Phoenix0531-sudo/tidy-skill/actions/workflows/validate.yml"><img src="https://img.shields.io/github/actions/workflow/status/Phoenix0531-sudo/tidy-skill/validate.yml?label=Validate" alt="Validate"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License"></a>
  <img src="https://img.shields.io/badge/Python-3.10%2B-3776AB.svg" alt="Python">
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
git clone https://github.com/Phoenix0531-sudo/tidy-skill.git
cd tidy-skill
uv sync --extra dev

# 给本仓库打卫生分
uv run python skills/tidy-skill/scripts/score_repo_hygiene.py --root . --json
# {"score": 100, "rating": "Clean", ...}

# 一键 doctor（包完整性 + 卫生门禁）
uv run python skills/tidy-skill/scripts/tidy_doctor.py --root . --json

# 写文件前做 A–E 路径分类
uv run python skills/tidy-skill/scripts/classify_artifact.py plan.md --root . --json

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
| **Enhanced** | Windows 深度审计 + DryRun 清理 + 可选只读 stop hook | PowerShell 脚本 + `hooks/stop-hygiene-check.py` |
| **Standard** | 可移植打分 / 产物 / 环境 / 多仓工作区审计 | `uv run python skills/tidy-skill/scripts/*.py` |
| **Manual** | 多 Agent 共用卫生规则模板 | `install-rule-template.ps1` 或复制 templates |

**Skills CLI（已实测可发现）：** 标准 `skills/tidy-skill/SKILL.md` 包。作者于 2026-08-05 验证：

```bash
npx skills add Phoenix0531-sudo/tidy-skill --list
# Found 1 skill: tidy-skill

npx skills add Phoenix0531-sudo/tidy-skill --skill tidy-skill
```

完整矩阵、静默失败与 doctor：[docs/installation.md](docs/installation.md) · 验证记录：[docs/skills-cli-verify.md](docs/skills-cli-verify.md)。

分平台说明：[Claude](docs/platforms/claude.md) · [Codex](docs/platforms/codex.md) · [Cursor](docs/platforms/cursor.md) · [Pi](docs/platforms/pi.md) · [OpenCode](docs/platforms/opencode.md)。

可选宿主 hook 样例（不会自动注册）：[docs/host-samples/](docs/host-samples/)。

本地拷贝到 Agent 目录（先预览）：

```powershell
pwsh skills/tidy-skill/scripts/install-local.ps1
# 默认 Codex + Claude；可加 -Cursor -Pi -OpenCode 或 -All
pwsh skills/tidy-skill/scripts/install-local.ps1 -All -DryRun:$false -Force
```

**不声称** Claude/Codex 官方 marketplace 插件上架或安装量徽章。

## 自审证据

本仓库用自己的脚本审计自己。最近一次作者本地运行报告：

| 报告 | 路径 | 快照 |
|---|---|---|
| 仓库卫生打分 | [docs/self-audit/repo_hygiene_score.md](docs/self-audit/repo_hygiene_score.md) | **100 / 100** — Clean |
| Agent 产物审计 | [docs/self-audit/agent_artifacts_audit.md](docs/self-audit/agent_artifacts_audit.md) | **0** 可疑根文件 |
| 开发环境审计 | [docs/self-audit/dev_environment_audit.md](docs/self-audit/dev_environment_audit.md) | **90 / 100** — Highly controlled |
| Doctor | [docs/self-audit/tidy_doctor.md](docs/self-audit/tidy_doctor.md) | 包完整性 + 卫生通过 |
| Fixture evals | [docs/evals/latest.md](docs/evals/latest.md) | 作者本地确定性用例 |
| 案例 | [docs/cases/](docs/cases/) | 合成脏仓→干净 + 本仓库自审 |

重新生成：

```bash
uv run python skills/tidy-skill/scripts/score_repo_hygiene.py --root . --report-path docs/self-audit/repo_hygiene_score.md
uv run python skills/tidy-skill/scripts/audit_agent_artifacts.py --root . --max-depth 3 --report-path docs/self-audit/agent_artifacts_audit.md
uv run python skills/tidy-skill/scripts/audit_dev_environment.py --root . --report-path docs/self-audit/dev_environment_audit.md
uv run python skills/tidy-skill/scripts/tidy_doctor.py --root . --report-path docs/self-audit/tidy_doctor.md
uv run python tools/run_evals.py
```

> **方法学注脚。** 自审与 fixture evals 均由本仓库脚本完成。Internal v1，作者本地跑通；不是独立第三方基准。

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
| `score_repo_hygiene.py` | 仓库卫生 0–100（可选 `--weights` / `--policy`） | `uv run python skills/tidy-skill/scripts/score_repo_hygiene.py --root . --json` |
| `tidy_doctor.py` | 一键包完整性 + 卫生 doctor / CI 门禁 | `uv run python skills/tidy-skill/scripts/tidy_doctor.py --root . --json` |
| `classify_artifact.py` | 写文件前 A–E 路径分类 | `uv run python skills/tidy-skill/scripts/classify_artifact.py plan.md --root . --json` |
| `hygiene_snapshot.py` | 分数历史 + CI `gate`（`min_score`） | `uv run python skills/tidy-skill/scripts/hygiene_snapshot.py gate --root . --json` |
| `audit_agent_artifacts.py` | 列出可疑根文件与受保护文档 | `uv run python skills/tidy-skill/scripts/audit_agent_artifacts.py --root . --json` |
| `audit_dev_environment.py` | 可移植本机缓存 / 环境基线 | `uv run python skills/tidy-skill/scripts/audit_dev_environment.py --root . --json` |
| `audit_workspace_hygiene.py` | 多仓库工作区审计（必须显式 root） | `uv run python skills/tidy-skill/scripts/audit_workspace_hygiene.py --root <path> --json` |
| `audit-dev-environment.ps1` | Windows 深度审计（WSL2 / Docker / VHDX） | `pwsh skills/tidy-skill/scripts/audit-dev-environment.ps1 -Roots .` |
| `clean-agent-artifacts.ps1` | 清理过期 agent 临时/报告文件 | `pwsh skills/tidy-skill/scripts/clean-agent-artifacts.ps1 -Root . -DryRun` |
| `hooks/stop-hygiene-check.py` | 任务结束只读检查 | `uv run python skills/tidy-skill/hooks/stop-hygiene-check.py --root .` |
| `install-local.ps1` | 安装到 Codex / Claude / Cursor / Pi / OpenCode | `pwsh skills/tidy-skill/scripts/install-local.ps1 -All` |
| `install-rule-template.ps1` | 安装 AGENTS / CLAUDE / Cursor 模板 | `pwsh skills/tidy-skill/scripts/install-rule-template.ps1 -TargetRoot <path>` |

Python 脚本纯标准库。清理与安装默认 DryRun。触发语与命令 stub 见 `skills/tidy-skill/commands/`。

## 范围

**在范围内**

- 对 agent 产物、仓库卫生、多仓工作区、本机缓存足迹的只读审计
- 可选项目策略（`.tidy-skill.json`）、doctor、写前分类器、分数历史/门禁
- 对 `.agent_tmp/` / `.agent_reports/` 的 DryRun 清理预览
- 可选只读 stop hook 与 pre-commit 根目录过程文档拦截
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
tidy-skill/
├─ skills/tidy-skill/
│  ├─ SKILL.md                 # skill 定义（三层模型、A–E 分类）
│  ├─ scripts/                 # Python + PowerShell 工具
│  ├─ hooks/                   # 只读 stop 检查
│  ├─ commands/                # 触发语 + 命令 stub
│  ├─ templates/               # AGENTS.md / CLAUDE.md / cursor-rule
│  ├─ references/              # 更细的使用说明
│  └─ examples/
├─ tools/                      # validate_skill、run_evals、pre-commit 辅助
├─ evals/                      # fixture eval 说明
├─ tests/                      # pytest + PowerShell 安全测试
├─ docs/
│  ├─ installation.md          # 安装矩阵 + doctor
│  ├─ platforms/               # Claude / Codex / Cursor / Pi / OpenCode
│  ├─ host-samples/            # 可选 hook JSON 样例
│  ├─ cases/                   # before/after 案例
│  ├─ screenshots/             # banner + 终端预览
│  ├─ self-audit/              # 作者本地自审报告
│  └─ evals/                   # 最近一次 fixture eval
├─ .github/workflows/          # ci.yml + validate.yml
├─ pyproject.toml
└─ README.md / README.zh-CN.md
```

## 许可证

MIT。详见 [LICENSE](LICENSE)。
