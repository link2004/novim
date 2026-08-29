# Current Task

Updated: 2026-08-30
Task ID: `TASK-008`
Status: `PLANNED`
Delivery policy: `LIGHTWEIGHT`
Base branch: `main`
Task branch: `task/TASK-008-settings-and-resizing`
Expected baseline: `4244d1036303e7a0a2ba292b69b4f6c673d1c53b` (`origin/main`)
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

Status: `PLANNED`

Implement only TASK-008 on the recorded isolated branch. Return a local
handoff with the candidate commit and observed validation; do not push, open a
PR, merge, or mark the task accepted as the implementer.
