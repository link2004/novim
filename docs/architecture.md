# Architecture

Updated: 2026-08-27
Status: `OBSERVED_BASELINE`

## Current system

The repository is a direct clone of upstream novim at tag `v0.1.7`.

### Launcher

- `bin/novim` is a Bash wrapper, not a compiled editor.
- It resolves its own repository root and sets `XDG_CONFIG_HOME` to the
  bundled `config` directory.
- It also sets separate `XDG_DATA_HOME` and `XDG_STATE_HOME` directories below
  that config root, then executes `nvim "$@"`.
- The installed release is a separate extraction under
  `~/.local/share/novim`; this repository does not own or update that path.

### Neovim configuration

- `config/nvim/init.lua` contains the main behavior and visual configuration.
- The file defines the Tokyo Night-inspired palette, standard editing
  shortcuts, mouse behavior, safe quit flow, netrw-based file tree, dynamic
  help, and Git overlays.
- The file tree is built on netrw with tree view and a right-hand editor split.
- Git status, log, and diff are currently opened by running local Git commands
  in temporary Neovim floating terminal buffers.
- `gitsigns.nvim` is bundled under `config/nvim/pack/` for buffer-level Git
  change signs.

### External boundaries

- Files are read and written through Neovim and the local filesystem.
- Git information is obtained through local Git subprocesses.
- Normal editor launch has no required hosted service or application database.
- The upstream wrapper also exposes update/statistics paths; the planned
  development command must not reuse those network-capable behaviors by
  default.

## Planned development boundary

`TASK-001` will add a repository-local development launcher and a separate
`novim-dev` command. The launcher will use this checkout's `config/nvim` while
keeping writable data/state separate from upstream `novim`. It will not change
the upstream command or add product features yet.

## Accepted target direction

After bootstrap, the target product direction is a read-only diff workbench:

- left pane: project tree or changed-file list;
- right pane: source preview or a readable Git diff;
- divider: mouse-draggable and width-constrained;
- settings: an in-app menu/panel, beginning with dot-folder visibility;
- Git: local status/history/diff inspection only, with no stage, commit, push,
  discard, or other repository mutation;
- extensions: no plugin manager or third-party plugin dependency for the first
  workbench slices.

The exact diff baseline and settings persistence model remain open and must be
resolved before the corresponding implementation task is issued.

## Preserved contracts

- Public/user command: installed `novim` remains unchanged.
- Configuration isolation: the derivative must not load or overwrite the
  user's normal Neovim config.
- Editing behavior: Ctrl/Cmd save, undo, copy, paste, mouse interaction, and
  safe quit remain available unless an accepted task changes them.
- License and attribution: retain MIT and third-party notices.
- Privacy: no source, credentials, or raw private data leave the machine by
  default.

## Known risks and unknowns

- The current config is intentionally compact but monolithic; plugin growth
  could make behavior harder to reason about.
- netrw and floating terminal buffers may not provide the full file/diff
  navigation expected from VS Code.
- No dedicated repository test suite was observed in the upstream clone.
- The first feature priority and the Git mutation boundary are still awaiting
  the product grill.
