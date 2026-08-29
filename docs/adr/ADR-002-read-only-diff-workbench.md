# ADR-002: Read-Only Diff Workbench Direction

- Status: `ACCEPTED FOR IMPLEMENTATION`
- Date: 2026-08-30
- Scope: initial product direction after user grill

## Decision

The first feature milestone after the isolated development launcher will focus
on inspecting local Git changes, not mutating the repository.

The target interface is a terminal workbench with:

- a Files view with a lazy left project tree and right source preview;
- a Diff view with a left changed-file list, middle old-file pane, and right
  new-file pane;
- mouse-draggable, width-constrained boundaries between visible panes;
- a settings panel with six built-in themes, dot-folder visibility, and a
  key-help section;
- no plugin manager requirement.

The initial Git surface is read-only. Status, history, and diff inspection are
allowed; stage, unstage, commit, push, merge, rebase, discard, and other Git
mutations are not part of the initial scope.

The first diff baseline is the working tree versus `HEAD`, including untracked
files. Display settings persist locally between launches. Dot-prefixed files
and folders are hidden by default and can be revealed through the settings
toggle; there is no first-slice allowlist.

The project browser shows only the working directory's immediate visible
entries at startup. Folder contents are scanned only when the folder is
double-clicked and the expansion state lasts only for the current session.
Entering Diff refreshes Git status and the selected diff. Text diffs are
always side-by-side with old content on the left and new content on the right;
removed lines are red and added lines are green, with no unified-mode toggle.

## Rationale

The primary need is to understand repository structure and verify changes in a
visual terminal interface. Repository mutation adds safety and scope concerns
without helping the first inspection workflow.

## Consequences

- `TASK-002` can be evaluated using screenshots/interaction checks and local
  diff fixtures without requiring commit or remote credentials.
- The UI must clearly distinguish source-on-disk from changed/diff views.
- Branch and historical-commit comparisons are deliberately deferred until
  after the first workbench slice.
- Plugin installation and plugin lifecycle are not hidden dependencies of the
  first workbench.
