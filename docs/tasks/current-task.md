# Current Task

Updated: 2026-08-29
Task ID: `TASK-004`
Status: `PLANNED`
Delivery policy: `LIGHTWEIGHT`
Base branch: `main`
Task branch: `task/TASK-004-source-navigation`
Expected baseline: `6a9be23522c43110dd4c4053f67ab22c8586d4b9` (`origin/main`)
Pull request: `NOT_OPEN`
Remote checks: `OPTIONAL / NOT_RUN`

## Outcome

Extend the accepted novim-dev workbench so a user can open a selected project
source file for reading/editing and move predictably among the project browser,
changed-file list, and diff context without losing the existing two-pane layout.

## Context

TASK-001 established the isolated `novim-dev` command. TASK-002 delivered the
read-only Git diff workbench, and TASK-003 delivered the project browser with
persistent dot-folder visibility settings. The next usable slice is source-file
opening and navigation across the workbench views.

## In scope

- Open a selected regular project file from the project browser in the existing
  Neovim editing surface while preserving normal save, undo, and mouse behavior.
- Keep the project browser, changed-file list, and diff preview reachable from
  the workbench without losing the current selection or project root
  unexpectedly.
- Make navigation between the Files and Git Diff views explicit and usable by
  keyboard and existing mouse interactions.
- Keep directory selection as a read-only inspection/preview action; only a
  regular file selection may open file content in the editor.
- Preserve the TASK-003 dotfile visibility setting, including nested filtering,
  persistence, and safe write-error behavior.

## Out of scope

- Git stage, unstage, commit, push, pull, merge, rebase, reset, checkout,
  restore, discard, or any other repository mutation.
- A new plugin manager, third-party runtime dependency, LSP, debugger, AI, or
  hosted service.
- Search, tabs/workspaces, project configuration discovery, file operations,
  or a full VS Code replacement.
- Changing the accepted Git diff baseline of working tree versus `HEAD`, the
  inclusion of untracked files, or native mouse divider behavior.
- Changes to installed `/Users/mert/.local/share/novim` or the user's normal
  Neovim configuration.

## Acceptance criteria

- [ ] Selecting a regular visible project file opens its content in the normal
      Neovim editing surface without a plugin or network connection.
- [ ] Selecting a directory keeps the right pane in read-only directory
      inspection and does not attempt to open a directory as a file.
- [ ] The user can move from Files to Git Diff and back using the existing
      workbench controls, with the correct pane content and active tab rendered.
- [ ] Selecting a changed file renders its diff against `HEAD`, and returning
      to Files keeps the project browser root and dotfile setting intact.
- [ ] Existing dotfile hidden/revealed behavior and persistent settings remain
      intact across refreshes and fresh `novim-dev` launches.
- [ ] Existing TASK-002 read-only Git behavior, untracked-file diff rendering,
      native mouse selection, divider resizing, and minimum widths remain intact.
- [ ] No Git mutation action, network call, plugin-manager dependency, or
      installed-release modification is introduced.

## Decision guardrails

- Keep source opening local and compatible with the current Neovim editing
  model; do not silently replace the user's current buffer or unsaved layout.
- Preserve the read-only status of navigation, directory previews, and Git
  inspection. Opening a source file may use the existing editor's normal edit
  and save behavior, but must not mutate Git state.
- Preserve `show_dotfiles` as the single visibility preference and pass it
  consistently through refresh, selection, and preview paths.
- Keep the workbench usable when the current directory is not a Git repository;
  Files navigation must not depend on Git availability.
- Prefer existing Neovim/Lua capabilities. Any dependency addition requires an
  explicit justification and remains out of scope by default.

## Relevant areas

- `config/nvim/lua/novim/workbench.lua` — view switching, selection, panes, and
  editor handoff.
- `config/nvim/lua/novim/browser.lua` — project entries and preview behavior.
- `config/nvim/lua/novim/settings.lua` and `settings_ui.lua` — preserved setting
  contract and refresh callback behavior.
- `config/nvim/init.lua` — existing editor shortcuts and workbench commands.
- `tests/test_workbench.lua` — regression fixtures and read-only invariance.
- `docs/architecture.md`, `docs/product/product.md`, and accepted completed
  task records — preserved contracts and scope context.

## Required validation

- Create a temporary fixture project containing regular text files,
  directories, visible siblings, and dot-prefixed entries.
- Launch `novim-dev`, open a regular file from Files, select a directory, switch
  to Git Diff, select a changed/untracked file, and return to Files; inspect
  pane content and active-tab state.
- Verify unsaved editor content and existing editor layout are not lost when
  opening or closing the workbench.
- Re-run the dotfile hidden/revealed, persistence, malformed-settings, and
  write-failure checks from TASK-003.
- Verify fixture Git status and diff bytes are unchanged after all navigation
  and source-opening interactions.
- Re-run `./tests/run_tests.sh`, `novim-dev --version`, installed
  `novim --version`, `git diff --check`, and complete diff/scope inspection.
- Keep local filesystem/UI evidence distinct from hosted, production,
  recovery, and customer-acceptance evidence.

## Blockers and dependencies

- No product decision is open for this bounded slice.
- Dependencies: TASK-002 and TASK-003 are accepted on `origin/main` at
  `6a9be23522c43110dd4c4053f67ab22c8586d4b9`.
- No remote or hosted service is required for implementation.

## Implementation handoff

Not started. Use `$stateless-implementer` on the recorded isolated branch and
stop at `READY_FOR_REVIEW` with a local validation summary.
