# Current Task

Updated: 2026-08-29
Task ID: `TASK-003`
Status: `PLANNED`
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

- [ ] Launching `novim-dev` in a fixture project shows regular files and
      directories in the project browser without network access or plugin
      installation.
- [ ] Dot-prefixed files and directories, including nested dot-folders, are
      hidden by default while non-dot siblings remain visible.
- [ ] The settings surface is visibly reachable from the workbench and
      exposes a dot-folder visibility toggle with an unambiguous state.
- [ ] Enabling the toggle reveals dot-prefixed files and directories at every
      relevant tree level; disabling it hides them again without losing normal
      entries.
- [ ] The visibility choice persists across a fresh `novim-dev` launch using
      the checkout's isolated state path.
- [ ] Missing or malformed local settings fall back safely to hidden-by-default
      behavior without crashing or writing outside the isolated runtime.
- [ ] Existing TASK-002 diff inspection, native mouse divider behavior, and
      read-only Git invariance remain intact.
- [ ] No Git mutation action, network call, plugin-manager dependency, or
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

Status: `PLANNED`
Candidate commit: `NOT_STARTED`

The implementer must work only on `task/TASK-003-project-browser-settings`,
preserve unrelated changes, and stop at `READY_FOR_REVIEW` with a local
handoff commit and complete acceptance evidence.
