-- novim/settings_ui.lua - Interactive Settings Modal for novim custom derivative
-- Part of novim custom derivative

local settings = require("novim.settings")
local themes = require("novim.themes")
local keymaps = require("novim.keymaps")

local M = {}

local DIVIDER = " ────────────────────────────────────────────────────────"

local state = {
  win = nil,
  buf = nil,
  on_change = nil,
  last_error = nil,
  prev_win = nil,
  dotfiles_row = nil,
  theme_row = nil,
  ns_id = vim.api.nvim_create_namespace("novim_settings_ui"),
}

--- Check if settings modal is currently open
---@return boolean
function M.is_open()
  return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

--- Buffer of the open settings modal (for diagnostics / testing)
---@return integer? buf
function M.get_buf()
  if M.is_open() and state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    return state.buf
  end
  return nil
end

--- Window of the open settings modal (for diagnostics / testing)
---@return integer? win
function M.get_win()
  if M.is_open() then
    return state.win
  end
  return nil
end

--- Restore focus to the window that was current before the modal opened.
local function restore_focus()
  if state.prev_win and vim.api.nvim_win_is_valid(state.prev_win) then
    pcall(vim.api.nvim_set_current_win, state.prev_win)
  end
  state.prev_win = nil
end

--- Close the settings modal and return focus to the workbench immediately.
--- nvim_win_hide is synchronous, so the float is gone and workbench focus is
--- restored deterministically within the same keypress.
function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    pcall(vim.api.nvim_win_hide, state.win)
  end
  state.win = nil
  state.buf = nil
  state.last_error = nil
  restore_focus()
end

--- Render settings content in buffer
function M.render()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end

  vim.bo[state.buf].readonly = false
  vim.bo[state.buf].modifiable = true

  local cur_settings = settings.load(true)
  local show_dot = cur_settings.show_dotfiles
  local checkbox = show_dot and "[X]" or "[ ]"
  local status_text = show_dot and "ON (dot-prefixed files & folders are VISIBLE)" or "OFF (dot-prefixed files & folders are HIDDEN)"

  local theme_list = themes.list()
  local theme_pos = 1
  for i, t in ipairs(theme_list) do
    if t.id == cur_settings.theme then
      theme_pos = i
      break
    end
  end
  local theme_label = theme_list[theme_pos].label

  local path = settings.get_settings_file_path()

  -- Shorten path if very long
  local display_path = path
  if #display_path > 52 then
    display_path = "..." .. display_path:sub(#display_path - 49)
  end

  local lines = {
    " novim-dev Settings & Preferences",
    DIVIDER,
    "",
    " Display Options:",
    "",
  }

  local dot_row, theme_row
  table.insert(lines, string.format("   ▶ %s Show Dot-Folders & Hidden Files", checkbox))
  dot_row = #lines -- 1-based window row (lines[1] renders at window row 1)
  table.insert(lines, string.format("       Status: %s", status_text))
  table.insert(lines, "")
  table.insert(lines, string.format("   ▶ Theme:  ‹ %s ›", theme_label))
  theme_row = #lines
  table.insert(lines, string.format("       Status: Palette %d of %d applied  ([h]/[l] to change)", theme_pos, #theme_list))
  table.insert(lines, "")

  local error_line_idx = nil
  if state.last_error then
    table.insert(lines, " ⚠ " .. tostring(state.last_error))
    error_line_idx = #lines - 1
    table.insert(lines, "   (Changes could not be persisted to disk)")
    table.insert(lines, "")
  end

  -- Key help is rendered below the display controls, from the canonical
  -- keymap documentation so it always matches the actual mappings.
  table.insert(lines, DIVIDER)
  table.insert(lines, " Key Bindings (Workbench):")
  local workbench_docs_start = #lines
  for _, entry in ipairs(keymaps.workbench) do
    table.insert(lines, string.format("   %-21s %s", entry.display, entry.desc))
  end
  table.insert(lines, DIVIDER)
  table.insert(lines, " Settings Panel Keys:")
  local settings_docs_start = #lines
  for _, entry in ipairs(keymaps.settings) do
    table.insert(lines, string.format("   %-21s %s", entry.display, entry.desc))
  end
  table.insert(lines, DIVIDER)
  table.insert(lines, " Storage:")
  table.insert(lines, "   Saved to: " .. display_path)

  state.dotfiles_row = dot_row
  state.theme_row = theme_row

  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false
  vim.bo[state.buf].readonly = true

  -- Highlights
  vim.api.nvim_buf_clear_namespace(state.buf, state.ns_id, 0, -1)
  local function add_hl(line, col_start, col_end, group)
    pcall(vim.api.nvim_buf_add_highlight, state.buf, state.ns_id, group, line, col_start, col_end)
  end

  local function row0(row)
    return row - 1 -- window row (1-based) to buffer line (0-based)
  end

  add_hl(0, 0, -1, "Title")
  add_hl(1, 0, -1, "WorkbenchDivider")
  add_hl(3, 0, -1, "WorkbenchHeader")
  add_hl(row0(dot_row), 5, 8, show_dot and "WorkbenchClean" or "WorkbenchSummary")
  add_hl(row0(dot_row), 9, -1, "Normal")
  add_hl(row0(dot_row) + 1, 7, -1, show_dot and "WorkbenchClean" or "WorkbenchSubHeader")
  add_hl(row0(theme_row), 5, -1, "WorkbenchKeyHint")
  add_hl(row0(theme_row) + 1, 7, -1, "WorkbenchSubHeader")

  if error_line_idx then
    add_hl(error_line_idx, 0, -1, "WorkbenchError")
    add_hl(error_line_idx + 1, 0, -1, "WorkbenchSubHeader")
  end

  add_hl(row0(workbench_docs_start) - 1, 0, -1, "WorkbenchDivider")
  add_hl(row0(workbench_docs_start), 0, -1, "WorkbenchKeyHint")
  add_hl(row0(settings_docs_start) - 1, 0, -1, "WorkbenchDivider")
  add_hl(row0(settings_docs_start), 0, -1, "WorkbenchKeyHint")
  add_hl(row0(settings_docs_start) + #keymaps.settings + 1, 0, -1, "WorkbenchDivider")
  add_hl(row0(settings_docs_start) + #keymaps.settings + 2, 0, -1, "WorkbenchSubHeader")
end

--- Toggle the dotfiles setting and notify listeners
function M.toggle_dotfiles()
  local ok, err, effective_val = settings.toggle_dotfiles()
  if not ok then
    state.last_error = "Failed to save settings: " .. tostring(err)
    M.render()
    return
  end

  state.last_error = nil
  M.render()
  if state.on_change then
    pcall(state.on_change, "show_dotfiles", effective_val)
  end
end

--- Select a specific built-in theme, persist it, and apply its palette live.
--- On save failure the previous theme is retained and the error is rendered.
---@param id string
---@return boolean success
---@return string? error_msg
function M.set_theme(id)
  local ok, err = settings.set("theme", id)
  if not ok then
    state.last_error = "Failed to save theme: " .. tostring(err)
    M.render()
    return false, err
  end

  state.last_error = nil
  themes.apply(id)
  M.render()
  if state.on_change then
    pcall(state.on_change, "theme", id)
  end
  return true, nil
end

--- Cycle through the built-in themes (+1 next, -1 previous) with wraparound.
---@param direction integer
---@return boolean success
---@return string? error_msg
function M.cycle_theme(direction)
  local list = themes.list()
  local current = settings.get("theme")
  local pos = 1
  for i, t in ipairs(list) do
    if t.id == current then
      pos = i
      break
    end
  end
  local next_pos = ((pos - 1 + direction) % #list) + 1
  return M.set_theme(list[next_pos].id)
end

--- Open the settings modal
---@param on_change? fun(key: string, value: any)
function M.open(on_change)
  if M.is_open() then
    vim.api.nvim_set_current_win(state.win)
    M.render()
    return
  end

  state.last_error = nil
  state.on_change = on_change
  state.prev_win = vim.api.nvim_get_current_win()

  local width = 60
  local height = math.min(38, math.max(20, vim.o.lines - 4))
  local row = math.max(1, math.floor((vim.o.lines - height) / 2))
  local col = math.max(1, math.floor((vim.o.columns - width) / 2))

  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].buftype = "nofile"
  vim.bo[state.buf].bufhidden = "wipe"
  vim.bo[state.buf].swapfile = false
  vim.bo[state.buf].buflisted = false

  state.win = vim.api.nvim_open_win(state.buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Settings ",
    title_pos = "center",
  })

  vim.wo[state.win].cursorline = false
  vim.wo[state.win].number = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].signcolumn = "no"

  M.render()

  -- Keymaps
  local opts = { buffer = state.buf, silent = true, noremap = true }

  vim.keymap.set("n", "<Space>", M.toggle_dotfiles, opts)
  vim.keymap.set("n", "<CR>", M.toggle_dotfiles, opts)
  vim.keymap.set("n", "t", M.toggle_dotfiles, opts)

  -- Theme selection
  vim.keymap.set("n", "h", function() M.cycle_theme(-1) end, opts)
  vim.keymap.set("n", "<Left>", function() M.cycle_theme(-1) end, opts)
  vim.keymap.set("n", "[", function() M.cycle_theme(-1) end, opts)
  vim.keymap.set("n", "l", function() M.cycle_theme(1) end, opts)
  vim.keymap.set("n", "<Right>", function() M.cycle_theme(1) end, opts)
  vim.keymap.set("n", "]", function() M.cycle_theme(1) end, opts)

  vim.keymap.set("n", ":", ":", { buffer = state.buf, noremap = true, silent = false })

  -- Clicking a control row toggles it; the theme row cycles to the next theme
  vim.keymap.set("n", "<LeftMouse>", function()
    local mouse = vim.fn.getmousepos()
    if mouse.winid == state.win then
      if state.theme_row and mouse.line == state.theme_row then
        M.cycle_theme(1)
      elseif state.dotfiles_row and mouse.line == state.dotfiles_row then
        M.toggle_dotfiles()
      end
    end
  end, opts)

  -- Single Esc closes immediately; q stays a direct close action
  vim.keymap.set("n", "q", M.close, opts)
  vim.keymap.set("n", "<Esc>", M.close, opts)
end

return M
