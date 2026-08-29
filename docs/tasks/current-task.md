# Current Task

Updated: 2026-08-29
Task ID: `TASK-002`
Status: `READY_FOR_REVIEW`
Delivery policy: `LIGHTWEIGHT`
Base branch: `main`
Task branch: `task/TASK-002-diff-workbench`
Expected baseline: `12327b78049e1348df858b589baf669ba451c090` (`origin/main`)
Pull request: `NOT_OPEN`
Remote checks: `OPTIONAL / NOT_RUN`

## Outcome

Create the first usable read-only Git diff workbench inside `novim-dev`: a
two-pane terminal interface where the left pane lists relevant changed files
and the right pane shows the selected file's diff or content. The divider must
be draggable with the mouse so both panes can be widened or narrowed.

The workbench compares the working tree with `HEAD` and includes untracked
files. It is an inspection surface only; it must not expose or perform Git
mutations.

## Context

The product direction is a VS Code-like terminal workbench for code and local
Git review. TASK-001 established an isolated `novim-dev` launch path, and is
accepted on `origin/main`. This task delivers the smallest observable diff
review slice before persistent settings and broader file navigation.

## In scope

- Add a workbench entry point reachable through `novim-dev`.
- Discover the repository's changed tracked files relative to `HEAD`.
- Include untracked files in the changed-file view.
- Provide a left changed-file or compact project-file pane and a right source or
  diff pane.
- Show the selected tracked file's working-tree diff against `HEAD`.
- Show an untracked file as a readable new-file diff/content view without
  requiring it to be staged.
- Make the pane divider draggable with the mouse, with sensible minimum widths
  so either pane remains usable.
- Preserve the isolated launcher/runtime behavior from TASK-001.
- Keep Git behavior read-only and local.

## Out of scope

- Stage, unstage, commit, push, pull, merge, rebase, reset, checkout, discard,
  or any other Git mutation.
- Branch or historical-commit comparison; the only baseline is `HEAD`.
- Persistent settings or the dot-folder visibility toggle; those belong to
  TASK-003.
- A plugin manager, new third-party plugin dependency, LSP, debugger, AI, or
  hosted service.
- A full file explorer, search system, tabs/workspaces, or release packaging.
- Changes to the installed `/Users/mert/.local/share/novim` release.

## Acceptance criteria

- [x] Launching `novim-dev` in a fixture Git repository opens the workbench
      without requiring a network connection or a plugin installation.
- [x] The left pane identifies changed tracked files relative to `HEAD` and
      includes at least modified and untracked fixture files.
- [x] Selecting a tracked file shows its working-tree diff against `HEAD` in
      the right pane, with enough context to identify additions and deletions.
- [x] Selecting an untracked file shows its complete readable new-file view or
      an equivalent all-additions diff without staging the file.
- [x] Dragging the divider with the mouse changes the left/right pane widths in
      both directions and respects minimum usable widths.
- [x] The workbench exposes no action that stages, commits, pushes, discards,
      or otherwise mutates Git state; opening and quitting it leaves the fixture
      repository status unchanged.
- [x] Existing launcher isolation remains intact: `novim-dev` still uses this
      checkout's configuration/runtime paths and installed `novim` remains
      unchanged.
- [x] The implementation introduces no plugin-manager or new third-party
      runtime dependency and does not modify unrelated upstream site files.

## Decision guardrails

- Prefer Neovim/Lua and existing repository/runtime capabilities; justify any
  new dependency in the task diff before adding it.
- Treat subprocess errors, non-Git directories, missing `HEAD`, deleted files,
  and binary files as explicit UI states rather than silently mutating or
  dropping repository data.
- Quote or otherwise safely pass repository paths to local Git commands; do not
  build shell commands from untrusted path text.
- Keep the initial interaction model small and deterministic. Do not implement
  settings persistence or future branch comparisons as incidental additions.
- Preserve MIT and third-party attribution notices.

## Relevant areas

- `bin/novim-dev` — isolated development entry point.
- `config/nvim/init.lua` — current configuration and UI integration point.
- `config/nvim/pack/` — existing bundled runtime; do not add dependencies here
  for this task without explicit justification.
- `docs/product/product.md`, `docs/architecture.md`, and
  `docs/adr/ADR-002-read-only-diff-workbench.md` — accepted product and
  architecture boundaries.
- `docs/tasks/backlog.md`, `project-state.md`, and this record — workflow state
  that must remain consistent.

## Required validation

- Create a temporary fixture repository with a committed baseline, one modified
  tracked file, one untracked file, and (if supported) a deleted file.
- Run the workbench against that fixture and verify the changed-file list and
  selected-file views against direct read-only `git diff`/`git status` output.
- Manually smoke-test mouse divider dragging in both directions and verify the
  minimum-width behavior.
- Verify before and after that the fixture's `git status --short` is identical
  and that no stage/commit/discard control is present.
- Verify `novim-dev --version` and the existing installed `novim --version`.
- Inspect `git status`, `git diff --check`, and the complete task diff for
  generated runtime files or unrelated changes.

## Blockers and dependencies

- No product decision is open for this slice.
- Dependency accepted: TASK-001 is merged to `origin/main`.
- No remote or hosted service is required for implementation.

## Implementer handoff

Status: `READY_FOR_REVIEW`
Candidate commit: `HEAD (handoff commit)`

### Summary of changes

1. **NUL-delimited Git status parsing (`config/nvim/lua/novim/git.lua`)**:
   - Switched to `git status --porcelain=v1 -z -uall` with NUL (`\0`) chunking via `vim.system`.
   - Exact byte preservation for filenames containing literal arrows (`arrow -> name.txt`), double quotes (`quote"name.txt`), tabs (`tab\tname.txt`), spaces, and Unicode.
   - Two-part rename/copy handling (`path\0orig_path\0`) properly extracted.
   - Diff generation executes with table arguments avoiding shell injection or quoting corruption.

2. **Safe workbench lifecycle and editor preservation (`config/nvim/lua/novim/workbench.lua`)**:
   - Command-opened workbench (from active buffer/session) opens in a dedicated tabpage (`tabnew`). Closing via `q` or `close()` calls `tabclose`, returning user to their exact previous buffer, split layout, and unsaved edits without `E37` errors or unintended `:qa`.
   - Startup-opened workbench (`argc == 0`) quits safely via `confirm qa` if unsaved buffers exist or `qa` if clean.
   - Programmatic close cleans up state without exiting Neovim.

3. **Automated test suite and invariance validation (`tests/test_workbench.lua`)**:
   - `test_git_module_special_paths`: verifies detection and readable diff previews for literal arrows, quotes, tabs, Unicode, renames, and binary files.
   - `test_workbench_close_editor_state`: verifies closing from an unsaved buffer preserves the buffer and its modified flag without `E37`.
   - `test_mouse_divider_drag_and_status_invariance`: exercises real mouse divider dragging in both directions, enforces `winminwidth >= 15`, and verifies byte-for-byte before/after invariance of `git status --porcelain=v1 -z -uall` and `git diff HEAD`.
   - `test_non_git_directory` and `test_clean_repository`: verifies explicit UI empty states.

### Files changed

- `config/nvim/lua/novim/git.lua`: NUL-delimited status parsing and safe diff execution.
- `config/nvim/lua/novim/workbench.lua`: Tabpage lifecycle management and safe close behavior.
- `tests/test_workbench.lua`: Regression test suite for paths, editor state, mouse dragging, and Git invariance.
- `docs/tasks/current-task.md`: Task status, evidence table, and review resolution records.

### Validation commands and results

1. `./tests/run_tests.sh`
   - Output: `5 total, 5 passed, 0 failed` (`test_git_module_special_paths`, `test_workbench_close_editor_state`, `test_mouse_divider_drag_and_status_invariance`, `test_non_git_directory`, `test_clean_repository`).
2. `git diff --check` and `git diff --check origin/main...HEAD`
   - Output: Clean (0 whitespace errors, 0 trailing blank lines).
3. `./bin/novim-dev --version`
   - Output: `novim-dev 0.1.7-dev (custom checkout)` powered by `NVIM v0.12.5`.
4. `/Users/mert/.local/bin/novim --version`
   - Output: `novim 0.1.7` (installed version unchanged).
5. Runtime isolation check (`./bin/novim-dev --headless` querying stdpath):
   - Config: `/Users/mert/novim-custom/config/nvim`
   - Data: `/Users/mert/novim-custom/.dev-data/nvim`
   - State: `/Users/mert/novim-custom/.dev-state/nvim`
   - Cache: `/Users/mert/novim-custom/.dev-cache/nvim`

### Acceptance criteria evidence

| Criterion | Result | Evidence |
|---|---|---|
| Launching `novim-dev` opens workbench without network/plugin | PASS | `./bin/novim-dev --headless` initializes workbench with 0 plugins and 0 network requests |
| Left pane lists changed files relative to `HEAD` (modified, untracked, deleted) | PASS | Verified in `test_git_module_special_paths`; includes literal arrows, quotes, tabs, Unicode, renames |
| Selecting tracked file shows working-tree diff against `HEAD` with additions/deletions | PASS | Verified in test suite; shows `+MODIFIED`, `-deleted` lines for tracked files |
| Selecting untracked file shows readable all-additions diff without staging | PASS | Verified in `test_git_module_special_paths`; diff against `/dev/null` for arrows, quotes, tabs, Unicode |
| Dragging divider changes pane widths in both directions with min width | PASS | Verified in `test_mouse_divider_drag_and_status_invariance`; mouse drag events and `winminwidth >= 15` |
| Workbench exposes no mutation action; status remains unchanged | PASS | Verified in `test_mouse_divider_drag_and_status_invariance`; `git status -z` and `git diff HEAD` byte-for-byte identical before/after |
| Launcher isolation intact; installed `novim` unchanged | PASS | `novim-dev` uses `.dev-*` directories; `/Users/mert/.local/bin/novim` reports `0.1.7` |
| No plugin manager or third-party dependency; upstream site files untouched | PASS | Zero new dependencies added; no files outside `config/`, `tests/`, `docs/` modified |

### Residual risks or known gaps

- Dot-folder visibility settings and persistent preferences will be implemented in TASK-003.
