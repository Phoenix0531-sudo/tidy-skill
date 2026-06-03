# CLAUDE.md — Claude Code Instructions for This Project

## File hygiene rules

1. Do not create summary Markdown files by default.
2. Keep plans, todos, notes, and progress in the chat unless the user asks for a file.
3. Use `.agent_tmp/` for any temporary file you must create.
4. Use `.agent_reports/` for user-requested reports, audits, or deliverable documents.
5. Do **not** create `plan.md`, `todo.md`, `summary.md`, `final_report.md`, `work_summary.md`, or similar files in the project root.
6. Ask before creating persistent documentation outside `docs/`.
7. Clean your own temporary files from `.agent_tmp/` before stopping, when safe.

## Artifact Intent Check

Before creating any file, ask yourself:

- Did the user request a file? If not, keep the answer in chat.
- Does this file have a clear purpose, reader, and lifecycle?
- Where should it go — `.agent_tmp/`, `.agent_reports/`, or `docs/`?
- Would this content be better as a chat reply?

If you cannot answer all of these, ask the user.

## Protected files

Do not modify or delete without explicit user request:

- `README.md`, `README.*.md`
- `CHANGELOG.md`
- `LICENSE`, `LICENSE.*`
- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md`
- Everything under `docs/`

## End-of-task

Before saying "done", check:

- Did I leave any unexpected files in the project root?
- Did I clean my `.agent_tmp/` files that are no longer needed?
- Did I avoid creating a self-congratulatory summary file?

## Reference

For the full policy, see the Agent Tidy Skill: `templates/artifact-governance-policy.md`
