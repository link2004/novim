-- novim/settings_ui.lua - Interactive Settings Modal for novim custom derivative
-- Part of novim custom derivative

local settings = require("novim.settings")

local M = {}

local state = {
  win = nil,
  buf = nil,
  on_change = nil,
  ns_id = vim.api.nvim_create_namespace("novim_settings_ui"),
}

--- Check if settings modal is currently open
---@return boolean
function M.is_open()
  return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

--- Close the settings modal
function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    pcall(vim.api.nvim_win_close, state.win, true)
  end
  state.win = nil
  state.buf = nil
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
  local path = settings.get_settings_file_path()

  -- Shorten path if very long
  local display_path = path
  if #display_path > 52 then
    display_path = "..." .. display_path:sub(#display_path - 49)
  end

  local lines = {
    " novim-dev Settings & Preferences",
    " ────────────────────────────────────────────────────────",
    "",
    " Display Options:",
    "",
    string.format("   ▶ %s Show Dot-Folders & Hidden Files", checkbox),
    string.format("       Status: %s", status_text),
    "",
    " ────────────────────────────────────────────────────────",
    " Shortcuts:",
    "   [Space] / [Enter] / [Click]   Toggle selected setting",
    "   [t]                           Toggle dot-folders visibility",
    "   [q] / [Esc]                   Close settings",
    " ────────────────────────────────────────────────────────",
    " Storage:",
    "   Saved to: " .. display_path,
  }

  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false
  vim.bo[state.buf].readonly = true

  -- Highlights
  vim.api.nvim_buf_clear_namespace(state.buf, state.ns_id, 0, -1)
  local function add_hl(line, col_start, col_end, group)
    pcall(vim.api.nvim_buf_add_highlight, state.buf, state.ns_id, group, line, col_start, col_end)
  end

  add_hl(0, 0, -1, "Title")
  add_hl(1, 0, -1, "WorkbenchDivider")
  add_hl(3, 0, -1, "WorkbenchHeader")
  add_hl(5, 5, 8, show_dot and "WorkbenchClean" or "WorkbenchSummary")
  add_hl(5, 9, -1, "Normal")
  add_hl(6, 7, -1, show_dot and "WorkbenchClean" or "WorkbenchSubHeader")
  add_hl(8, 0, -1, "WorkbenchDivider")
  add_hl(9, 0, -1, "WorkbenchKeyHint")
  add_hl(13, 0, -1, "WorkbenchDivider")
  add_hl(14, 0, -1, "WorkbenchKeyHint")
  add_hl(15, 0, -1, "WorkbenchSubHeader")
end

--- Toggle the dotfiles setting and notify listeners
function M.toggle_dotfiles()
  local new_val = settings.toggle_dotfiles()
  M.render()
  if state.on_change then
    pcall(state.on_change, "show_dotfiles", new_val)
  end
end

--- Open the settings modal
---@param on_change? fun(key: string, value: any)
function M.open(on_change)
  if M.is_open() then
    vim.api.nvim_set_current_win(state.win)
    M.render()
    return
  end

  state.on_change = on_change

  local width = 60
  local height = 18
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
  vim.keymap.set("n", ":", ":", { buffer = state.buf, noremap = true, silent = false })
  vim.keymap.set("n", "<LeftMouse>", function()
    local mouse = vim.fn.getmousepos()
    if mouse.winid == state.win then
      -- Click anywhere on the option line or toggle
      M.toggle_dotfiles()
    end
  end, opts)

  vim.keymap.set("n", "q", M.close, opts)
  vim.keymap.set("n", "<Esc>", M.close, opts)
end

return M
