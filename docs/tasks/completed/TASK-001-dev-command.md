# TASK-001 — Isolated development command

Updated: 2026-08-27
Task ID: `TASK-001`
Status: `ACCEPTED`
Delivery policy: `LIGHTWEIGHT`
Base branch: `main`
Task branch: `task/TASK-001-dev-command`
Expected baseline: `03939c0`
Pull request: `https://github.com/medonmez/novim-custom/pull/1`
Remote checks: `OPTIONAL / NOT_RUN`

## Outcome

This checkout can be launched as `novim-dev` from any directory, using the
fork's Neovim configuration and isolated writable runtime paths, while the
installed upstream `novim` command remains unchanged.

## Context

The installed release is a tarball extraction without Git history and its
updater writes into its own installation directory. A separate clone and
launcher are needed before making custom behavior changes safely.

## In scope

- Add a repository-local launcher for the development checkout.
- Expose the launcher through the distinct command name `novim-dev`.
- Resolve the checkout root so the command works regardless of the caller's
  current directory.
- Use this checkout's `config/nvim` as `XDG_CONFIG_HOME`.
- Keep development data/state separate from installed `novim` and the user's
  normal Neovim state.
- Provide a non-networking `--version`/help smoke path that identifies the
  development command.
- Document how to install or link the command locally.

## Out of scope

- Changes to the installed `/Users/mert/.local/share/novim` release.
- Changes to the user's normal Neovim configuration.
- New file-tree, search, LSP, Git review, AI, or terminal features.
- Automatic update, remote fork creation, GitHub push, or release publishing.
- Changes to upstream `bin/novim` behavior.

## Acceptance criteria

- [x] `novim-dev --version` resolves to the development launcher and exits
      successfully without a network request.
- [x] `novim-dev --headless '+qa'` (or an equivalent non-interactive smoke
      command) loads this checkout's config successfully.
- [x] Launching from a directory outside the repository still uses the
      checkout's `config/nvim/init.lua`.
- [x] Development runtime data/state paths are distinct from the installed
      `novim` paths and from the user's normal Neovim paths.
- [x] `novim --version` continues to report the installed upstream release.
- [x] A local install/link instruction for `novim-dev` is documented and does
      not overwrite `~/.local/bin/novim`.
- [x] The task diff contains no unrelated feature or upstream-site changes.

## Decision guardrails

- Preserve existing upstream behavior outside this launcher.
- Do not add network calls, credentials, telemetry, or remote Git mutations.
- Do not let an update command overwrite the development checkout.
- Keep the command name and runtime paths explicit rather than relying on
  whichever Neovim configuration happens to be active in the shell.
- Preserve MIT and third-party attribution notices.

## Relevant areas

- `bin/novim` — upstream wrapper to preserve as a reference and contract.
- `config/nvim/init.lua` — configuration that the development launcher must
  load.
- `VERSION` — upstream version baseline; use a clearly distinguishable dev
  identifier without pretending it is an upstream release.
- `.gitignore` — add only narrowly scoped ignores if a dev runtime directory is
  placed inside the checkout.
- `docs/repository.md`, `project-state.md`, and this task record — workflow
  records that must remain consistent.

## Required validation

- Shell syntax check for the new launcher.
- `novim-dev --version` and `novim-dev --help` from the repository root.
- Headless Neovim config-load smoke test from the repository root and from a
  temporary directory outside the repository.
- Confirm installed `novim --version` still resolves to the previously
  installed command.
- Inspect `git status` and the complete diff for scope and accidental runtime
  files.

## Blockers and dependencies

- No implementation blocker for this task.
- The GitHub fork and PR delivery path are now configured for this repository.

## Review and delivery record

- Implementation commit: `b8512b6`
- Local review: `APPROVED` at candidate `b8512b6`, baseline `03939c0`
- Review record: `docs/reviews/latest-review.md`
- Pull request: `#1 <https://github.com/medonmez/novim-custom/pull/1>`
- Merge commit: `12327b78049e1348df858b589baf669ba451c090`
- Merge status: `MERGED`
- Target branch contains change: `YES` (`origin/main`)
- Acceptance evidence: all 7 criteria passed in local launcher and config-load
  smoke tests; the complete delivered diff was scope-checked.

## Delivery gate

- Local review: `APPROVED`
- Pull request: `MERGED`
- Required checks: `OPTIONAL / NOT_RUN`
- Required approvals: `NOT_REQUIRED unless explicitly configured`
- Merge status: `MERGED`
- Target branch contains change: `YES`
