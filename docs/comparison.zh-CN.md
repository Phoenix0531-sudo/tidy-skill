# tidy-skill 横向对比

对比人们常与 tidy-skill 一起（或替代 tidy-skill）安装的 skills 的诚实定位。Star 数和安装量**不是质量声明**——只是市场背景。

| 项目 | 优化什么 | 默认磁盘行为 | 适合场景 |
|---|---|---|---|
| **tidy-skill**（本仓） | 本地环境洁癖：仓内垃圾、workspace 缓存、机器蔓延 | 对话优先；Class A–E 落位；DryRun 清理；评分/闸门；doctor→repair | Agent 让根目录变脏、缓存膨胀、你想要可度量闸门 |
| [planning-with-files](https://github.com/OthmanAdi/planning-with-files) | 长任务在 `/clear` 和压缩后存活 | 写 `task_plan.md` / `findings.md` / `progress.md`（或 `.planning/<slug>/`） | 多步任务要在上下文丢失后能续跑 |
| [obra/superpowers](https://github.com/obra/superpowers) | 规格 → 计划 → TDD 方法论包 | 跨多宿主的 skill 库 | 你想要一套有主见的工程工作流，而非洁癖 |
| [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) | 定义 → 计划 → 构建 → 验证 → 审查 → 交付 | 24 个生命周期 skill | 你想要生产代码的过程纪律 |
| [anthropics/skills](https://github.com/anthropics/skills) | Agent Skills 格式 / 参考 | 规格 + 示例 | 你在编写或研究 skill 标准 |
| [affaan-m/ECC](https://github.com/affaan-m/ECC) | Agent harness OS：skills、hooks、memory、安全 | 大组件安装；doctor/repair；会话保留旋钮 | 你要完整 harness，不只是洁癖 |
| [garrytan/gstack](https://github.com/garrytan/gstack) | 角色 slash 命令 + 发版安全闸 | `/careful` `/freeze` `/guard`；团队自动更新 | 你要 CEO/QA/CSO 式生产力角色 |
| [mattpocock/skills](https://github.com/mattpocock/skills) | 小而可组合的工程 skill | 插件订阅 vs skills.sh 可改副本 | 你要失败模式 skill，不是环境治理 |

## 一句话

> **planning-with-files** 让长任务在上下文丢失后存活。  
> **tidy-skill** 让机器和仓库不被 agent 垃圾淹没。  
> 两者并用：把 PWF 工作记忆放进 `.planning/`（首选）或用 policy 把根三件套 opt-in；其余让 tidy 评分、审计、卡门。

## 理念冲突（及如何解决）

| 维度 | planning-with-files | tidy-skill 默认 |
|---|---|---|
| 上下文模型 | 文件系统 = 持久磁盘 | 对话 = 默认；文件需要意图 |
| 根目录过程 Markdown | 期望存在（`task_plan.md` 等） | 禁止模式（`*_plan.md`、`progress.md` 等） |
| 并行工作 | `.planning/YYYY-MM-DD-slug/` | `.agent_tmp/` / `.agent_reports/` |
| 生命周期 | gitignore 的工作记忆 | 评分 / 审计 / DryRun / 过期 |
| 安全 | 计划 hooks、完成闸门 | 只读审计；不自动动 VHDX/配置 |

**解决方案（三选一）：**

1. **首选：** 把 PWF 放到 `.planning/` 下——tidy-skill 把 `.planning/**` 归为有意的 Class C 工作记忆（允许）。
2. **根三件套：** 加一个项目 policy，把 PWF 名字 opt-in：

```json
{
  "version": 1,
  "planning_root_globs": ["task_plan.md", "findings.md", "progress.md"],
  "min_score": 80,
  "require_agent_dirs": true
}
```

把 [`skills/tidy-skill/references/tidy-skill.policy.pwf.example.json`](../skills/tidy-skill/references/tidy-skill.policy.pwf.example.json) 复制为 `.tidy-skill.json`。这些名字不再算可疑根垃圾，也不会被默认清理扫到。**仍要 gitignore 它们。**

3. **仅忽略（较弱）：** `ignore_root_globs` 让名字从禁止匹配里隐身，但不标为规划工作记忆。

没有 opt-in，默认的 PWF 根三件套对 tidy-skill 仍然是脏的——这是设计如此。洁癖和崩溃安全的规划是不同产品；共存是显式的，不会静默发生。

## tidy-skill 独有的东西

1. **三层洁癖** —— 仓库产物、多仓 workspace 缓存、本机（WSL2 / Docker / VHDX / 包 / 模型缓存）。
2. **Class A–E + 落位意图检查** —— 写之前先判落位。
3. **可度量 CI 闸门** —— `score_repo_hygiene`、`hygiene_snapshot gate`、`tidy_doctor` 退出码。
4. **Doctor → repair 闭环** —— 诊断后 DryRun 优先安全修复（`tidy_repair`），不自动动宿主/VHDX。
5. **Python + PowerShell 共享项目 policy** —— `.tidy-skill.json`。
6. **离线 stdlib Python** —— 核心脚本无运行时网络依赖。
7. **安全动词** —— dryrun / careful / guard（文档与 CLI 同义）。

## 同类做得更好的地方（以及我们借了什么）

| 采纳面 | 谁做得好 | tidy-skill 借了什么 |
|---|---|---|
| Doctor → repair / 卸载路径 | ECC | `tidy_repair.py` + installation.md 卸载节 |
| 安全写成短动词 | gstack（`/careful` `/guard`） | dryrun · careful · guard 产品语言 |
| 按失败模式写 README，不堆方法论 | mattpocock/skills | 四种失败模式（根垃圾 / 缓存膨胀 / 不安全清理 / 无 CI 闸） |
| 订阅 vs 可改安装 | mattpocock、ECC | 双路径安装矩阵（skills CLI vs clone/本地） |
| 会话保留旋钮 | ECC | 文档化 tmp 7 天 / reports 30 天 + clean 脚本参数 |
| 宽宿主镜像 / marketplace | PWF、superpowers、addy | 保持精简；有真安装路径再扩 |
| 擦除后恢复叙事 | PWF、superpowers | 诚实自审 + fixture eval；不做假基准 |
| 并排对比页 | addy | 本文档 |

**仍不抄：** 200+ skill harness、Memory Vault、TDD 方法论包、自动写宿主配置、用 star 当质量指标。

## 非目标

- 不把 tidy-skill 重新包装成规划或 TDD 方法论包。
- 不自动删有意的 PWF 计划文件。
- 不声称没测过的第三方基准或安装排名。
- 不吞并 ECC/gstack 角色库，不变成完整 agent harness。

## 相关

- Policy schema 示例：[`skills/tidy-skill/references/tidy-skill.policy.example.json`](../skills/tidy-skill/references/tidy-skill.policy.example.json)
- PWF 共存 policy：[`skills/tidy-skill/references/tidy-skill.policy.pwf.example.json`](../skills/tidy-skill/references/tidy-skill.policy.pwf.example.json)
- 安装矩阵：[installation.md](installation.md)
- 英文版：[comparison.md](comparison.md)
