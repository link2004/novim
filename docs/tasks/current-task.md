# Current Task

Task ID: `TASK-007`
Status: `PLANNED`
Delivery policy: `LIGHTWEIGHT`
Base branch: `main`
Task branch: `task/TASK-007-lazy-project-browser`
Expected baseline: `33864f5d411b38c851af0401fdbf9919e1a32dbc` (`origin/main`)
Pull request: `NOT_OPEN`

## Outcome

Make `novim-dev` open quickly from large directories by replacing recursive
startup project scanning with a root-only lazy browser. Show descendants only
when the user double-clicks a folder, and keep expansion state for the current
session without persisting it.

## Context

The current `workbench.refresh()` calls `browser.get_tree()` synchronously and
recursively, with a depth limit of 15. Opening from a large directory can
block the Neovim event loop before the workbench becomes usable. The current
browser also renders a flattened recursive tree, so it cannot defer work until
a folder is opened.

## In scope

- Add a browser data path that reads and sorts only the immediate entries of a
  requested directory.
- Render only visible root entries at initial workbench open. Apply the
  existing hidden-dotfile setting at every level.
- Track expanded directories in workbench memory. On folder double-click,
  scan and reveal only that folder's immediate children; nested folders remain
  collapsed until explicitly expanded.
- On folder double-click again, collapse it and remove all descendants from
  the visible list.
- Keep expansion state during a refresh within the same session when the
  corresponding folders still exist; reset it on a new workbench launch.
- Preserve single-click selection, right-pane directory/file preview, regular
  file editing handoff, selection bounds, sorting, symlink-cycle protection,
  and read-only Git behavior.
- Add deterministic fixture tests proving that descendants are absent before
  expansion and appear only after the relevant folder is expanded.

## Out of scope

- Themes, settings key-help content, settings close behavior, and pane-drag
  implementation; these belong to TASK-008.
- Three-area side-by-side Git diff rendering and diff-entry refresh; these
  belong to TASK-009.
- Git mutation, network access, plugin installation, persistent expansion
  state, file watching, background polling, and installed `novim` changes.

## Acceptance criteria

- [ ] Initial Files view lists only immediate visible entries of the current
      root; no descendant file or directory is loaded or rendered before an
      expansion action.
- [ ] A folder double-click expands it, scans only its immediate children,
      and renders those children with correct indentation and directory/file
      ordering.
- [ ] A second double-click collapses that folder and removes all descendants
      from the visible list without changing files on disk.
- [ ] A nested folder remains collapsed after its parent expands and can be
      expanded independently by double-click.
- [ ] Dot-prefixed entries remain hidden or visible according to the existing
      persisted setting at root and nested levels.
- [ ] Refresh preserves valid in-session expansion state, while a new
      workbench launch starts collapsed at the root.
- [ ] Opening from a large/deep fixture remains responsive because startup
      performs no recursive browser traversal; the test suite observes the
      lazy boundary directly rather than relying only on a wall-clock budget.
- [ ] Existing source preview/editing, read-only Git, isolated runtime,
      installed-release, and no-default-network contracts remain intact.

## Decision guardrails

- Keep the implementation self-contained in the bundled Neovim configuration;
  do not add a plugin manager or third-party dependency.
- Use explicit relative paths and preserve safe symlink-cycle handling. Do not
  follow a directory recursively unless its visible parent was expanded.
- Keep all Git commands read-only and leave the working tree untouched.
- Preserve the current dotfile setting file and isolated `novim-dev` runtime
  paths.
- Do not modify the installed `novim` command, its data directory, or normal
  Neovim configuration.
- Make no hosted, production, recovery, or customer-acceptance claim from
  local fixture evidence.

## Relevant areas

- `config/nvim/lua/novim/browser.lua` — immediate-directory scan and entry
  model.
- `config/nvim/lua/novim/workbench.lua` — visible tree state, render path,
  refresh behavior, and mouse mappings.
- `config/nvim/lua/novim/settings.lua` — existing dotfile setting contract.
- `tests/test_workbench.lua` and `tests/test_smoke.lua` — fixture and runtime
  regression coverage.

## Required validation

- Add and run unit/integration coverage for root-only initial state,
  expansion/collapse, nested expansion, dotfile filtering, and refresh state.
- Run the full local suite with `./tests/run_tests.sh` and the relevant smoke
  checks from a large/deep temporary fixture.
- Run Lua/shell syntax checks as applicable, both version checks, and
  `git diff --check`.
- Verify the candidate diff contains no installed-release, network, Git
  mutation, credential, or unrelated feature changes.

## Blockers and dependencies

- No product decision is open for this slice.
- Dependency: TASK-006 is accepted on `origin/main` at `33864f5`.
- Follow-up slices TASK-008 and TASK-009 remain proposed and must not be
  implemented as part of this task.

## Implementation handoff

Status: `PLANNED`

Implement on `task/TASK-007-lazy-project-browser`, then stop at a local
handoff for orchestrator review. Do not push, open, or merge a PR as the
implementer.
