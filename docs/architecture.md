# Architecture

Updated: 2026-08-30
Status: `OBSERVED_BASELINE_WITH_ACCEPTED_EXTENSION`

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

### Current derivative workbench baseline

- `novim.workbench` opens two windows and reads only the immediate entries of
  the root directory at startup and on every refresh through
  `browser.get_immediate_entries`; startup performs no recursive traversal, so
  launching from a large directory stays responsive.
- The project browser renders a lazy visible list. Double-clicking a folder
  expands one level at a time (immediate children only), double-clicking an
  expanded folder collapses it and removes its descendants, and expansion
  state lives in workbench memory for the current session only. Symlink loops
  are refused by comparing real paths against the folder's own ancestors.
- Settings persist dot-folder visibility and the selected built-in theme.
  The settings modal offers theme selection (six application-owned themes,
  Tokyo Night default), an embedded key-help section rendered below the
  controls, and immediate `Esc`/`q` close that restores workbench focus.
  Themes apply through `novim.themes` highlight mappings with no plugin
  dependency; theme state lives in the isolated settings file.
- The current Diff view renders a selected file as unified text in the right
  preview window. The visible pane boundary has an application-owned drag
  state: pressing the divider starts a drag, `<LeftDrag>` resizes both
  directions, and widths clamp to minimum pane widths (left 15, right 20
  columns) without `E21` or invalid-window failures.

### External boundaries

- Files are read and written through Neovim and the local filesystem.
- Git information is obtained through local Git subprocesses.
- Normal editor launch has no required hosted service or application database.
- The upstream wrapper also exposes update/statistics paths; the planned
  development command must not reuse those network-capable behaviors by
  default.

## Development boundary and launcher

`TASK-001` added a dedicated repository-local launcher via `bin/novim-dev`:
- Resolves its repository root dynamically through symlinks and from any working directory.
- Sets `XDG_CONFIG_HOME` to this checkout's `config` directory (`config/nvim/init.lua`).
- Sets separate runtime paths `XDG_DATA_HOME` (`.dev-data/`), `XDG_STATE_HOME` (`.dev-state/`), and `XDG_CACHE_HOME` (`.dev-cache/`) inside the checkout root, keeping runtime state strictly isolated from installed `novim` and standard Neovim configurations.
- Excludes networking, update, and uninstallation routines.
- Forwards arbitrary Neovim flags (e.g. `--headless`, buffers, files) to `nvim`.

### Local installation / linking

To make `novim-dev` accessible from any terminal without overwriting the installed `novim`:

```bash
ln -sf /Users/mert/novim-custom/bin/novim-dev ~/.local/bin/novim-dev
```

Verification:
- `novim-dev --version` reports the development launcher without network activity.
- `novim --version` continues to invoke the upstream release at `~/.local/bin/novim`.

### Local derivative packaging

`bin/novim-dev-package` is an offline, allowlist-based distribution helper:

- `package ARCHIVE` stages `bin/novim-dev`, the complete `config/nvim` tree,
  `VERSION`, `LICENSE`, and `THIRD_PARTY_LICENSES.md` into a deterministic
  `novim-custom-<VERSION>.tar.gz` archive;
- the archive excludes Git metadata, `.dev-*` state, credentials, and private
  runtime data and does not include the upstream `bin/novim` command; and
- `install ARCHIVE INSTALL_ROOT` extracts only into a new or empty, explicitly
  named derivative root. A launcher link, when desired, is user-created at
  `~/.local/bin/novim-dev`; the installed `novim` path is never a target.

Package creation and installation perform no network or Git history action.
The manifest, temporary-target verification, and removal boundaries are
documented in `docs/LOCAL_DISTRIBUTION.md`. Explicit upstream comparison and
integration is documented separately in `docs/UPSTREAM_SYNC.md`.

## Local testing and regression smoke layer

Deterministic local validation is provided through standalone scripts without external dependencies:

- `./tests/run_tests.sh`: runs all test suites, including the unit/integration suite (`tests/test_workbench.lua`) and the regression smoke runner. Supports `--smoke` / `-s` to run only smoke checks, or `--all` / `-a` to run both.
- `./tests/run_smoke_tests.sh`: dedicated end-to-end regression smoke runner. It exercises:
  1. CLI flags (`--version`, `-v`, `--help`) and output validation.
  2. Working directory independence (invoking from `/tmp`) and symlink path resolution.
  3. Isolation from installed `novim` (`~/.local/share/novim` remains untouched).
  4. Headless Neovim execution of `tests/test_smoke.lua` against isolated temporary Git/project fixtures, verifying two-pane layout, divider constraints, view switching, source preview/editing handoff, unsaved buffer preservation, settings persistence/malformed fallback, and byte-for-byte Git read-only invariance.
  5. Post-run artifact cleanup verification ensuring zero fixture residue.

## Accepted target direction

The accepted next target is a read-only multi-pane diff workbench:

- Files view: left lazy project tree and right source preview;
- Diff view: left changed-file list, middle old-file content, and right
  new-file content;
- every visible pane boundary: mouse-draggable and width-constrained;
- project tree: root-only at launch, with session-only double-click folder
  expansion and on-demand child scanning;
- settings: an in-app panel with six built-in themes, dot-folder visibility,
  and an accurate key-help section;
- Git: local status/history/diff inspection only, with no stage, commit, push,
  discard, or other repository mutation;
- initial diff baseline: working tree versus `HEAD`, including untracked files;
- diff entry: refresh Git status and selected content on entry, while keeping
  continuous background polling out of scope;
- text diff presentation: old content on the left and new content on the
  right, with red removed lines and green added lines;
- settings: persisted locally between launches;
- dot-folders: hidden by default and revealed through a settings toggle;
- extensions: no plugin manager or third-party plugin dependency for the first
  workbench slices.

Selected branch or historical-commit comparisons are future scope and are not
required for the first workbench slice.

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
- The three-area layout must remain usable at narrow terminal widths; minimum
  pane widths and behavior when a file is binary or deleted need explicit
  local tests.
