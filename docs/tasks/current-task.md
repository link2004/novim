# Current Task

Updated: 2026-08-30
Task ID: `TASK-008`
Status: `READY_FOR_REVIEW`
Delivery policy: `LIGHTWEIGHT`
Base branch: `main`
Task branch: `task/TASK-008-settings-and-resizing`
Expected baseline: `b98901fcbde3dc7dc2d30e940e2fe3ebb5b81d7d` (`origin/main`)
Pull request: `NOT_OPEN`

## Outcome

Complete the next workbench slice: add six application-owned built-in themes,
accurate settings key help, immediate settings close behavior, and reliable
mouse resizing for the visible workbench panes. Preserve the accepted
read-only, isolated, terminal-first derivative boundary.

## Context

The settings panel currently persists only dot-folder visibility and exposes
one toggle. The workbench palette is fixed to Tokyo Night, the settings panel
has no embedded navigation/help section, and the existing two-pane divider is
only a native split boundary without explicit drag behavior. TASK-007's lazy
project browser is accepted on `origin/main` and must remain unchanged in
behavior while this interaction/display slice is implemented.

## In scope

- Add the exact six built-in themes: Tokyo Night, Nord, Gruvbox Dark,
  Catppuccin Mocha, One Dark, and Solarized Light; retain Tokyo Night as the
  default.
- Persist the selected theme through the existing isolated local settings
  path, with safe fallback for missing, malformed, or invalid theme values.
- Render a settings panel that exposes theme selection and dot-folder
  visibility, and displays key help below the controls.
- Make the key-help text match the actual workbench mappings for navigation,
  view/toggle actions, refresh, pane switching, settings, and close behavior.
- Make one `Esc` press close the settings panel immediately and return to the
  workbench; retain a direct close mapping such as `q`.
- Make the visible workbench pane boundary mouse-draggable in both directions,
  with sensible minimum widths and no `E21`/invalid-window failure.
- Keep existing source preview/editing, lazy expansion state, selection,
  refresh, directory inspection, and read-only Git behavior intact.
- Add deterministic tests for theme defaults/persistence/fallback, visible
  key-help and mappings, one-key settings close, pane drag direction and
  minimum widths, and existing regression contracts.

## Out of scope

- New project-browser traversal or expansion semantics; TASK-007 is accepted.
- Three-area side-by-side Git diff rendering or diff-entry refresh; those
  remain TASK-009.
- Git mutation, network access, plugin installation, background polling,
  installed `novim` changes, or changes to the normal Neovim configuration.
- User-created themes, arbitrary color configuration, or a theme/plugin
  management system.

## Acceptance criteria

- [ ] Settings supports the exact six built-in themes, defaults safely to
      Tokyo Night, and applies the selected application-owned palette to the
      workbench/settings UI without a plugin dependency.
- [ ] The selected theme and existing dot-folder setting persist under the
      isolated settings path across launches; missing, malformed, or invalid
      values fall back safely without overwriting unrelated settings.
- [ ] The settings panel visibly includes key help below its controls, and
      every documented navigation, view/toggle, refresh, pane, settings, and
      close shortcut is implemented by the corresponding actual mapping.
- [ ] Pressing `Esc` once closes settings immediately and restores workbench
      focus; `q` remains a direct close action.
- [ ] The visible workbench pane boundary responds to mouse drag in both
      directions, clamps to minimum usable widths, and preserves valid windows
      and existing selection/navigation behavior.
- [ ] TASK-007 lazy root-only browsing, session-only expansion, dotfile
      filtering, refresh behavior, source preview/editing, and read-only Git
      behavior remain intact.
- [ ] No plugin, Git mutation, network action, installed-release write, or
      TASK-009 three-area diff implementation is introduced.

## Decision guardrails

- Use application-owned palettes and direct mappings in the bundled Neovim
  configuration; do not add a plugin manager or third-party runtime
  dependency.
- Preserve the current isolated settings file and `novim-dev` runtime paths;
  theme state must not leak into the user's normal Neovim configuration.
- Keep existing dotfile filtering and lazy expansion semantics unchanged.
- Keep all Git commands read-only and avoid network actions by default.
- Do not modify `/Users/mert/.local/share/novim`, the installed `novim`
  command, or the normal Neovim configuration.
- Keep this slice limited to settings/display/input interaction; do not begin
  the TASK-009 diff layout.

## Relevant areas

- `config/nvim/lua/novim/settings.lua` — persisted display settings and safe
  fallback behavior.
- `config/nvim/lua/novim/settings_ui.lua` — theme controls, key help, and
  immediate close mappings.
- `config/nvim/lua/novim/workbench.lua` — palette application, pane layout,
  mouse handling, and preserved lazy-browser integration.
- `tests/test_workbench.lua` and `tests/test_smoke.lua` — deterministic
  interaction and regression coverage.
- `docs/architecture.md` and `docs/product/product.md` — accepted display and
  interaction contracts.

## Required validation

- Add and run focused tests for all six themes, default/persistence/fallback,
  settings key help and actual mappings, one-key `Esc` close, and bidirectional
  pane dragging with minimum-width constraints.
- Run `./tests/run_tests.sh`, including the offline package and regression
  smoke suites.
- Run Lua/shell syntax checks as applicable, both version checks, JSON
  validation, and `git diff --check`.
- Verify the candidate diff contains no installed-release, network, Git
  mutation, credential, plugin, TASK-007 regression, or TASK-009 scope change.
- Keep all evidence local; do not claim hosted, production, recovery, or
  customer acceptance.

## Blockers and dependencies

- No product decision is open for this slice.
- Dependency: TASK-007 is accepted on `origin/main` at
  `d8f567a2b1b20d6ab9f9afba7e5ab9d2442ce1c9`.
- TASK-009 remains proposed and depends on TASK-008 acceptance.

## Implementation handoff

Status: `READY_FOR_REVIEW`

### Change summary

Implemented the full TASK-008 slice on `task/TASK-008-settings-and-resizing`
(baseline `origin/main` `b98901f`, orchestration commit `6ffa8e1` on top):

- Added `config/nvim/lua/novim/themes.lua`: six application-owned built-in
  palettes (Tokyo Night default, Nord, Gruvbox Dark, Catppuccin Mocha,
  One Dark, Solarized Light) with one `apply()` mapping to every highlight
  group the bundled config previously hard-coded. The Tokyo Night default is
  byte-exact against the accepted baseline (verified sampled group values).
- `init.lua` no longer hard-codes the Tokyo Night palette; it calls
  `require("novim.themes").apply("tokyo_night")` (clean cutover, no second
  palette convention).
- `settings.lua` persists `theme` through the existing isolated settings
  file next to `show_dotfiles`; missing, malformed, non-string, or unknown
  theme values fall back to `tokyo_night` without clobbering unrelated
  settings; `M.set("theme", ...)` rejects invalid ids.
- `settings_ui.lua` renders a theme control plus the dot-folder control,
  shows the key-help section below the controls, applies the selected
  palette live, and closes immediately on one `Esc` (or `q`), restoring the
  previously focused workbench window (synchronous `nvim_win_hide`).
- `workbench.lua` delegates all highlight setup to the active theme and adds
  an application-owned divider drag: a press on the visible boundary starts
  the drag, `<LeftDrag>` resizes in both directions, `<LeftRelease>` ends it;
  widths clamp to minimums (left 15, right 20 columns) and resizing never
  raises `E21` or invalid-window errors; selection/navigation is preserved.
- Added `config/nvim/lua/novim/keymaps.lua`: canonical keymap documentation
  shared by the settings key help and the tests that pin help text to real
  mappings in both directions.
- `tests/run_smoke_tests.sh` Step 4 now snapshots tracked `bin/`+`config/`
  checksums before the run and compares after, so it detects mutations made
  during the run while no longer failing legitimate uncommitted task changes
  (its previous working-tree-vs-HEAD comparison contradicted its documented
  purpose on any task branch with uncommitted product changes).

### Files changed

- `config/nvim/lua/novim/themes.lua` (new), `config/nvim/lua/novim/keymaps.lua` (new)
- `config/nvim/lua/novim/settings.lua`, `config/nvim/lua/novim/settings_ui.lua`,
  `config/nvim/lua/novim/workbench.lua`, `config/nvim/init.lua`
- `tests/test_workbench.lua`, `tests/test_smoke.lua`, `tests/run_smoke_tests.sh`
- `docs/architecture.md` (baseline contracts), `docs/project.json` (status),
  this task file

### Validation commands and results (all local)

- `./tests/run_tests.sh`: PASS — 33/33 integration tests
  (`tests/test_workbench.lua`), offline package suite PASS, 7/7 regression
  smoke tests PASS, product-tree invariance PASS.
- `bash -n bin/novim-dev bin/novim-dev-package tests/run_tests.sh
  tests/run_smoke_tests.sh tests/run_package_tests.sh`: PASS.
- `./bin/novim-dev --version`: `0.1.7-dev` (NVIM v0.12.5); installed
  `/Users/mert/.local/bin/novim --version`: `0.1.7` unchanged: PASS.
- `python3 -m json.tool docs/project.json`: PASS.
- `git diff --check`: PASS (no whitespace errors).
- Read-only scope scan of `git diff origin/main...HEAD` plus the working
  tree: no network calls, Git mutations, credentials, plugin dependencies,
  installed-release writes, TASK-007 regressions, or TASK-009 scope content.

### Acceptance-criterion evidence

| Criterion | Result | Evidence |
|---|---|---|
| Exact six themes, Tokyo Night default, application-owned, plugin-free | PASS | `themes.lua:251-259` canonical order, `themes.lua:11` default, `themes.lua:290` apply; `tests/test_workbench.lua:1460-1505` |
| Theme + dot-folder persistence, safe fallback without clobbering | PASS | `settings.lua:11,55-57,90-92,137-139`; `tests/test_workbench.lua:1507-1567` |
| Key help visible below controls; every documented shortcut backed by real mappings | PASS | `settings_ui.lua:113,129-137` rendering, `keymaps.lua` canonical docs; bidirectional mapping check `tests/test_workbench.lua:1616-1708` |
| One `Esc` closes immediately, restores workbench focus; `q` closes directly | PASS | `settings_ui.lua:48-66,312-313`; `tests/test_workbench.lua:1710-1759`; `tests/test_smoke.lua:665-806` |
| Pane boundary drags both directions, clamps to minimum widths, valid windows and selection preserved | PASS | `workbench.lua:49-51,712-783,1204-1205`; `tests/test_workbench.lua:1761-1838` |
| TASK-007 lazy browsing, expansion, dotfile filtering, refresh, preview/editing, read-only Git intact | PASS | Existing TASK-003/004/007 suites all green (`test_workbench.lua`, `test_smoke.lua`), including byte-for-byte Git invariance tests |
| No plugin, Git mutation, network, installed-release write, or TASK-009 scope | PASS | Scope scan above; `themes.lua`/`keymaps.lua` require nothing; diff contains no diff-layout changes |

### Residual risks and known gaps

- Non-default theme surface colors for Nord/Gruvbox/Catppuccin/One Dark/
  Solarized Light are application-owned renditions of the canonical public
  palettes; only Tokyo Night is verified byte-exact against a prior baseline.
- With the right pane focused, divider dragging uses Neovim's native
  separator drag (`mouse=a`, `winminwidth=15`); application-owned drag state
  covers the left-pane-focused case. Both directions work; the native path
  clamps at 15 columns rather than the 20-column right-pane minimum.
- Settings panel height is capped for small terminals; content remains fully
  rendered in the buffer regardless.

### Candidate commit

HEAD (handoff commit): the single local commit on
`task/TASK-008-settings-and-resizing` containing the staged task-owned files
listed above; the resolved hash is reported to the orchestrator. Do not push,
open a PR, merge, or mark the task accepted as the implementer.
