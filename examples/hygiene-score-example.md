# Repo Hygiene Score — Example Report

This is a sample output from `scripts/score-repo-hygiene.ps1`.

---

## Example: Clean Repo (Score: 94/100)

**Repository:** `C:\Projects\well-maintained-app`
**Score:** 94 / 100 — **Clean** (很干净)

| Dimension | Score | Max | Notes |
|---|---|---|---|
| Root cleanliness | 25 | 25 | No suspicious files in root |
| Artifact placement | 18 | 20 | Has `.agent_tmp/` and `.agent_reports/` |
| Protected docs clarity | 15 | 15 | Has README, LICENSE, CHANGELOG, docs/ |
| Git hygiene | 14 | 15 | .gitignore includes artifact dirs |
| Agent state isolation | 15 | 15 | Clean separation |
| Cleanup readiness | 7 | 10 | Has cleanup directories |
| **Total** | **94** | **100** | **Clean** |

### What's right

- Root directory is clean — no `plan.md`, `todo.md`, or `summary.md` in sight.
- Agent temp files go to `.agent_tmp/`, reports go to `.agent_reports/`.
- `.gitignore` excludes both artifact directories.
- README, LICENSE, and CHANGELOG are present and well-structured.
- Tool state directories (`.vscode/`, `.claude/`) are properly isolated.

---

## Example: Needs Tidy-Up (Score: 56/100)

**Repository:** `C:\Projects\messy-repo`
**Score:** 56 / 100 — **Needs tidy-up** (需要整理)

| Dimension | Score | Max | Notes |
|---|---|---|---|
| Root cleanliness | 5 | 25 | 7 suspicious files in root |
| Artifact placement | 5 | 20 | No `.agent_tmp/`, no `.agent_reports/` |
| Protected docs clarity | 5 | 15 | Has README but no LICENSE, no docs/ |
| Git hygiene | 10 | 15 | Has .gitignore but doesn't exclude artifacts |
| Agent state isolation | 15 | 15 | No state dirs found |
| Cleanup readiness | 0 | 10 | No cleanup structure |
| **Total** | **56** | **100** | **Needs tidy-up** |

### Suspicious Files in Root

- `plan.md` (1.2 KB, modified 2026-05-28)
- `todo.md` (0.8 KB, modified 2026-05-28)
- `summary.md` (2.1 KB, modified 2026-05-28)
- `final_report.md` (3.4 KB, modified 2026-05-28)
- `implementation_plan.md` (4.2 KB, modified 2026-05-25)
- `audit_report.md` (2.7 KB, modified 2026-05-20)
- `work_summary.md` (1.5 KB, modified 2026-05-30)

### Recommendations

1. Remove or relocate the 7 suspicious root-level files.
2. Create `.agent_tmp/` for temporary agent files.
3. Create `.agent_reports/` for user-requested reports.
4. Add a `LICENSE` file and consider a `docs/` directory.
5. Update `.gitignore` to exclude `.agent_tmp/` and `.agent_reports/`.

---

## Example: Artifact Landfill (Score: 28/100)

**Repository:** `C:\Projects\abandoned-agent-mess`
**Score:** 28 / 100 — **Artifact landfill** (Agent 产物垃圾场)

| Dimension | Score | Max | Notes |
|---|---|---|---|
| Root cleanliness | 5 | 25 | 12 suspicious files |
| Artifact placement | 0 | 20 | Everything dumped in root |
| Protected docs clarity | 3 | 15 | No README, no LICENSE |
| Git hygiene | 5 | 15 | No .gitignore for artifacts |
| Agent state isolation | 10 | 15 | State dirs mixed with project files |
| Cleanup readiness | 5 | 10 | No cleanup structure |
| **Total** | **28** | **100** | **Artifact landfill** |

### Recommendations

1. Start with an audit: `.\audit-agent-artifacts.ps1 -Root "C:\Projects\abandoned-agent-mess"`
2. Review and clean the 12 suspicious files in the project root.
3. Create a basic project structure with README, LICENSE, and docs/.
4. Create `.agent_tmp/` and `.agent_reports/` for future agent work.
5. Add `.gitignore` entries for both directories.
6. Configure Tidy Skill templates to prevent future pollution.
