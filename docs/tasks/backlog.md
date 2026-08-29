# Backlog

Updated: 2026-08-30

Statuses: `PROPOSED`, `PLANNED`, `IN_PROGRESS`, `READY_FOR_REVIEW`,
`CHANGES_REQUESTED`, `BLOCKED`, or `ACCEPTED`.

| Priority | ID | Vertical slice | Status | Dependency |
|---:|---|---|---|---|
| 1 | TASK-001 | Run this checkout through an isolated `novim-dev` command without changing installed `novim` | ACCEPTED | None |
| 2 | TASK-002 | Inspect the working tree versus `HEAD` in a two-pane, mouse-resizable read-only workbench, including untracked files | ACCEPTED | TASK-001 (accepted) |
| 3 | TASK-003 | Browse project files with dot-folders hidden by default and a persistent settings toggle | ACCEPTED | TASK-002 (accepted) |
| 4 | TASK-004 | Open source files and move between file tree, changed files, and diff context | ACCEPTED | TASK-002, TASK-003 (accepted) |
| 5 | TASK-005 | Add local regression smoke tests for launcher, workbench layout, settings, and diff rendering | ACCEPTED | TASK-002 through TASK-004 (accepted) |
| 6 | TASK-006 | Package the local derivative and document a safe upstream sync procedure | ACCEPTED | TASK-005 (accepted) |
| 7 | TASK-007 | Start quickly with a root-only lazy project browser and session-only folder expansion | ACCEPTED | TASK-006 (accepted) |
| 8 | TASK-008 | Add six built-in themes, settings key help, immediate settings close, and reliable mouse pane resizing | PLANNED | TASK-007 (accepted) |
| 9 | TASK-009 | Render a three-area side-by-side read-only Git diff with refresh on entry | PROPOSED | TASK-008 (planned) |

TASK-001 through TASK-007 are accepted. TASK-008 is the only actionable
current task; TASK-009 remains proposed until TASK-008 is accepted.

## Task notes

- `TASK-002` is intentionally read-only: it must not add stage, commit, push,
  discard, or other Git mutations.
- `TASK-003` must make the settings and dot-folder behavior observable without
  requiring a plugin manager.
- The workbench should remain usable with the existing local Neovim/runtime
  dependencies; new dependencies need a separate justification.
- `TASK-007` must remove recursive project scanning from startup while
  retaining safe dot-folder filtering and read-only source preview behavior.
- `TASK-008` must use application-owned palettes and actual mappings; it must
  not introduce a plugin manager or hide a slow synchronous refresh behind the
  settings modal.
- `TASK-009` must keep the changed-file list visible beside old/new panes and
  preserve readable handling for binary, deleted, renamed, and untracked
  files.
