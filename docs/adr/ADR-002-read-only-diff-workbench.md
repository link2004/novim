# ADR-002: Read-Only Diff Workbench Direction

- Status: `ACCEPTED FOR PLANNING`
- Date: 2026-08-27
- Scope: initial product direction after user grill

## Decision

The first feature milestone after the isolated development launcher will focus
on inspecting local Git changes, not mutating the repository.

The target interface is a terminal workbench with:

- a left project tree or changed-file list;
- a right source or readable diff view;
- a divider that can be widened or narrowed with the mouse;
- a settings menu/panel, initially including hide/show dot-prefixed files and
  folders such as `.vscode`;
- no plugin manager requirement.

The initial Git surface is read-only. Status, history, and diff inspection are
allowed; stage, unstage, commit, push, merge, rebase, discard, and other Git
mutations are not part of the initial scope.

## Rationale

The primary need is to understand repository structure and verify changes in a
visual terminal interface. Repository mutation adds safety and scope concerns
without helping the first inspection workflow.

## Consequences

- `TASK-002` can be evaluated using screenshots/interaction checks and local
  diff fixtures without requiring commit or remote credentials.
- The UI must clearly distinguish source-on-disk from changed/diff views.
- The exact comparison baseline and settings persistence behavior remain
  implementation decisions to resolve before `TASK-002` is issued.
- Plugin installation and plugin lifecycle are not hidden dependencies of the
  first workbench.
