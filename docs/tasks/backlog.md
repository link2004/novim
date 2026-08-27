# Backlog

Updated: 2026-08-27

Statuses: `PROPOSED`, `PLANNED`, `IN_PROGRESS`, `READY_FOR_REVIEW`,
`CHANGES_REQUESTED`, `BLOCKED`, or `ACCEPTED`.

| Priority | ID | Vertical slice | Status | Dependency |
|---:|---|---|---|---|
| 1 | TASK-001 | Run this checkout through an isolated `novim-dev` command without changing installed `novim` | READY_FOR_REVIEW | None |
| 2 | TASK-002 | Inspect the working tree versus `HEAD` in a two-pane, mouse-resizable read-only workbench, including untracked files | PROPOSED | TASK-001 |
| 3 | TASK-003 | Browse project files with dot-folders hidden by default and a persistent settings toggle | PROPOSED | TASK-001 |
| 4 | TASK-004 | Open source files and move between file tree, changed files, and diff context | PROPOSED | TASK-002, TASK-003 |
| 5 | TASK-005 | Add local regression smoke tests for launcher, workbench layout, settings, and diff rendering | PROPOSED | TASK-002 through TASK-004 |
| 6 | TASK-006 | Package the local derivative and document a safe upstream sync procedure | PROPOSED | TASK-005 |

## Task notes

- `TASK-002` is intentionally read-only: it must not add stage, commit, push,
  discard, or other Git mutations.
- `TASK-003` must make the settings and dot-folder behavior observable without
  requiring a plugin manager.
- The workbench should remain usable with the existing local Neovim/runtime
  dependencies; new dependencies need a separate justification.
