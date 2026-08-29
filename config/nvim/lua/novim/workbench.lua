-- novim/workbench.lua - Read-Only Git Diff Workbench
-- Part of novim custom derivative

local git = require("novim.git")

local M = {}

-- State
local state = {
  is_open = false,
  is_tab = false,
  tab_id = nil,
  is_git = false,
  repo_root = nil,
  has_head = false,
  files = {},
  stats = { modified = 0, untracked = 0, deleted = 0, added = 0, renamed = 0, total = 0 },
  err = nil,
  selected_index = 1,
  line_to_file_index = {},
  header_line_count = 4,
  buf_left = nil,
  win_left = nil,
  buf_right = nil,
  win_right = nil,
  ns_id = vim.api.nvim_create_namespace("novim_workbench"),
}

-- Ensure highlights are set up
local function setup_highlights()
  local function hl(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- Workbench UI highlights (Tokyo Night style)
  hl("WorkbenchHeader", { fg = "#7aa2f7", bold = true })
  hl("WorkbenchSubHeader", { fg = "#565f89", italic = true })
  hl("WorkbenchDivider", { fg = "#292e42" })
  hl("WorkbenchSummary", { fg = "#9aa5ce" })
  hl("WorkbenchClean", { fg = "#9ece6a", bold = true })
  hl("WorkbenchError", { fg = "#f7768e", bold = true })

  -- File status highlights
  hl("WorkbenchStatusM", { fg = "#e0af68", bold = true }) -- Modified (Yellow/Orange)
  hl("WorkbenchStatusA", { fg = "#9ece6a", bold = true }) -- Added (Green)
  hl("WorkbenchStatusU", { fg = "#7dcfff", bold = true }) -- Untracked (Cyan)
  hl("WorkbenchStatusD", { fg = "#f7768e", bold = true }) -- Deleted (Red)
  hl("WorkbenchStatusR", { fg = "#bb9af7", bold = true }) -- Renamed (Magenta)

  -- File paths & markers
  hl("WorkbenchPath", { fg = "#c0caf5" })
  hl("WorkbenchActiveMarker", { fg = "#7aa2f7", bold = true })
  hl("WorkbenchKeyHint", { fg = "#7aa2f7" })

  -- Diff syntax highlights
  hl("diffAdded", { fg = "#9ece6a" })
  hl("diffRemoved", { fg = "#f7768e" })
  hl("diffChanged", { fg = "#7aa2f7" })
  hl("diffFile", { fg = "#7dcfff", bold = true })
  hl("diffNewFile", { fg = "#9ece6a", bold = true })
  hl("diffOldFile", { fg = "#f7768e", bold = true })
  hl("diffLine", { fg = "#bb9af7" })
  hl("diffIndexLine", { fg = "#565f89" })
  hl("diffSubname", { fg = "#9aa5ce" })
end

--- Format summary line
---@param stats table
---@return string
local function format_summary(stats)
  if stats.total == 0 then
    return " ✓ Working tree clean (no changes vs HEAD)"
  end

  local parts = {}
  if stats.modified > 0 then
    table.insert(parts, stats.modified .. " modified")
  end
  if stats.untracked > 0 then
    table.insert(parts, stats.untracked .. " untracked")
  end
  if stats.added > 0 then
    table.insert(parts, stats.added .. " added")
  end
  if stats.deleted > 0 then
    table.insert(parts, stats.deleted .. " deleted")
  end
  if stats.renamed > 0 then
    table.insert(parts, stats.renamed .. " renamed")
  end

  return " Changes: " .. stats.total .. " (" .. table.concat(parts, ", ") .. ")"
end

--- Render the left pane (file list)
function M.render_left_pane()
  if not state.buf_left or not vim.api.nvim_buf_is_valid(state.buf_left) then
    return
  end

  vim.bo[state.buf_left].readonly = false
  vim.bo[state.buf_left].modifiable = true

  local lines = {}
  local highlights = {} -- list of { line, col_start, col_end, group }
  state.line_to_file_index = {}

  -- Line 1: Header
  table.insert(lines, " DIFF WORKBENCH (vs HEAD)")
  table.insert(highlights, { #lines - 1, 0, -1, "WorkbenchHeader" })

  -- Line 2: Divider
  table.insert(lines, " " .. string.rep("─", 38))
  table.insert(highlights, { #lines - 1, 0, -1, "WorkbenchDivider" })

  if not state.is_git then
    -- Not a git repo state
    table.insert(lines, " [Not a Git Repository]")
    table.insert(highlights, { #lines - 1, 1, -1, "WorkbenchError" })

    table.insert(lines, " Current directory is not a git worktree.")
    table.insert(highlights, { #lines - 1, 0, -1, "WorkbenchSubHeader" })

    table.insert(lines, " ")
    table.insert(lines, " Tip: Open novim-dev inside a Git repo.")
    table.insert(highlights, { #lines - 1, 0, -1, "WorkbenchSummary" })
  elseif state.err then
    -- Git error state
    table.insert(lines, " [Git Status Error]")
    table.insert(highlights, { #lines - 1, 1, -1, "WorkbenchError" })

    table.insert(lines, " " .. tostring(state.err))
    table.insert(highlights, { #lines - 1, 0, -1, "WorkbenchSubHeader" })
  elseif #state.files == 0 then
    -- Clean working tree state
    table.insert(lines, " ✓ Working tree clean")
    table.insert(highlights, { #lines - 1, 1, -1, "WorkbenchClean" })

    table.insert(lines, " No changed or untracked files relative to HEAD.")
    table.insert(highlights, { #lines - 1, 0, -1, "WorkbenchSubHeader" })

    table.insert(lines, " ")
    table.insert(lines, " " .. string.rep("─", 38))
    table.insert(highlights, { #lines - 1, 0, -1, "WorkbenchDivider" })

    table.insert(lines, " Press 'r' to refresh, '?' for help, 'q' to quit.")
    table.insert(highlights, { #lines - 1, 0, -1, "WorkbenchSummary" })
  else
    -- Summary line
    local summary = format_summary(state.stats)
    table.insert(lines, summary)
    table.insert(highlights, { #lines - 1, 0, -1, "WorkbenchSummary" })

    -- Line: Divider
    table.insert(lines, " " .. string.rep("─", 38))
    table.insert(highlights, { #lines - 1, 0, -1, "WorkbenchDivider" })

    state.header_line_count = #lines

    -- File entries
    for idx, file in ipairs(state.files) do
      local marker = (idx == state.selected_index) and "▶" or " "
      local status_label = file.status
      if status_label == "??" then
        status_label = "U "
      elseif #status_label == 1 then
        status_label = status_label .. " "
      end

      local display_name = file.path
      if file.orig_path then
        display_name = file.orig_path .. " -> " .. file.path
      end

      local line_text = string.format(" %s [%s] %s", marker, status_label, display_name)
      table.insert(lines, line_text)

      local line_idx = #lines - 1
      state.line_to_file_index[line_idx + 1] = idx

      -- Highlight marker
      if idx == state.selected_index then
        table.insert(highlights, { line_idx, 1, 2, "WorkbenchActiveMarker" })
      end

      -- Highlight status tag
      local hl_group = "WorkbenchStatusM"
      if file.status == "??" or file.status == "U" then
        hl_group = "WorkbenchStatusU"
      elseif file.status == "A" then
        hl_group = "WorkbenchStatusA"
      elseif file.status == "D" then
        hl_group = "WorkbenchStatusD"
      elseif file.status == "R" then
        hl_group = "WorkbenchStatusR"
      end

      table.insert(highlights, { line_idx, 3, 7, hl_group })
      table.insert(highlights, { line_idx, 8, -1, "WorkbenchPath" })
    end
  end

  vim.api.nvim_buf_set_lines(state.buf_left, 0, -1, false, lines)
  vim.bo[state.buf_left].modifiable = false
  vim.bo[state.buf_left].readonly = true

  -- Apply syntax highlights
  vim.api.nvim_buf_clear_namespace(state.buf_left, state.ns_id, 0, -1)
  for _, h in ipairs(highlights) do
    local end_col = h[3]
    if end_col == -1 then
      end_col = #lines[h[1] + 1]
    end
    pcall(vim.api.nvim_buf_add_highlight, state.buf_left, state.ns_id, h[4], h[1], h[2], end_col)
  end

  -- Position cursor on selected file line if left window is valid
  if state.win_left and vim.api.nvim_win_is_valid(state.win_left) and #state.files > 0 then
    local target_line = state.header_line_count + state.selected_index
    if target_line <= #lines then
      pcall(vim.api.nvim_win_set_cursor, state.win_left, { target_line, 1 })
    end
  end
end

--- Render the right pane (diff preview)
function M.render_right_pane()
  if not state.buf_right or not vim.api.nvim_buf_is_valid(state.buf_right) then
    return
  end

  vim.bo[state.buf_right].readonly = false
  vim.bo[state.buf_right].modifiable = true

  local lines = {}
  local is_diff_view = true

  if not state.is_git then
    is_diff_view = false
    lines = {
      "# ===================================================================",
      "# Diff Workbench (Read-Only)",
      "# ===================================================================",
      "#",
      "# Not a Git repository.",
      "# The current directory is not part of a Git working tree.",
      "#",
      "# To use the Diff Workbench:",
      "#   1. Navigate to a Git repository in your terminal.",
      "#   2. Run: novim-dev",
      "#",
      "# Shortcuts:",
      "#   [q] or [Esc Esc] Quit workbench",
      "#   [?]             Show help",
    }
  elseif state.err then
    is_diff_view = false
    lines = {
      "# ===================================================================",
      "# Git Status Error",
      "# ===================================================================",
      "#",
      "# Error details:",
      "# " .. tostring(state.err),
      "#",
      "# Press 'r' to retry / refresh.",
    }
  elseif #state.files == 0 then
    is_diff_view = false
    lines = {
      "# ===================================================================",
      "# Diff Workbench (vs HEAD)",
      "# ===================================================================",
      "#",
      "# ✓ Working tree is clean.",
      "# No modified, added, deleted, or untracked files found relative to HEAD.",
      "#",
      "# Shortcuts:",
      "#   [r]             Refresh Git status",
      "#   [q] or [Esc Esc] Quit workbench",
      "#   [?]             Show help",
    }
  else
    local file = state.files[state.selected_index]
    if file then
      local diff_lines, is_binary = git.get_file_diff(file, state.repo_root)
      if is_binary then
        is_diff_view = true
        lines = {
          "diff --git a/" .. file.path .. " b/" .. file.path,
          "# Binary file differs from HEAD",
          "# Path: " .. file.path,
          "# Status: " .. file.status .. " (" .. (file.is_untracked and "Untracked" or "Tracked") .. ")",
          "# Note: Binary content preview is not text-renderable in diff view.",
        }
        for _, l in ipairs(diff_lines) do
          table.insert(lines, l)
        end
      else
        lines = diff_lines
      end
    else
      is_diff_view = false
      lines = { "# No file selected" }
    end
  end

  vim.api.nvim_buf_set_lines(state.buf_right, 0, -1, false, lines)
  vim.bo[state.buf_right].modifiable = false
  vim.bo[state.buf_right].readonly = true

  if is_diff_view then
    vim.bo[state.buf_right].filetype = "diff"
  else
    vim.bo[state.buf_right].filetype = "conf"
  end
end

--- Select a specific file index and update preview
---@param index integer
function M.select_file(index)
  if #state.files == 0 then return end
  if index < 1 then index = 1 end
  if index > #state.files then index = #state.files end

  if state.selected_index ~= index then
    state.selected_index = index
    M.render_left_pane()
  end
  M.render_right_pane()
end

--- Refresh workbench data from git
function M.refresh()
  state.is_git, state.repo_root = git.get_repo_info()
  if state.is_git then
    state.has_head = git.has_head(state.repo_root)
    state.files, state.stats, state.err = git.get_changed_files(state.repo_root)
  else
    state.files = {}
    state.stats = { modified = 0, untracked = 0, deleted = 0, added = 0, renamed = 0, total = 0 }
    state.err = nil
  end

  if state.selected_index > #state.files then
    state.selected_index = math.max(1, #state.files)
  end

  M.render_left_pane()
  M.render_right_pane()
end

--- Handle cursor movement in left pane
local function on_left_cursor_moved()
  if not state.win_left or not vim.api.nvim_win_is_valid(state.win_left) then
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(state.win_left)
  local line_num = cursor[1]
  local file_idx = state.line_to_file_index[line_num]

  if file_idx and file_idx ~= state.selected_index then
    state.selected_index = file_idx
    M.render_left_pane()
    M.render_right_pane()
  end
end

--- Handle mouse click in left pane
local function on_left_click()
  local mouse = vim.fn.getmousepos()
  if mouse.winid == state.win_left then
    local file_idx = state.line_to_file_index[mouse.line]
    if file_idx then
      state.selected_index = file_idx
      M.render_left_pane()
      M.render_right_pane()
    end
  end
end

--- Show help popup
function M.show_help()
  local help_lines = {
    " novim-dev Diff Workbench (Read-Only)",
    " ────────────────────────────────────────────────",
    " Navigation:",
    "   j / k or ↑ / ↓   Move between changed files",
    "   Left Click       Select file and preview diff",
    "   Enter / Space    Select file and preview diff",
    "   Tab / S-Tab      Switch between file list and diff",
    "   Drag Divider     Resize left/right panes with mouse",
    "   r                Refresh Git status & diff",
    "   ?                Show this help",
    "   q or Esc Esc     Quit / Close workbench",
    " ────────────────────────────────────────────────",
    " Status Indicators:",
    "   [M ] Modified    Tracked file modified vs HEAD",
    "   [U ] Untracked   New untracked file (all additions)",
    "   [A ] Added       New file staged in index",
    "   [D ] Deleted     Tracked file deleted vs HEAD",
    "   [R ] Renamed     Tracked file renamed vs HEAD",
    " ────────────────────────────────────────────────",
    " Note: Workbench is strictly read-only.",
    " No git stage, commit, or discard operations exist.",
  }

  local width = 56
  local height = #help_lines + 2
  local row = math.max(1, math.floor((vim.o.lines - height) / 2))
  local col = math.max(1, math.floor((vim.o.columns - width) / 2))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Diff Workbench Help ",
    title_pos = "center",
  })

  local function close_help()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local keys = { "q", "<Esc>", "<CR>", "<Space>", "?" }
  for _, key in ipairs(keys) do
    vim.keymap.set("n", key, close_help, { buffer = buf, silent = true })
  end
end

--- Close workbench safely and preserve editor layout
---@param opts? { quit?: boolean }
function M.close(opts)
  if not state.is_open then
    return
  end

  opts = opts or {}
  local is_tab_mode = state.is_tab
  local tab_id = state.tab_id
  local all_tabs = vim.api.nvim_list_tabpages()

  -- If opened in a dedicated tab and multiple tabs exist, close the tab cleanly
  if is_tab_mode and #all_tabs > 1 and tab_id and vim.api.nvim_tabpage_is_valid(tab_id) then
    state.is_open = false
    state.is_tab = false
    state.tab_id = nil
    state.buf_left = nil
    state.win_left = nil
    state.buf_right = nil
    state.win_right = nil
    pcall(vim.cmd, "tabclose")
    return
  end

  -- If opened as a split alongside other editor windows
  local wins = {}
  if state.win_left and vim.api.nvim_win_is_valid(state.win_left) then
    table.insert(wins, state.win_left)
  end
  if state.win_right and vim.api.nvim_win_is_valid(state.win_right) then
    table.insert(wins, state.win_right)
  end

  local all_wins = vim.api.nvim_list_wins()

  if #all_wins > #wins then
    -- Other editor windows exist: close workbench windows without exiting Neovim
    state.is_open = false
    for _, w in ipairs(wins) do
      pcall(vim.api.nvim_win_close, w, true)
    end
    state.win_left = nil
    state.win_right = nil
    state.buf_left = nil
    state.buf_right = nil
    return
  end

  -- Workbench is the only UI
  if opts.quit then
    -- User explicitly pressed q in standalone startup mode: check unsaved buffers
    local unsaved = false
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified then
        unsaved = true
        break
      end
    end

    if unsaved then
      local ok = pcall(vim.cmd, "confirm qa")
      if not ok then
        return
      end
    else
      state.is_open = false
      pcall(vim.cmd, "qa")
    end
  else
    -- Programmatic close without quitting editor
    state.is_open = false
    if state.win_right and vim.api.nvim_win_is_valid(state.win_right) then
      pcall(vim.api.nvim_win_close, state.win_right, true)
    end
    if state.win_left and vim.api.nvim_win_is_valid(state.win_left) then
      local empty_buf = vim.api.nvim_create_buf(true, false)
      pcall(vim.api.nvim_win_set_buf, state.win_left, empty_buf)
    end
    state.win_left = nil
    state.win_right = nil
    state.buf_left = nil
    state.buf_right = nil
  end
end

--- Open the Diff Workbench
function M.open()
  setup_highlights()

  -- If already open, focus left window and refresh
  if state.is_open and state.win_left and vim.api.nvim_win_is_valid(state.win_left) then
    if state.tab_id and vim.api.nvim_tabpage_is_valid(state.tab_id) then
      vim.api.nvim_set_current_tabpage(state.tab_id)
    end
    vim.api.nvim_set_current_win(state.win_left)
    M.refresh()
    return
  end

  -- Ensure mouse is enabled and window minimum width is set
  vim.opt.mouse = "a"
  vim.opt.winminwidth = 15

  -- Check if we are opening from an existing editing session with active files/buffers
  local current_buf = vim.api.nvim_get_current_buf()
  local buf_name = vim.api.nvim_buf_get_name(current_buf)
  local is_modified = vim.bo[current_buf].modified
  local is_existing_session = (buf_name ~= "" or is_modified or #vim.api.nvim_list_wins() > 1 or #vim.api.nvim_list_tabpages() > 1)

  if is_existing_session then
    -- Open workbench in a dedicated tabpage so user's existing layout and unsaved edits remain intact
    vim.cmd("tabnew")
    state.is_tab = true
    state.tab_id = vim.api.nvim_get_current_tabpage()
  else
    vim.cmd("silent! only")
    state.is_tab = false
    state.tab_id = vim.api.nvim_get_current_tabpage()
  end

  -- Create buffers
  state.buf_left = vim.api.nvim_create_buf(false, true)
  state.buf_right = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_name(state.buf_left, "[Diff Workbench - Files]")
  vim.api.nvim_buf_set_name(state.buf_right, "[Diff Workbench - Preview]")

  for _, buf in ipairs({ state.buf_left, state.buf_right }) do
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].buflisted = false
  end

  -- Setup left window
  state.win_left = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win_left, state.buf_left)

  local total_cols = vim.o.columns
  local left_width = math.max(26, math.min(50, math.floor(total_cols * 0.32)))

  -- Setup right window via vertical split
  vim.cmd("rightbelow vsplit")
  state.win_right = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win_right, state.buf_right)

  -- Set left window width
  vim.api.nvim_win_set_width(state.win_left, left_width)

  -- Window options for left window
  local function set_win_opts(win, is_left)
    if not vim.api.nvim_win_is_valid(win) then return end
    vim.wo[win].number = not is_left
    vim.wo[win].relativenumber = false
    vim.wo[win].signcolumn = "no"
    vim.wo[win].wrap = false
    vim.wo[win].cursorline = is_left
    vim.wo[win].spell = false
    vim.wo[win].foldenable = false
    if is_left then
      vim.wo[win].statusline = " %f %=[↑/↓/Click] Select  [Tab] Diff  [r] Refresh  [?] Help  [Esc Esc] Quit "
    else
      vim.wo[win].statusline = " %f %=[Tab] Files  [r] Refresh  [?] Help  [Esc Esc] Quit "
    end
  end

  set_win_opts(state.win_left, true)
  set_win_opts(state.win_right, false)

  -- Keymaps for Left Buffer
  local function set_left_maps(buf)
    local opts = { buffer = buf, silent = true, noremap = true }

    -- Navigation
    vim.keymap.set("n", "j", function()
      if #state.files > 0 then
        local next_idx = math.min(#state.files, state.selected_index + 1)
        M.select_file(next_idx)
      end
    end, opts)

    vim.keymap.set("n", "k", function()
      if #state.files > 0 then
        local prev_idx = math.max(1, state.selected_index - 1)
        M.select_file(prev_idx)
      end
    end, opts)

    vim.keymap.set("n", "<Down>", function()
      if #state.files > 0 then
        local next_idx = math.min(#state.files, state.selected_index + 1)
        M.select_file(next_idx)
      end
    end, opts)

    vim.keymap.set("n", "<Up>", function()
      if #state.files > 0 then
        local prev_idx = math.max(1, state.selected_index - 1)
        M.select_file(prev_idx)
      end
    end, opts)

    vim.keymap.set("n", "<CR>", function()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local file_idx = state.line_to_file_index[cursor[1]]
      if file_idx then
        M.select_file(file_idx)
      end
    end, opts)

    vim.keymap.set("n", "<Space>", function()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local file_idx = state.line_to_file_index[cursor[1]]
      if file_idx then
        M.select_file(file_idx)
      end
    end, opts)

    -- Pane switching
    vim.keymap.set("n", "<Tab>", function()
      if state.win_right and vim.api.nvim_win_is_valid(state.win_right) then
        vim.api.nvim_set_current_win(state.win_right)
      end
    end, opts)

    -- Actions
    vim.keymap.set("n", "r", M.refresh, opts)
    vim.keymap.set("n", "<C-r>", M.refresh, opts)
    vim.keymap.set("n", "?", M.show_help, opts)
    vim.keymap.set("n", "q", function() M.close({ quit = true }) end, opts)
    vim.keymap.set("n", "<Esc><Esc>", function() M.close({ quit = true }) end, opts)
  end

  -- Keymaps for Right Buffer
  local function set_right_maps(buf)
    local opts = { buffer = buf, silent = true, noremap = true }

    -- Pane switching
    vim.keymap.set("n", "<Tab>", function()
      if state.win_left and vim.api.nvim_win_is_valid(state.win_left) then
        vim.api.nvim_set_current_win(state.win_left)
      end
    end, opts)

    vim.keymap.set("n", "<S-Tab>", function()
      if state.win_left and vim.api.nvim_win_is_valid(state.win_left) then
        vim.api.nvim_set_current_win(state.win_left)
      end
    end, opts)

    -- Actions
    vim.keymap.set("n", "r", M.refresh, opts)
    vim.keymap.set("n", "<C-r>", M.refresh, opts)
    vim.keymap.set("n", "?", M.show_help, opts)
    vim.keymap.set("n", "q", function() M.close({ quit = true }) end, opts)
    vim.keymap.set("n", "<Esc><Esc>", function() M.close({ quit = true }) end, opts)
  end

  set_left_maps(state.buf_left)
  set_right_maps(state.buf_right)

  -- Autocommands for cursor movement
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = state.buf_left,
    callback = on_left_cursor_moved,
  })

  -- Switch focus to left window
  vim.api.nvim_set_current_win(state.win_left)
  state.is_open = true

  -- Populate data
  M.refresh()
end

--- Get current workbench state for diagnostics / testing
---@return table
function M.get_state()
  return {
    is_open = state.is_open,
    is_tab = state.is_tab,
    tab_id = state.tab_id,
    is_git = state.is_git,
    repo_root = state.repo_root,
    has_head = state.has_head,
    file_count = #state.files,
    files = state.files,
    stats = state.stats,
    selected_index = state.selected_index,
    header_line_count = state.header_line_count,
    win_left = state.win_left,
    win_right = state.win_right,
    buf_left = state.buf_left,
    buf_right = state.buf_right,
  }
end

return M
