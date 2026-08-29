# Current Task

Task ID: `TASK-007`
Status: `READY_FOR_REVIEW`
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

- [x] Initial Files view lists only immediate visible entries of the current
      root; no descendant file or directory is loaded or rendered before an
      expansion action.
- [x] A folder double-click expands it, scans only its immediate children,
      and renders those children with correct indentation and directory/file
      ordering.
- [x] A second double-click collapses that folder and removes all descendants
      from the visible list without changing files on disk.
- [x] A nested folder remains collapsed after its parent expands and can be
      expanded independently by double-click.
- [x] Dot-prefixed entries remain hidden or visible according to the existing
      persisted setting at root and nested levels.
- [x] Refresh preserves valid in-session expansion state, while a new
      workbench launch starts collapsed at the root.
- [x] Opening from a large/deep fixture remains responsive because startup
      performs no recursive browser traversal; the test suite observes the
      lazy boundary directly rather than relying only on a wall-clock budget.
- [x] Existing source preview/editing, read-only Git, isolated runtime,
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

Status: `READY_FOR_REVIEW`

### Change summary

- `config/nvim/lua/novim/browser.lua`: replaced the recursive `get_tree` walk
  (depth limit 15) with `get_immediate_entries(dir_path, rel_prefix, depth,
  show_dotfiles)`, which scans and sorts only the immediate visible entries of
  one directory (directories before files, case-insensitive). Dotfile
  filtering applies at every level; link/unknown types still resolve through
  `fs_stat`.
- `config/nvim/lua/novim/workbench.lua`: added session-only `expanded_dirs`
  state, `rebuild_project_view` (rebuilds the visible list from root entries
  plus expanded folders only), `toggle_dir_expansion` (expand on folder
  double-click; a second double-click collapses and removes all descendants),
  and an `is_symlink_cycle` guard that refuses expansion when a directory's
  real path appears among its own ancestors. `refresh()` and settings changes
  reuse the rebuild path, so in-session expansion survives refresh; `M.open`
  resets expansion state so a new launch starts collapsed. Stats now describe
  the currently visible list (`dot_count` counts visible dot entries). The
  left-pane `<2-LeftMouse>` mapping toggles folders and opens files as before.
- Defect fix required by the "new launch starts collapsed" criterion: the
  workbench previously failed with `E95: Buffer with this name already
  exists` when reopened within the same Neovim session. `fresh_buffer()` now
  removes a leftover `[Workbench - Navigation]`/`[Workbench - Preview]`
  scratch buffer before naming a new one (used by `M.open` and
  `render_right_pane`).
- Tests: rewrote `test_project_browser_default_hidden_dotfiles` and
  `test_settings_toggle_reveals_and_hides_dotfiles` for the lazy model and
  added five TASK-007 tests covering root-only initial state, expand/collapse
  with disk invariance, nested independent expansion, refresh preservation
  plus new-launch reset, the structural large-fixture lazy boundary, and
  symlink-cycle refusal. The project fixture gained `src/nested/deep.lua`.
- `tests/test_smoke.lua`: `browser.get_tree` usage replaced with
  `get_immediate_entries`; `dot_count` assertions follow the new
  visible-entry semantics.
- `docs/architecture.md`: the workbench baseline section now describes the
  lazy root-only scan, session-only expansion, and symlink-loop refusal.

### Files changed

- `config/nvim/lua/novim/browser.lua`
- `config/nvim/lua/novim/workbench.lua`
- `tests/test_workbench.lua`
- `tests/test_smoke.lua`
- `docs/architecture.md`
- `docs/tasks/current-task.md`
- `docs/project.json`

### Validation

- `bin/novim-dev --headless -c "luafile tests/test_workbench.lua"`: 27/27 PASS
  (22 existing tests updated where they scanned recursively, 5 added).
- `./tests/run_tests.sh`: 27/27 integration tests, full offline package
  suite, and 6/6 smoke tests PASS. The smoke runner's product-source
  invariance check compares tracked `bin/` and `config/` content against
  `HEAD`, so the full suite is re-run at the handoff commit for the final
  green run.
- `bash -n` on `bin/novim-dev`, `bin/novim-dev-package`,
  `tests/run_tests.sh`, `tests/run_smoke_tests.sh`, and
  `tests/run_package_tests.sh`: PASS.
- `./bin/novim-dev --version` reports `0.1.7-dev` on Neovim `v0.12.5`; the
  installed `novim --version` reports `0.1.7` unchanged: PASS.
- `python3 -m json.tool docs/project.json`: PASS. `git diff --check`: PASS.

### Acceptance evidence

- Root-only initial state: `test_lazy_root_only_initial_state` asserts exactly
  4 visible root entries at depth 0, no expanded folders, and no descendant
  text rendered. `test_large_fixture_startup_stays_lazy` observes the lazy
  boundary structurally on a 12-branch/4-level fixture: startup lists 12 root
  entries, expanding one branch reveals exactly its 9 immediate children, and
  deeper descendants stay unloaded (no wall-clock budget involved).
- Expand/collapse: `test_folder_double_click_expand_and_collapse` proves
  depth-1 children with correct directories-first ordering, collapse
  restoring the root-only list, and `filereadable`/`isdirectory` disk
  invariance.
- Nested independence: `test_nested_folder_expands_independently` proves a
  nested folder stays collapsed after the parent expands, expands
  independently to depth 2, and disappears when the parent collapses.
- Dotfile setting: root- and nested-level filtering is asserted in
  `test_project_browser_default_hidden_dotfiles`,
  `test_settings_toggle_reveals_and_hides_dotfiles`, and the smoke suite.
- Refresh vs new launch: `test_refresh_preserves_expansion_new_launch_resets`.
- Preserved contracts: byte-for-byte read-only Git invariance, source
  preview/editing handoff with unsaved-buffer preservation, isolated runtime
  paths, installed-release independence, and no-default-network checks all
  pass in the existing suites.

### Residual risks and known gaps

- `project_stats` now describes the visible list only; recursive totals are
  intentionally no longer computed at startup.
- Expanding the same real directory through two different symlink aliases is
  allowed (aliasing is not a cycle); true loops are refused by the ancestor
  real-path check.
- Expansion rebuild rescans expanded folders on each toggle/refresh; cost is
  bounded by the visible tree, not the whole project.

### Candidate commit

Candidate: HEAD (handoff commit) on `task/TASK-007-lazy-project-browser`.
