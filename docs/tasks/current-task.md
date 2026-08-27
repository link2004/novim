# Current Task

Updated: 2026-08-27
Task ID: `TASK-002`
Status: `PLANNED`
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

- [ ] Launching `novim-dev` in a fixture Git repository opens the workbench
      without requiring a network connection or a plugin installation.
- [ ] The left pane identifies changed tracked files relative to `HEAD` and
      includes at least modified and untracked fixture files.
- [ ] Selecting a tracked file shows its working-tree diff against `HEAD` in
      the right pane, with enough context to identify additions and deletions.
- [ ] Selecting an untracked file shows its complete readable new-file view or
      an equivalent all-additions diff without staging the file.
- [ ] Dragging the divider with the mouse changes the left/right pane widths in
      both directions and respects minimum usable widths.
- [ ] The workbench exposes no action that stages, commits, pushes, discards,
      or otherwise mutates Git state; opening and quitting it leaves the fixture
      repository status unchanged.
- [ ] Existing launcher isolation remains intact: `novim-dev` still uses this
      checkout's configuration/runtime paths and installed `novim` remains
      unchanged.
- [ ] The implementation introduces no plugin-manager or new third-party
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

- Use `$stateless-implementer` on `task/TASK-002-diff-workbench`.
- Start from `main` at `12327b78049e1348df858b589baf669ba451c090`.
- Implement only the observable read-only diff workbench described above.
- Stop at a local `READY_FOR_REVIEW` handoff with commands, fixture details,
  and evidence recorded for each acceptance criterion.
