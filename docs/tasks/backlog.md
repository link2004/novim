# Backlog

Updated: 2026-08-27

Statuses: `PROPOSED`, `PLANNED`, `IN_PROGRESS`, `READY_FOR_REVIEW`,
`CHANGES_REQUESTED`, `BLOCKED`, or `ACCEPTED`.

| Priority | ID | Vertical slice | Status | Dependency |
|---:|---|---|---|---|
| 1 | TASK-001 | Run this checkout through an isolated `novim-dev` command without changing installed `novim` | PLANNED | None |
| 2 | TASK-002 | Navigate and search a project with a more deliberate file/code explorer | PROPOSED | TASK-001 + first-workflow decision |
| 3 | TASK-003 | Review local Git changes through a file list and readable diff workflow | PROPOSED | TASK-001 + Git authority decision |
| 4 | TASK-004 | Run project commands and open files at actionable locations from the editor | PROPOSED | TASK-002 |
| 5 | TASK-005 | Add opt-in language tooling and diagnostics without weakening startup isolation | PROPOSED | TASK-002 + plugin policy decision |
| 6 | TASK-006 | Add regression smoke tests and a repeatable local packaging/update path | PROPOSED | TASK-001 through TASK-005 |

## Task notes

- `TASK-002` should remain focused on observable navigation/search behavior; it
  should not silently become a plugin migration.
- `TASK-003` must state whether stage/unstage/commit are allowed. Push and
  other remote mutations require an explicit separate decision.
- `TASK-005` is intentionally opt-in until language, performance, and plugin
  lifecycle expectations are known.
