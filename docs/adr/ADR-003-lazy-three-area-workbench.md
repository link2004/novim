# ADR-003: Lazy Project Tree and Three-Area Diff Layout

- Status: `ACCEPTED FOR IMPLEMENTATION`
- Date: 2026-08-30
- Scope: next workbench milestone

## Decision

Implement the next workbench milestone as three ordered slices:

1. The Files view starts with only immediate visible root entries. Descendant
   directories are scanned only after a folder is double-clicked. Expansion
   state is kept in memory for the current session and is not persisted.
2. Settings add six built-in themes, retaining Tokyo Night as the default,
   plus an accurate key-help section. Settings close through `Esc` must be
   immediate. Pane boundaries must support reliable mouse dragging with
   minimum widths.
3. The Diff view keeps the changed-file list on the left and renders the
   selected text file in two code panes: old content in the middle and new
   content on the right. Removed lines are red and added lines are green.
   Entering Diff refreshes its Git data; continuous polling is not required.

The workbench remains local and read-only. No plugin dependency, Git mutation,
network action, installed-release write, or unified-diff fallback is added.

## Rationale

Recursive startup scanning is the observed cause of slow launches from large
directories. Keeping the file list available while dedicating two panes to
the selected diff preserves navigation and matches the requested VS Code-like
review flow.

## Consequences

- The first implementation task can be validated without Git diff layout
  assumptions and should remove the startup bottleneck independently.
- Theme names and colors are an application-owned built-in palette set; no
  external theme/plugin installation is needed.
- Binary, deleted, renamed, and untracked files must retain readable status
  handling in the three-area diff view without pretending binary content is
  text.
