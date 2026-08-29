# Current Task

Updated: 2026-08-29
Task ID: `TASK-003`
Status: `READY_FOR_REVIEW`
Delivery policy: `LIGHTWEIGHT`
Base branch: `main`
Task branch: `task/TASK-003-project-browser-settings`
Expected baseline: `794a7c6fe09abb335fb7c14273614a796b365631` (`origin/main`)
Pull request: `NOT_OPEN`
Remote checks: `OPTIONAL / NOT_RUN`

## Outcome

Add the next usable project-browsing slice to `novim-dev`: a visible local
project file browser whose dot-prefixed files and folders are hidden by
default, plus an in-app settings surface that reveals or hides them and
persists that choice locally between launches.

The browser is a read-only filesystem inspection surface. It must preserve the
accepted TASK-002 Git diff workbench and the isolated development runtime.

## Context

TASK-001 established the isolated `novim-dev` command and TASK-002 delivered
the read-only changed-file/diff workbench. The accepted product direction now
requires project browsing with a persistent dot-folder visibility setting.
Source-file opening and navigation between the project browser, changed-file
list, and diff context remain TASK-004 scope.

## In scope

- Add a project-file browser reachable from `novim-dev`.
- List regular project files and directories from the current project root.
- Hide dot-prefixed files and directories by default at every tree level.
- Provide a visible settings menu or panel with a dot-folder visibility toggle.
- Persist the setting locally between launches under the isolated development
  runtime/state paths.
- Refresh the browser after toggling the setting without requiring a plugin,
  network connection, or Git mutation.
- Keep TASK-002 changed-file/diff behavior and launcher isolation intact.

## Out of scope

- Opening source files or editing them from the project browser.
- Navigation between project files, changed files, and the diff preview; that is
  TASK-004.
- Git stage, unstage, commit, push, pull, merge, rebase, reset, checkout,
  discard, or any other repository mutation.
- A plugin manager, new third-party dependency, LSP, debugger, AI, or hosted
  service.
- Search, tabs/workspaces, file operations, project configuration discovery,
  or a full VS Code replacement.
- Changes to installed `/Users/mert/.local/share/novim` or the user's normal
  Neovim configuration.

## Acceptance criteria

- [x] Launching `novim-dev` in a fixture project shows regular files and
      directories in the project browser without network access or plugin
      installation.
- [x] Dot-prefixed files and directories, including nested dot-folders, are
      hidden by default while non-dot siblings remain visible.
- [x] The settings surface is visibly reachable from the workbench and
      exposes a dot-folder visibility toggle with an unambiguous state.
- [x] Enabling the toggle reveals dot-prefixed files and directories at every
      relevant tree level; disabling it hides them again without losing normal
      entries.
- [x] The visibility choice persists across a fresh `novim-dev` launch using
      the checkout's isolated state path.
- [x] Missing or malformed local settings fall back safely to hidden-by-default
      behavior without crashing or writing outside the isolated runtime.
- [x] Existing TASK-002 diff inspection, native mouse divider behavior, and
      read-only Git invariance remain intact.
- [x] No Git mutation action, network call, plugin-manager dependency, or
      installed-release modification is introduced.

## Decision guardrails

- Keep filesystem and settings operations local and read-only with respect to
  Git; do not infer project root by changing repository state.
- Apply the dot-prefix rule consistently to nested files and directories, with
  no first-slice allowlist.
- Default to hidden when the settings file is absent, invalid, or unreadable;
  handle persistence errors as visible non-fatal UI states.
- Store only the display preference under Neovim's isolated state/runtime path;
  never write credentials, source content, or private data into project docs.
- Preserve the TASK-002 workbench commands, native mouse behavior, minimum
  pane widths, and installed `novim` contract.
- Prefer existing Neovim/Lua capabilities. Any dependency addition requires an
  explicit justification and remains out of scope by default.

## Relevant areas

- `config/nvim/init.lua` — command and workbench integration.
- `config/nvim/lua/novim/workbench.lua` — existing two-pane workbench and
  settings entry point.
- `config/nvim/lua/novim/` — a focused browser/settings module may be added.
- `bin/novim-dev` — isolated `XDG_*` runtime paths that persistence must use.
- `docs/product/product.md`, `docs/architecture.md`, and
  `docs/adr/ADR-002-read-only-diff-workbench.md` — accepted boundaries.
- `docs/tasks/backlog.md`, `project-state.md`, and this record — workflow state.

## Required validation

- Create a temporary fixture project containing regular files/directories,
  top-level dot-files, and nested dot-folders with visible siblings.
- Launch `novim-dev` and inspect the browser's default listing and settings
  toggle; verify both show and hide states at nested levels.
- Start a fresh `novim-dev` process using the same isolated runtime and verify
  the selected setting persists; test absent and malformed settings behavior.
- Verify fixture Git status and diff bytes are unchanged before and after
  browser/settings interaction, and that no mutation control exists.
- Re-run `./tests/run_tests.sh`, `novim-dev --version`, installed
  `novim --version`, `git diff --check`, and complete diff/scope inspection.
- Keep local filesystem/UI evidence distinct from hosted, production,
  recovery, and customer-acceptance evidence.

## Blockers and dependencies

- No product decision is open for this slice.
- Dependency: TASK-002 is accepted on `origin/main` at
  `794a7c6fe09abb335fb7c14273614a796b365631`.
- No remote or hosted service is required for implementation.

## Implementation handoff

Status: `READY_FOR_REVIEW`
Candidate commit: `HEAD (handoff commit)`

### Summary of changes

- Added `config/nvim/lua/novim/settings.lua`: robust local persistence layer storing settings (such as `show_dotfiles`) under isolated runtime state (`stdpath("state")/novim_settings.json`). Missing, unreadable, or malformed settings fall back safely to default `{ show_dotfiles = false }` without crashing or throwing errors. `toggle_dotfiles()` strictly propagates persistence success/failure and retains previous value on write errors without false toggle reporting.
- Added `config/nvim/lua/novim/browser.lua`: read-only project file browser module scanning regular directories and files recursively using native `vim.uv.fs_scandir`. Hides dot-prefixed items at every tree level by default, and reveals them when `show_dotfiles` is enabled. Directory preview strictly filters dot-prefixed child entries based on `show_dotfiles` setting, preventing name leakage of hidden dot-folders/files, and accurately reflects visible item counts. Provides formatted read-only text file previews, directory summaries, and binary file detection.
- Added `config/nvim/lua/novim/settings_ui.lua`: centered interactive settings modal reachable via `s` or `:Settings`, exposing unambiguous toggle state (`[ ] OFF` / `[X] ON`), instant save, workbench refresh notification, and visible non-fatal error banner (`⚠ Failed to save settings`) when write operations fail.
- Updated `config/nvim/lua/novim/workbench.lua`: integrated two-pane layout with view modes (`files` and `diff`), active tab header, keyboard navigation (`1`/`2`/`s`/`r`/`j`/`k`/`Tab`/`q`), left click selection, native mouse divider resizing, diagnostic `get_state()`, and correct propagation of `show_dotfiles` to directory previews.
- Updated `config/nvim/init.lua`: launches `workbench.open({ view = "files" })` on `VimEnter` by default; exposes `:ProjectBrowser`, `:Files`, `:DiffWorkbench`, `:Workbench`, and `:Settings` commands; maps `<C-e>` / `<D-e>` for Project Browser and `<C-d>` / `<D-d>` for Diff Workbench.
- Updated `tests/test_workbench.lua`: expanded test suite from 6 to 14 unit and integration tests covering default hidden dotfiles, nested dot-folders, directory preview filtering (hidden vs revealed), settings toggle, settings write failure handling, persistence across fresh process launches, malformed fallback, view switching, file previews, and status/diff byte invariance.

### Files changed

- `config/nvim/lua/novim/settings.lua` (new)
- `config/nvim/lua/novim/browser.lua` (new)
- `config/nvim/lua/novim/settings_ui.lua` (new)
- `config/nvim/lua/novim/workbench.lua` (modified)
- `config/nvim/init.lua` (modified)
- `tests/test_workbench.lua` (modified)
- `docs/tasks/current-task.md` (modified)

### Validation commands and results

- `./tests/run_tests.sh`: 14/14 passed (`test_git_module_special_paths`, `test_workbench_close_editor_state`, `test_left_pane_mouse_selection_no_e21`, `test_mouse_divider_drag_and_status_invariance`, `test_non_git_directory`, `test_clean_repository`, `test_project_browser_default_hidden_dotfiles`, `test_settings_toggle_reveals_and_hides_dotfiles`, `test_settings_persistence_across_launches`, `test_settings_missing_or_malformed_fallback`, `test_settings_write_failure_handling`, `test_view_switching_and_header_tabs`, `test_project_browser_preview`, `test_project_browser_read_only_invariance`).
- `git diff --check`: passed cleanly.
- `bash -n bin/novim-dev tests/run_tests.sh`: passed cleanly.
- `./bin/novim-dev --version`: `novim-dev 0.1.7-dev (custom checkout)` / Neovim `v0.12.5`.
- `/Users/mert/.local/bin/novim --version`: `novim 0.1.7` (unchanged).
- Directory preview filtering probe: verified `src/` directory preview hides `.secret_module/` under default `show_dotfiles = false` and reveals it under `show_dotfiles = true`.
- Write failure probe: verified unwriteable settings path causes `toggle_dotfiles()` to return `false, err, false`, retains in-memory setting, and renders non-fatal error banner in UI.
- Multi-process persistence: verified fresh process launch restores `show_dotfiles = true` from isolated `$XDG_STATE_HOME`.
- Git invariance: verified byte-for-byte status (`git status --porcelain=v1 -z -uall`) and diff (`git diff HEAD`) invariance.

### Residual risks or known gaps

- None. Both review findings are resolved, covered by regression tests, and verified.
