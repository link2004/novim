----------------------------------------------------------------------
-- novim - A friendly terminal editor for vibe coders
-- https://github.com/link2004/novim
--
-- Features:
--   - Mouse-based operation
--   - Standard shortcuts (Ctrl+S, Ctrl+Z, etc.)
--   - File tree on the left
--   - No vim knowledge required
--
-- Credits:
--   - Neovim (Apache 2.0 / Vim License) - https://neovim.io
--   - gitsigns.nvim (MIT) - Lewis Russell
--   - Tokyo Night color palette (MIT) - enkia
----------------------------------------------------------------------


----------------------------------------------------------------------
-- 1. Color Scheme (application-owned built-in themes)
----------------------------------------------------------------------

-- The default palette is Tokyo Night. The workbench Settings panel can
-- switch at runtime to any of the six application-owned built-in themes
-- (Tokyo Night, Nord, Gruvbox Dark, Catppuccin Mocha, One Dark, Solarized
-- Light) through `novim.themes`; no plugin or external colorscheme is used.
vim.cmd("highlight clear")
require("novim.themes").apply("tokyo_night")


----------------------------------------------------------------------
-- 2. Display and Input Settings
----------------------------------------------------------------------

vim.opt.number = true
vim.opt.relativenumber = false

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2

vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.termguicolors = true

-- Hide mode display (INSERT/NORMAL) for VSCode-like feel
vim.opt.showmode = false

-- Always show statusline
vim.opt.laststatus = 2

-- Dynamic statusline with hints (set up later in hints section)

-- Allow cursor to go one past end of line (for right-edge click)
vim.opt.virtualedit = "onemore"

-- Make Backspace work properly in Insert mode
vim.opt.backspace = { "indent", "eol", "start" }


----------------------------------------------------------------------
-- 3. Mouse Settings
----------------------------------------------------------------------

vim.opt.mouse = "a"
vim.opt.mousemodel = "extend"

-- Share clipboard with OS
vim.opt.clipboard = "unnamedplus"


----------------------------------------------------------------------
-- 4. Highlight Changed Lines
----------------------------------------------------------------------

-- ChangedLine highlight color is owned by the active theme (novim.themes).

-- Track changed lines and highlight them
local changed_lines = {}
local highlight_ns = vim.api.nvim_create_namespace("changed_lines")

vim.api.nvim_create_autocmd("TextChangedI", {
  pattern = "*",
  callback = function()
    local line = vim.fn.line(".")
    local buf = vim.api.nvim_get_current_buf()
    changed_lines[buf] = changed_lines[buf] or {}
    changed_lines[buf][line] = true

    -- Apply highlight
    vim.api.nvim_buf_add_highlight(buf, highlight_ns, "ChangedLine", line - 1, 0, -1)
  end,
})

-- Clear highlights on save
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*",
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(buf, highlight_ns, 0, -1)
    changed_lines[buf] = {}
  end,
})


----------------------------------------------------------------------
-- 5. Backspace / Delete Support
-- Handle terminal differences (<BS> / <C-h>)
----------------------------------------------------------------------

-- Normal mode: delete one character
vim.keymap.set("n", "<BS>", "X", { silent = true })
vim.keymap.set("n", "<C-h>", "X", { silent = true })

-- Visual mode: delete selection
vim.keymap.set("v", "<BS>", '"_d', { silent = true })
vim.keymap.set("v", "<C-h>", '"_d', { silent = true })
vim.keymap.set("v", "<Del>", '"_d', { silent = true })

-- Visual mode: typing replaces selection (VSCode-like)
-- Printable ASCII characters (32-126) replace selection and enter insert mode
for i = 32, 126 do
  local char = string.char(i)
  -- Skip special keys that need different handling
  if char ~= "\\" then
    vim.keymap.set("v", char, '"_c' .. char, { noremap = true, silent = true })
  end
end
vim.keymap.set("v", "\\", '"_c\\', { noremap = true, silent = true })

-- Enter also replaces selection with newline
vim.keymap.set("v", "<CR>", '"_c<CR>', { noremap = true, silent = true })

-- Normal mode: typing enters insert mode (VSCode-like)
-- Printable ASCII characters (32-126) enter insert mode and type
for i = 32, 126 do
  local char = string.char(i)
  -- Skip ? (used for help) and \ (needs escaping)
  if char ~= "?" and char ~= "\\" then
    vim.keymap.set("n", char, "i" .. char, { noremap = true, silent = true })
  end
end
vim.keymap.set("n", "\\", "i\\", { noremap = true, silent = true })

-- Enter in normal mode starts new line
vim.keymap.set("n", "<CR>", "i<CR>", { noremap = true, silent = true })


----------------------------------------------------------------------
-- 6. Ctrl / Cmd Shortcuts
----------------------------------------------------------------------

-- Select all
vim.keymap.set({ "n", "i", "v" }, "<C-a>", "<Esc>ggVG", { silent = true })
vim.keymap.set({ "n", "i", "v" }, "<D-a>", "<Esc>ggVG", { silent = true })

-- Save (with friendly message)
local function save_file()
  vim.cmd("stopinsert")
  local ok, err = pcall(vim.cmd, "silent write")
  if ok then
    vim.api.nvim_echo({{ "Saved!", "String" }}, false, {})
  else
    vim.api.nvim_echo({{ "Error: " .. err, "ErrorMsg" }}, false, {})
  end
end
vim.keymap.set({ "n", "i", "v" }, "<C-s>", save_file, { silent = true })
vim.keymap.set({ "n", "i", "v" }, "<D-s>", save_file, { silent = true })

-- Undo
vim.keymap.set({ "n", "i", "v" }, "<C-z>", "<Esc>u", { silent = true })
vim.keymap.set({ "n", "i", "v" }, "<D-z>", "<Esc>u", { silent = true })

-- Redo
vim.keymap.set({ "n", "i", "v" }, "<C-S-z>", "<Esc><C-r>", { silent = true })
vim.keymap.set({ "n", "i", "v" }, "<D-S-z>", "<Esc><C-r>", { silent = true })

-- Copy (keep selection after copy)
vim.keymap.set("v", "<C-c>", '"+ygv', { silent = true })
vim.keymap.set("v", "<D-c>", '"+ygv', { silent = true })

-- Paste
vim.keymap.set({ "n", "i", "v" }, "<C-v>", '"+p', { silent = true })
vim.keymap.set({ "n", "i", "v" }, "<D-v>", '"+p', { silent = true })

-- Shift+Arrow: Select text (VSCode-like)
-- From normal mode: start visual selection
vim.keymap.set("n", "<S-Left>", "vh", { silent = true })
vim.keymap.set("n", "<S-Right>", "vl", { silent = true })
vim.keymap.set("n", "<S-Up>", "vk", { silent = true })
vim.keymap.set("n", "<S-Down>", "vj", { silent = true })

-- From insert mode: exit to visual and select
vim.keymap.set("i", "<S-Left>", "<Esc>vh", { silent = true })
vim.keymap.set("i", "<S-Right>", "<Esc>vl", { silent = true })
vim.keymap.set("i", "<S-Up>", "<Esc>vk", { silent = true })
vim.keymap.set("i", "<S-Down>", "<Esc>vj", { silent = true })

-- From visual mode: extend selection
vim.keymap.set("v", "<S-Left>", "h", { silent = true })
vim.keymap.set("v", "<S-Right>", "l", { silent = true })
vim.keymap.set("v", "<S-Up>", "k", { silent = true })
vim.keymap.set("v", "<S-Down>", "j", { silent = true })


----------------------------------------------------------------------
-- 7. File Tree (netrw)
----------------------------------------------------------------------

vim.g.netrw_browse_split = 4   -- Open selected file in right pane
vim.g.netrw_altv = 1           -- Vertical split opens on right
vim.g.netrw_liststyle = 3      -- Tree view
vim.g.netrw_banner = 0         -- Hide banner
vim.g.netrw_winsize = 33       -- Tree takes 1/3 (leaving 2/3 for editor)

-- Fix mouse behavior in netrw
vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  callback = function()
    -- Single click: move cursor (default)
    -- Double click: open/expand (same as Enter)
    vim.keymap.set("n", "<2-LeftMouse>", "<CR>", { buffer = true, silent = true })

    -- Ctrl+click: open file with system default app (for images, etc.)
    vim.keymap.set("n", "<C-LeftMouse>", function()
      -- Move cursor to click position first
      local mouse_pos = vim.fn.getmousepos()
      if mouse_pos.line > 0 then
        vim.api.nvim_win_set_cursor(0, { mouse_pos.line, 0 })
      end

      -- Get the file name from current line (netrw tree format)
      local line = vim.fn.getline(".")
      -- Extract filename: last non-space sequence after tree characters
      local file = line:match("[^%s│├└─]+$")
      if not file or file == "" then return end

      -- Get the current directory from netrw
      local dir = vim.b.netrw_curdir or vim.fn.getcwd()
      local filepath = dir .. "/" .. file

      -- Check if it's a file (not a directory)
      if vim.fn.isdirectory(filepath) == 1 then
        -- It's a directory, just expand it normally
        vim.cmd("normal \\<CR>")
        return
      end

      -- Check if file exists
      if vim.fn.filereadable(filepath) == 0 then return end

      -- Open with system default app
      local cmd
      if vim.fn.has("mac") == 1 then
        cmd = "open"
      elseif vim.fn.has("unix") == 1 then
        cmd = "xdg-open"
      elseif vim.fn.has("win32") == 1 then
        cmd = "start"
      else
        vim.api.nvim_echo({{"Cannot detect OS for opening files", "WarningMsg"}}, false, {})
        return
      end

      vim.fn.jobstart({ cmd, filepath }, { detach = true })
      vim.api.nvim_echo({{"Opened: " .. file, "String"}}, false, {})
    end, { buffer = true, silent = true })
  end,
})


----------------------------------------------------------------------
-- 8. Help Screen (Press ? to show)
----------------------------------------------------------------------

local function show_help()
  local lines = {
    "",
    "              Welcome to novim",
    "",
    "  EDITING",
    "    Click anywhere      Move cursor",
    "    Type                Insert text",
    "    Drag to select      Select text",
    "",
    "  SHORTCUTS",
    "    Ctrl+S              Save",
    "    Ctrl+Z              Undo",
    "    Ctrl+Shift+Z        Redo",
    "    Ctrl+A              Select all",
    "    Ctrl+C              Copy",
    "    Ctrl+V              Paste",
    "",
    "  GIT",
    "    Ctrl+G              Git status",
    "    Ctrl+L              Git log",
    "    Ctrl+D              Git diff",
    "",
    "  FILE TREE",
    "    Double-click        Open file",
    "    Ctrl+click          Open externally",
    "",
    "  EXIT",
    "    Esc Esc             Quit",
    "",
    "        Press any key to close...",
    "",
  }

  local width = 46
  local height = #lines
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  -- Close on any key (and delete buffer to prevent memory leak)
  local function close_help()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end

  local close_keys = { "<CR>", "q", "<Esc>", "<Space>", "<BS>", "?" }
  for _, key in ipairs(close_keys) do
    vim.api.nvim_buf_set_keymap(buf, "n", key, "", {
      callback = close_help,
      noremap = true,
      silent = true,
    })
  end
end

-- Press ? to show help
vim.keymap.set("n", "?", show_help, { silent = true })


----------------------------------------------------------------------
-- 9. Dynamic Hints (in statusline)
----------------------------------------------------------------------

-- Generate hints for editor (dynamic based on state)
function _G.get_editor_hints()
  local mode = vim.fn.mode()
  local modified = vim.bo.modified

  if mode == "v" or mode == "V" or mode == "\22" then
    return "^C Copy  ^X Cut  ^A All"
  elseif modified then
    return "^S Save  ^Z Undo"
  else
    return "^V Paste  ^A All"
  end
end

-- Set statusline based on buffer type
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "FileType" }, {
  pattern = "*",
  callback = function()
    local ft = vim.bo.filetype
    if ft == "netrw" then
      -- File tree: Quit/Open (left), Git (center), Help (right)
      vim.wo.statusline = " Esc×2 Quit  ^Click Open%=Git: ^G ^L ^D%=? Help "
    else
      -- Editor: filename left, editor hints right
      vim.wo.statusline = " %f%m%=%{v:lua.get_editor_hints()} "
    end
  end,
})


----------------------------------------------------------------------
-- 10. Startup Layout
-- Opens file tree on left, editor on right
----------------------------------------------------------------------

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() > 0 then return end

    -- Open the Project Browser Workbench
    local ok, workbench = pcall(require, "novim.workbench")
    if ok and workbench then
      workbench.open({ view = "files" })
    end
  end,
})


----------------------------------------------------------------------
-- 11. Exit
----------------------------------------------------------------------

local function quit_with_confirm()
  -- Check for unsaved buffers
  local unsaved = false
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified then
      unsaved = true
      break
    end
  end

  -- No unsaved changes, just quit
  if not unsaved then
    vim.cmd("qa")
    return
  end

  -- Show options
  vim.ui.select(
    { "Save and Quit", "Quit without Saving", "Cancel" },
    { prompt = "You have unsaved changes:" },
    function(choice)
      if choice == "Save and Quit" then
        vim.cmd("wa")
        vim.cmd("qa")
      elseif choice == "Quit without Saving" then
        vim.cmd("qa!")
      end
      -- Cancel = do nothing
    end
  )
end

-- Press Esc twice to quit (with confirmation if unsaved)
vim.keymap.set("n", "<Esc><Esc>", quit_with_confirm, { silent = true })


----------------------------------------------------------------------
-- 12. Git Signs (show changed lines)
----------------------------------------------------------------------

require("gitsigns").setup({
  signs = {
    add          = { text = "│" },
    change       = { text = "│" },
    delete       = { text = "_" },
    topdelete    = { text = "‾" },
    changedelete = { text = "~" },
  },
  signs_staged = {
    add          = { text = "│" },
    change       = { text = "│" },
    delete       = { text = "_" },
    topdelete    = { text = "‾" },
    changedelete = { text = "~" },
  },
  signcolumn = true,
  numhl = false,
  linehl = false,
  word_diff = false,
  current_line_blame = false,  -- Set to true to show git blame inline
})

-- Gitsigns colors are owned by the active theme (novim.themes).


----------------------------------------------------------------------
-- 13. Git Shortcuts
----------------------------------------------------------------------

-- Show git status in a floating window
local function show_git_status()
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.6)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Git Status ",
    title_pos = "center",
  })

  vim.fn.termopen("git status", {
    on_exit = function()
      vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
        callback = function()
          vim.api.nvim_win_close(win, true)
        end,
        noremap = true,
        silent = true,
      })
      vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "", {
        callback = function()
          vim.api.nvim_win_close(win, true)
        end,
        noremap = true,
        silent = true,
      })
    end,
  })
  vim.cmd("startinsert")
end

-- Show git log in a floating window
local function show_git_log()
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.7)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Git Log ",
    title_pos = "center",
  })

  vim.fn.termopen("git log --oneline --graph --decorate -30", {
    on_exit = function()
      vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
        callback = function()
          vim.api.nvim_win_close(win, true)
        end,
        noremap = true,
        silent = true,
      })
      vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "", {
        callback = function()
          vim.api.nvim_win_close(win, true)
        end,
        noremap = true,
        silent = true,
      })
    end,
  })
  vim.cmd("startinsert")
end

-- Workbench & Project Browser
local function open_workbench(opts)
  local ok, workbench = pcall(require, "novim.workbench")
  if ok and workbench then
    workbench.open(opts)
  end
end

local function open_settings()
  local ok, workbench = pcall(require, "novim.workbench")
  if ok and workbench then
    workbench.open_settings()
  else
    local s_ok, settings_ui = pcall(require, "novim.settings_ui")
    if s_ok and settings_ui then
      settings_ui.open()
    end
  end
end

vim.api.nvim_create_user_command("Workbench", function() open_workbench() end, { desc = "Open Workbench" })
vim.api.nvim_create_user_command("DiffWorkbench", function() open_workbench({ view = "diff" }) end, { desc = "Open Git Diff Workbench" })
vim.api.nvim_create_user_command("ProjectBrowser", function() open_workbench({ view = "files" }) end, { desc = "Open Project File Browser" })
vim.api.nvim_create_user_command("Files", function() open_workbench({ view = "files" }) end, { desc = "Open Project File Browser" })
vim.api.nvim_create_user_command("Settings", open_settings, { desc = "Open novim-dev Settings" })

-- Ctrl+G / Cmd+G: Git status
vim.keymap.set({ "n", "i", "v" }, "<C-g>", show_git_status, { silent = true })
vim.keymap.set({ "n", "i", "v" }, "<D-g>", show_git_status, { silent = true })

-- Ctrl+L / Cmd+L: Git log
vim.keymap.set({ "n", "i", "v" }, "<C-l>", show_git_log, { silent = true })
vim.keymap.set({ "n", "i", "v" }, "<D-l>", show_git_log, { silent = true })

-- Ctrl+D / Cmd+D: Git diff workbench
vim.keymap.set({ "n", "i", "v" }, "<C-d>", function() open_workbench({ view = "diff" }) end, { silent = true, desc = "Open Diff Workbench" })
vim.keymap.set({ "n", "i", "v" }, "<D-d>", function() open_workbench({ view = "diff" }) end, { silent = true, desc = "Open Diff Workbench" })

-- Ctrl+E / Cmd+E: Project file browser
vim.keymap.set({ "n", "i", "v" }, "<C-e>", function() open_workbench({ view = "files" }) end, { silent = true, desc = "Open Project Browser" })
vim.keymap.set({ "n", "i", "v" }, "<D-e>", function() open_workbench({ view = "files" }) end, { silent = true, desc = "Open Project Browser" })
