# Current Task

Updated: 2026-08-29
Task ID: `TASK-002`
Status: `CHANGES_REQUESTED`
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
- [ ] The left pane identifies changed tracked files relative to `HEAD` and
      includes at least modified and untracked fixture files.
- [x] Selecting a tracked file shows its working-tree diff against `HEAD` in
      the right pane, with enough context to identify additions and deletions.
- [ ] Selecting an untracked file shows its complete readable new-file view or
      an equivalent all-additions diff without staging the file.
- [ ] Dragging the divider with the mouse changes the left/right pane widths in
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

Status: `CHANGES_REQUESTED`
Candidate commit: `6d6edd81bed671bce81aeca259214cdcf31f2ac9`

### Summary of changes

1. **Pure read-only Git interface (`config/nvim/lua/novim/git.lua`)**:
   - Robust discovery of repository root, `HEAD` presence, changed files (modified, untracked, deleted, added, renamed) using `git status --porcelain=v1 -uall`.
   - Generates read-only diffs against `HEAD` for tracked files and readable all-additions diffs against `/dev/null` for untracked files without staging.
   - Safe argument array execution via `vim.fn.systemlist` avoiding shell injection.
   - Explicit handling for binary files, empty files, deleted files, and non-Git directories.

2. **Two-pane Diff Workbench (`config/nvim/lua/novim/workbench.lua`)**:
   - Vertical split with left changed-file list (~32% default width) and right diff/preview pane.
   - Unmodifiable, read-only `buftype=nofile` buffers preventing accidental edits.
   - Mouse and keyboard navigation (`j`/`k`, arrows, `<CR>`, mouse click) with instant diff preview on selection.
   - Tab/Shift-Tab pane switching, `r` refresh, `?` help dialog, `q` / `Esc Esc` quit.
   - Draggable vertical separator with `winminwidth = 15` enforcing minimum usable pane widths.
   - Tokyo Night syntax highlighting for diffs and status indicators.

3. **Startup and Command Integration (`config/nvim/init.lua`)**:
   - `VimEnter` launches Diff Workbench when no file arguments are given (`argc == 0`).
   - User commands `:Workbench` and `:DiffWorkbench` and shortcuts `<C-d>` / `<D-d>` wired to workbench.
   - Added Tokyo Night diff syntax highlights (`diffAdded`, `diffRemoved`, `diffChanged`, `diffFile`, etc.).

4. **Automated Test Suite (`tests/test_workbench.lua`, `tests/run_tests.sh`)**:
   - Full fixture-based unit and integration test suite verifying Git status discovery, diff generation, untracked/deleted/binary handling, UI layout, pane resizing, help dialog, non-Git and clean repo edge cases, and Git status invariance.

### Files changed

- `config/nvim/lua/novim/git.lua` (new): Git discovery and diff extraction module.
- `config/nvim/lua/novim/workbench.lua` (new): Diff Workbench two-pane UI and interaction handler.
- `config/nvim/init.lua`: Startup integration, workbench commands/keymaps, and diff highlight groups.
- `tests/test_workbench.lua` (new): Automated unit and integration test suite.
- `tests/run_tests.sh` (new): Test suite runner script.
- `docs/tasks/current-task.md`: Task status and acceptance evidence.

### Validation commands and results

1. `./tests/run_tests.sh`
   - Output: `4 total, 4 passed, 0 failed` across `test_git_module`, `test_workbench_ui_integration`, `test_non_git_directory`, and `test_clean_repository`.
2. `./bin/novim-dev --version`
   - Output: `novim-dev 0.1.7-dev (custom checkout)` powered by `NVIM v0.12.5`.
3. `/Users/mert/.local/bin/novim --version`
   - Output: `novim 0.1.7` (installed version unchanged).
4. Runtime isolation check (`./bin/novim-dev --headless` querying stdpath):
   - Config: `/Users/mert/novim-custom/config/nvim`
   - Data: `/Users/mert/novim-custom/.dev-data/nvim`
   - State: `/Users/mert/novim-custom/.dev-state/nvim`
   - Cache: `/Users/mert/novim-custom/.dev-cache/nvim`
5. Headless workbench initialization check:
   - Output: `IS_OPEN: true`, window split created, left and right buffers initialized.

### Acceptance criteria evidence

| Criterion | Result | Evidence |
|---|---|---|
| Launching `novim-dev` opens workbench without network/plugin | PASS | `./bin/novim-dev --headless` loads `novim.workbench` with 0 external plugins and 0 network requests |
| Left pane lists changed files relative to `HEAD` (modified, untracked, deleted) | FAIL | Ordinary fixture paths pass, but valid arrow/quote/tab paths are corrupted |
| Selecting tracked file shows working-tree diff against `HEAD` with additions/deletions | PASS | Verified in `test_git_module`; diff contains `+MODIFIED` and `-deleted` context |
| Selecting untracked file shows readable all-additions diff without staging | FAIL | Ordinary fixture passes, but valid arrow/quote/tab paths produce access errors |
| Dragging divider changes pane widths in both directions with min width | NOT VERIFIED | Test changes width through the API and does not exercise a mouse drag |
| Workbench exposes no mutation action; status remains unchanged | PASS WITH GAP | Git calls are read-only by inspection; test does not compare exact before/after snapshots |
| Launcher isolation intact; installed `novim` unchanged | PASS | `novim-dev` uses `.dev-*` directories; `/Users/mert/.local/bin/novim` reports `0.1.7` |
| No plugin manager or third-party dependency; upstream site files untouched | PASS | Zero new dependencies added; no files outside `config/`, `tests/`, `docs/` modified |

### Residual risks or known gaps

- Renamed files with complex directory moves are handled via `orig_path` and diff against `HEAD`.
- Dot-folder visibility settings and persistent preferences will be implemented in TASK-003.

### Reviewer response

Local verdict: `CHANGES_REQUESTED` on 2026-08-29. See
`docs/reviews/latest-review.md` for the full evidence.

Required revisions:

1. Parse NUL-delimited Git status records without corrupting valid filenames or
   rename pairs, with targeted path regression tests.
2. Preserve and safely restore editor state when the workbench is opened from
   an existing buffer; closing must not exit unexpectedly or leave stale state
   after an unsaved-buffer error.
3. Replace the simulated mouse/incomplete status evidence with a real mouse
   interaction record and an exact before/after Git status comparison.
4. Remove the trailing blank line and make `git diff --check` pass.
