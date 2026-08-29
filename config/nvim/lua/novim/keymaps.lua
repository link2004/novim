-- novim/keymaps.lua - Canonical keymap documentation for novim custom derivative
-- Part of novim custom derivative
--
-- Single source of truth shared by the settings panel key-help section and
-- the tests that pin help text to real mappings. Every entry lists the
-- actual Normal-mode buffer-local mappings backing its display label; the
-- tests assert this correspondence in both directions, so the rendered help
-- can never silently drift from the workbench behavior.

local M = {}

--- Workbench shortcuts (left navigation pane and right preview pane).
--- Each entry: { display = help text, keys = mapped lhs strings, desc = action }.
M.workbench = {
  { display = "j / k or ↑ / ↓", keys = { "j", "k", "<Up>", "<Down>" }, desc = "Move selection" },
  { display = "Left Click", keys = { "<LeftMouse>" }, desc = "Select item / switch tabs" },
  { display = "Double-Click", keys = { "<2-LeftMouse>" }, desc = "Expand folder / open file" },
  { display = "Enter / e / o", keys = { "<CR>", "e", "o" }, desc = "Open regular file / select" },
  { display = "Space", keys = { "<Space>" }, desc = "Preview selected item" },
  { display = "1 / b / f", keys = { "1", "b", "f" }, desc = "Project Files view" },
  { display = "2 / d / g", keys = { "2", "d", "g" }, desc = "Git Diff view (vs HEAD)" },
  { display = "Tab / Shift-Tab", keys = { "<Tab>", "<S-Tab>" }, desc = "Switch left/right pane" },
  { display = "Drag Boundary", keys = { "<LeftDrag>", "<LeftRelease>" }, desc = "Resize panes (drag divider)" },
  { display = "r or Ctrl-R", keys = { "r", "<C-r>" }, desc = "Refresh files and Git status" },
  { display = "s or S", keys = { "s", "S" }, desc = "Open settings" },
  { display = "?", keys = { "?" }, desc = "Show workbench help" },
  { display = ":", keys = { ":" }, desc = "Command line" },
  { display = "q or Esc Esc", keys = { "q", "<Esc><Esc>" }, desc = "Quit the workbench" },
}

--- Settings panel shortcuts.
M.settings = {
  { display = "h / ← / [", keys = { "h", "<Left>", "[" }, desc = "Previous theme" },
  { display = "l / → / ]", keys = { "l", "<Right>", "]" }, desc = "Next theme" },
  { display = "t / Space / Enter", keys = { "t", "<Space>", "<CR>" }, desc = "Toggle dot-folder visibility" },
  { display = "q / Esc", keys = { "q", "<Esc>" }, desc = "Close settings (Esc closes immediately)" },
}

return M
