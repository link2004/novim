# Current Task

Updated: 2026-08-27
Task ID: `TASK-001`
Status: `READY_FOR_REVIEW`
Delivery policy: `LIGHTWEIGHT`
Base branch: `main`
Task branch: `task/TASK-001-dev-command`
Expected baseline: `8e36d447ee9c73d29b75f3dfc50db9452a2addf1` (`v0.1.7`)
Pull request: `NOT_OPEN`
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
- A GitHub fork remote is not required for local implementation or review.

## Implementer handoff

- Status: `READY_FOR_REVIEW`
- Summary: Implemented `bin/novim-dev` launcher with dynamic symlink-safe checkout root resolution and path isolation (`XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`, `XDG_CACHE_HOME`). Added dev runtime directories to `.gitignore` and documented linking in `docs/architecture.md`. Verified that installed `novim` remains untouched.
- Files changed:
  - `bin/novim-dev` (new executable wrapper)
  - `.gitignore` (ignore `.dev-data/`, `.dev-state/`, `.dev-cache/`)
  - `docs/architecture.md` (documented launcher contract and link instructions)
  - `docs/tasks/current-task.md` (acceptance criteria and handoff)
- Validation:
  - `bash -n bin/novim-dev`: syntax valid
  - `./bin/novim-dev --version` & `--help`: valid output, non-networking, exit 0
  - `./bin/novim-dev --headless "+lua print('LOADED: ' .. vim.g.colors_name)" +qa`: loaded `tokyonight`
  - stdpath isolation check: config under `config/`, data/state/cache under `.dev-*/`
  - `/tmp` execution test via absolute path and symlink: both resolved config to checkout
  - `novim --version`: unchanged at `/Users/mert/.local/bin/novim` (0.1.7)
- Acceptance evidence: All 7 criteria verified locally.
- Residual risks: None.
- Candidate commit or diff: `HEAD (handoff commit)`

## Delivery gate

- Local review: `NOT_REVIEWED`
- Pull request: `NOT_OPEN`
- Required checks: `OPTIONAL / NOT_RUN`
- Required approvals: `NOT_REQUIRED unless explicitly configured`
- Merge status: `NOT_MERGED`
- Target branch contains change: `NO`
