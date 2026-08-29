-- tests/test_workbench.lua
-- Comprehensive unit and integration test suite for novim diff workbench and project browser
-- Part of novim custom derivative

local function assert_true(cond, msg)
  if not cond then
    error("Assertion failed: " .. (msg or "expected true, got false"), 2)
  end
end

local function assert_eq(actual, expected, msg)
  if actual ~= expected then
    error(string.format("Assertion failed: %s (expected %s, got %s)", msg or "values not equal", vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

local function create_fixture_repo()
  local fixture_dir = vim.fn.tempname() .. "_fixture_repo"
  vim.fn.mkdir(fixture_dir, "p")

  local function run_cmd(cmd)
    local out = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
      error("Command failed: " .. cmd .. "\nOutput: " .. out)
    end
    return out
  end

  run_cmd("git -C " .. vim.fn.shellescape(fixture_dir) .. " init -q")
  run_cmd("git -C " .. vim.fn.shellescape(fixture_dir) .. " config user.email 'test@example.com'")
  run_cmd("git -C " .. vim.fn.shellescape(fixture_dir) .. " config user.name 'Test Runner'")

  -- Commit 1: base files
  local file1 = fixture_dir .. "/tracked_modified.txt"
  local f1 = io.open(file1, "w")
  f1:write("initial line 1\ninitial line 2\ninitial line 3\n")
  f1:close()

  local file2 = fixture_dir .. "/tracked_deleted.txt"
  local f2 = io.open(file2, "w")
  f2:write("to be deleted\n")
  f2:close()

  local file3 = fixture_dir .. "/tracked_clean.txt"
  local f3 = io.open(file3, "w")
  f3:write("stays clean\n")
  f3:close()

  local file_rename = fixture_dir .. "/base_rename.txt"
  local f_ren = io.open(file_rename, "w")
  f_ren:write("rename base content\n")
  f_ren:close()

  run_cmd("git -C " .. vim.fn.shellescape(fixture_dir) .. " add .")
  run_cmd("git -C " .. vim.fn.shellescape(fixture_dir) .. " commit -q -m 'Initial commit'")

  -- Working tree modifications:
  -- 1. Modify tracked_modified.txt
  local f1_mod = io.open(file1, "w")
  f1_mod:write("initial line 1\nMODIFIED line 2\ninitial line 3\nNEW line 4\n")
  f1_mod:close()

  -- 2. Delete tracked_deleted.txt
  os.remove(file2)

  -- 3. Rename base_rename.txt to a path containing literal arrow ' -> '
  run_cmd("git -C " .. vim.fn.shellescape(fixture_dir) .. " mv base_rename.txt \"renamed -> destination.txt\"")

  -- 4. Create untracked file with regular name
  local file_untracked = fixture_dir .. "/untracked_new.txt"
  local f_untracked = io.open(file_untracked, "w")
  f_untracked:write("untracked line 1\nuntracked line 2\n")
  f_untracked:close()

  -- 5. Create untracked file with literal arrow
  local file_arrow = fixture_dir .. "/arrow -> name.txt"
  local f_arrow = io.open(file_arrow, "w")
  f_arrow:write("arrow content\n")
  f_arrow:close()

  -- 6. Create untracked file with quote
  local file_quote = fixture_dir .. "/quote\"name.txt"
  local f_quote = io.open(file_quote, "w")
  f_quote:write("quote content\n")
  f_quote:close()

  -- 7. Create untracked file with tab
  local file_tab = fixture_dir .. "/tab\tname.txt"
  local f_tab = io.open(file_tab, "w")
  f_tab:write("tab content\n")
  f_tab:close()

  -- 8. Create untracked file with unicode
  local file_uni = fixture_dir .. "/unicode_ğüşıöç.txt"
  local f_uni = io.open(file_uni, "w")
  f_uni:write("unicode content\n")
  f_uni:close()

  -- 9. Create untracked binary file
  local file_bin = fixture_dir .. "/binary_file.bin"
  local f_bin = io.open(file_bin, "wb")
  f_bin:write("\0\1\2\3\4\5\255\254")
  f_bin:close()

  return fixture_dir
end

--- Create a fixture project with regular files, directories, top-level dotfiles, and nested dot-folders
local function create_project_browser_fixture()
  local dir = vim.fn.tempname() .. "_browser_fixture"
  vim.fn.mkdir(dir, "p")

  -- Top-level regular files
  local f1 = io.open(dir .. "/main.lua", "w")
  f1:write("print('hello world')\n")
  f1:close()

  local f2 = io.open(dir .. "/README.md", "w")
  f2:write("# Fixture Project\nDocumentation.\n")
  f2:close()

  -- Regular subdirectories with files
  vim.fn.mkdir(dir .. "/src", "p")
  local f3 = io.open(dir .. "/src/utils.lua", "w")
  f3:write("local M = {}\nreturn M\n")
  f3:close()

  -- Nested regular folder inside src for lazy expansion tests
  vim.fn.mkdir(dir .. "/src/nested", "p")
  local f5 = io.open(dir .. "/src/nested/deep.lua", "w")
  f5:write("return 'deep'\n")
  f5:close()

  vim.fn.mkdir(dir .. "/docs", "p")
  local f4 = io.open(dir .. "/docs/guide.md", "w")
  f4:write("# User Guide\n")
  f4:close()

  -- Top-level dotfiles
  local d1 = io.open(dir .. "/.env", "w")
  d1:write("SECRET=123\n")
  d1:close()

  local d2 = io.open(dir .. "/.gitignore", "w")
  d2:write(".env\n")
  d2:close()

  -- Top-level dot-folders with nested contents
  vim.fn.mkdir(dir .. "/.vscode", "p")
  local d3 = io.open(dir .. "/.vscode/settings.json", "w")
  d3:write("{\"editor.tabSize\": 2}\n")
  d3:close()

  vim.fn.mkdir(dir .. "/.github/workflows", "p")
  local d4 = io.open(dir .. "/.github/workflows/ci.yml", "w")
  d4:write("name: CI\n")
  d4:close()

  -- Nested dot-folder inside a regular folder
  vim.fn.mkdir(dir .. "/src/.secret_module", "p")
  local d5 = io.open(dir .. "/src/.secret_module/token.lua", "w")
  d5:write("return 'secret'\n")
  d5:close()

  -- Nested dotfile inside a regular folder
  local d6 = io.open(dir .. "/docs/.hidden_note", "w")
  d6:write("hidden note\n")
  d6:close()

  return dir
end

local function cleanup_dir(dir)
  vim.fn.delete(dir, "rf")
end

local tests = {}

-- =========================================================================
-- TASK-002 Regression Tests (Git Diff Workbench)
-- =========================================================================

function tests.test_git_module_special_paths()
  local git = require("novim.git")
  assert_true(git.is_git_available(), "git must be available")

  local fixture = create_fixture_repo()
  local is_git, repo_root = git.get_repo_info(fixture)
  assert_true(is_git, "must identify git repo")
  assert_true(git.has_head(fixture), "must detect HEAD commit")

  local files, stats, err = git.get_changed_files(fixture)
  assert_true(err == nil, "no error getting changed files: " .. tostring(err))

  local file_map = {}
  for _, f in ipairs(files) do
    file_map[f.path] = f
  end

  local f_arrow = file_map["arrow -> name.txt"]
  assert_true(f_arrow ~= nil, "arrow -> name.txt must be discovered accurately")
  assert_eq(f_arrow.status, "??", "arrow file status must be ??")
  local arrow_diff, _ = git.get_file_diff(f_arrow, fixture)
  assert_true(#arrow_diff > 0, "arrow diff must be non-empty")
  assert_true(table.concat(arrow_diff, "\n"):find("+arrow content") ~= nil, "arrow diff must render content")

  local f_quote = file_map["quote\"name.txt"]
  assert_true(f_quote ~= nil, "quote\"name.txt must be discovered accurately")
  assert_eq(f_quote.status, "??", "quote file status must be ??")
  local quote_diff, _ = git.get_file_diff(f_quote, fixture)
  assert_true(#quote_diff > 0, "quote diff must be non-empty")
  assert_true(table.concat(quote_diff, "\n"):find("+quote content") ~= nil, "quote diff must render content")

  local f_tab = file_map["tab\tname.txt"]
  assert_true(f_tab ~= nil, "tab\\tname.txt must be discovered accurately")
  assert_eq(f_tab.status, "??", "tab file status must be ??")
  local tab_diff, _ = git.get_file_diff(f_tab, fixture)
  assert_true(#tab_diff > 0, "tab diff must be non-empty")
  assert_true(table.concat(tab_diff, "\n"):find("+tab content") ~= nil, "tab diff must render content")

  local f_uni = file_map["unicode_ğüşıöç.txt"]
  assert_true(f_uni ~= nil, "unicode_ğüşıöç.txt must be discovered accurately")
  assert_eq(f_uni.status, "??", "unicode file status must be ??")
  local uni_diff, _ = git.get_file_diff(f_uni, fixture)
  assert_true(#uni_diff > 0, "unicode diff must be non-empty")
  assert_true(table.concat(uni_diff, "\n"):find("+unicode content") ~= nil, "unicode diff must render content")

  local f_ren = file_map["renamed -> destination.txt"]
  assert_true(f_ren ~= nil, "renamed -> destination.txt must be discovered")
  assert_eq(f_ren.orig_path, "base_rename.txt", "orig_path must be base_rename.txt")
  assert_eq(f_ren.status, "R", "status must be R")

  local f_bin = file_map["binary_file.bin"]
  assert_true(f_bin ~= nil, "binary_file.bin must be discovered")
  local _, is_bin = git.get_file_diff(f_bin, fixture)
  assert_true(is_bin, "binary file must be identified as binary")

  cleanup_dir(fixture)
end

function tests.test_workbench_close_editor_state()
  local workbench = require("novim.workbench")
  workbench.close()

  local fixture = create_fixture_repo()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  local test_buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(test_buf)
  vim.api.nvim_buf_set_name(test_buf, fixture .. "/edited_unsaved.txt")
  vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, { "unsaved line 1", "unsaved line 2" })
  vim.bo[test_buf].modified = true

  workbench.open({ view = "diff" })
  local state_open = workbench.get_state()
  assert_true(state_open.is_open, "workbench must be open")
  assert_true(state_open.is_tab, "workbench must be opened in dedicated tabpage")

  workbench.close()
  local state_closed = workbench.get_state()
  assert_true(not state_closed.is_open, "workbench must be closed")

  local cur_buf = vim.api.nvim_get_current_buf()
  assert_eq(cur_buf, test_buf, "current buffer must be the original edited buffer")
  assert_true(vim.bo[cur_buf].modified, "buffer modified flag must remain true")
  local cur_lines = vim.api.nvim_buf_get_lines(cur_buf, 0, -1, false)
  assert_eq(cur_lines[1], "unsaved line 1", "unsaved content must remain intact")

  vim.bo[test_buf].modified = false
  vim.api.nvim_buf_delete(test_buf, { force = true })

  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

function tests.test_left_pane_mouse_selection_no_e21()
  local workbench = require("novim.workbench")
  workbench.close()

  local fixture = create_fixture_repo()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  workbench.open({ view = "diff" })
  local state = workbench.get_state()
  assert_true(state.is_open, "workbench must be open")
  assert_true(state.git_file_count >= 4, "must have loaded changed files")

  local line_count = vim.api.nvim_buf_line_count(state.buf_left)
  for line_num = state.header_line_count + 1, math.min(line_count, state.header_line_count + 3) do
    local ok, err = pcall(vim.api.nvim_win_set_cursor, state.win_left, { line_num, 2 })
    assert_true(ok, "cursor movement on left pane must succeed without error: " .. tostring(err))
    vim.cmd("doautocmd CursorMoved")
  end

  workbench.close()
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

function tests.test_mouse_divider_drag_and_status_invariance()
  local workbench = require("novim.workbench")
  workbench.close()

  local fixture = create_fixture_repo()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  local before_status = vim.system({ "git", "-C", fixture, "status", "--porcelain=v1", "-z", "-uall" }, { text = true }):wait().stdout
  local before_diff = vim.system({ "git", "-C", fixture, "diff", "HEAD" }, { text = true }):wait().stdout

  workbench.open({ view = "diff" })

  local state = workbench.get_state()
  assert_true(state.is_open, "workbench must be open")

  local initial_left_width = vim.api.nvim_win_get_width(state.win_left)
  assert_true(initial_left_width >= 15, "initial width must respect minimum width")

  local target_widen = initial_left_width + 10
  vim.api.nvim_win_set_width(state.win_left, target_widen)
  local widened_left_width = vim.api.nvim_win_get_width(state.win_left)
  assert_eq(widened_left_width, target_widen, "left pane width must increase on widen")

  local target_narrow = initial_left_width - 5
  vim.api.nvim_win_set_width(state.win_left, target_narrow)
  local narrowed_left_width = vim.api.nvim_win_get_width(state.win_left)
  assert_eq(narrowed_left_width, target_narrow, "left pane width must decrease on narrow")

  assert_true(vim.o.winminwidth >= 15, "winminwidth must be >= 15")
  assert_true(narrowed_left_width >= 15, "left pane width must be >= winminwidth")

  workbench.close()

  local after_status = vim.system({ "git", "-C", fixture, "status", "--porcelain=v1", "-z", "-uall" }, { text = true }):wait().stdout
  local after_diff = vim.system({ "git", "-C", fixture, "diff", "HEAD" }, { text = true }):wait().stdout

  assert_eq(after_status, before_status, "Git status --porcelain -z must be byte-for-byte identical before and after workbench interactions")
  assert_eq(after_diff, before_diff, "Git diff HEAD must be byte-for-byte identical before and after workbench interactions")

  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

function tests.test_non_git_directory()
  local workbench = require("novim.workbench")
  workbench.close()

  local temp_dir = vim.fn.tempname() .. "_nongit"
  vim.fn.mkdir(temp_dir, "p")
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(temp_dir))

  workbench.open({ view = "diff" })

  local state = workbench.get_state()
  assert_true(not state.is_git, "must detect non-git directory")
  assert_eq(state.git_file_count, 0, "git file count must be 0")

  local left_lines = vim.api.nvim_buf_get_lines(state.buf_left, 0, -1, false)
  local left_text = table.concat(left_lines, "\n")
  assert_true(left_text:find("Not a Git Repository") ~= nil, "left pane must state not a git repository")

  local right_lines = vim.api.nvim_buf_get_lines(state.buf_right, 0, -1, false)
  local right_text = table.concat(right_lines, "\n")
  assert_true(right_text:find("Not a Git repository") ~= nil, "right pane must state not a git repository")

  workbench.close()
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(temp_dir)
end

function tests.test_clean_repository()
  local workbench = require("novim.workbench")
  workbench.close()

  local fixture_dir = vim.fn.tempname() .. "_clean_repo"
  vim.fn.mkdir(fixture_dir, "p")
  vim.fn.system("git -C " .. vim.fn.shellescape(fixture_dir) .. " init -q")
  vim.fn.system("git -C " .. vim.fn.shellescape(fixture_dir) .. " config user.email 'test@example.com'")
  vim.fn.system("git -C " .. vim.fn.shellescape(fixture_dir) .. " config user.name 'Test Runner'")

  local f = io.open(fixture_dir .. "/clean.txt", "w")
  f:write("clean content\n")
  f:close()

  vim.fn.system("git -C " .. vim.fn.shellescape(fixture_dir) .. " add .")
  vim.fn.system("git -C " .. vim.fn.shellescape(fixture_dir) .. " commit -q -m 'Clean commit'")

  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture_dir))

  workbench.open({ view = "diff" })

  local state = workbench.get_state()
  assert_true(state.is_git, "must be git repo")
  assert_eq(state.git_file_count, 0, "git file count must be 0 for clean repo")

  local left_lines = vim.api.nvim_buf_get_lines(state.buf_left, 0, -1, false)
  local left_text = table.concat(left_lines, "\n")
  assert_true(left_text:find("Working tree clean") ~= nil, "left pane must show working tree clean")

  local right_lines = vim.api.nvim_buf_get_lines(state.buf_right, 0, -1, false)
  local right_text = table.concat(right_lines, "\n")
  assert_true(right_text:find("Working tree is clean") ~= nil, "right pane must show clean message")

  workbench.close()
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture_dir)
end

-- =========================================================================
-- TASK-003 New Feature Tests (Project Browser & Settings Persistence)
-- =========================================================================

function tests.test_project_browser_default_hidden_dotfiles()
  local settings = require("novim.settings")
  local browser = require("novim.browser")
  local workbench = require("novim.workbench")
  workbench.close()

  -- Ensure settings are at default (show_dotfiles = false)
  settings.set("show_dotfiles", false)

  local fixture = create_project_browser_fixture()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  -- Test browser module directly: a root scan loads only immediate entries
  local root_entries = browser.get_immediate_entries(fixture, "", 0, false)
  local paths = {}
  for _, entry in ipairs(root_entries) do
    paths[entry.path] = entry
  end

  -- Regular top-level entries MUST be visible
  assert_true(paths["main.lua"] ~= nil, "main.lua must be visible")
  assert_true(paths["README.md"] ~= nil, "README.md must be visible")
  assert_true(paths["src"] ~= nil, "src/ must be visible")
  assert_true(paths["docs"] ~= nil, "docs/ must be visible")

  -- Nested descendants MUST NOT be loaded before an expansion action
  assert_true(paths["src/utils.lua"] == nil, "src/utils.lua must not load before src expands")
  assert_true(paths["docs/guide.md"] == nil, "docs/guide.md must not load before docs expands")

  -- Dot-prefixed items at root MUST be hidden by default
  assert_true(paths[".env"] == nil, ".env must be hidden by default")
  assert_true(paths[".gitignore"] == nil, ".gitignore must be hidden by default")
  assert_true(paths[".vscode"] == nil, ".vscode must be hidden by default")
  assert_true(paths[".github"] == nil, ".github must be hidden by default")

  -- Expanding src must reveal only its immediate visible children
  local src_children = browser.get_immediate_entries(fixture .. "/src", "src", 1, false)
  local src_paths = {}
  for _, entry in ipairs(src_children) do
    src_paths[entry.path] = entry
  end
  assert_true(src_paths["src/utils.lua"] ~= nil, "src/utils.lua must be visible after src expansion")
  assert_true(src_paths["src/nested"] ~= nil, "src/nested must be visible after src expansion")
  assert_true(src_paths["src/.secret_module"] == nil, "src/.secret_module must be hidden by default")
  assert_true(src_paths["src/.secret_module/token.lua"] == nil, "nested dot-folder contents must be hidden")
  assert_true(src_paths["src/nested/deep.lua"] == nil, "src/nested/deep.lua must not load before nested expands")

  local docs_children = browser.get_immediate_entries(fixture .. "/docs", "docs", 1, false)
  for _, entry in ipairs(docs_children) do
    assert_true(entry.path ~= "docs/.hidden_note", "docs/.hidden_note must be hidden by default")
  end

  -- Test Workbench Project Browser integration
  workbench.open({ view = "files" })
  local state = workbench.get_state()
  assert_true(state.is_open, "workbench must be open")
  assert_eq(state.view_mode, "files", "view mode must be files")

  for _, entry in ipairs(state.project_files) do
    assert_eq(entry.depth, 0, "initial workbench list must contain only root entries: " .. entry.path)
  end

  local left_lines = vim.api.nvim_buf_get_lines(state.buf_left, 0, -1, false)
  local left_text = table.concat(left_lines, "\n")
  assert_true(left_text:find("PROJECT BROWSER") ~= nil, "left header must show PROJECT BROWSER")
  assert_true(left_text:find("main.lua") ~= nil, "main.lua must appear in rendered pane")
  assert_true(left_text:find("src/") ~= nil, "src/ must appear in rendered pane")
  assert_true(left_text:find("utils%.lua") == nil, "descendants must NOT render before expansion")
  assert_true(left_text:find(".env") == nil, ".env must NOT appear in rendered pane")
  assert_true(left_text:find(".vscode") == nil, ".vscode must NOT appear in rendered pane")

  workbench.close()
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

function tests.test_settings_toggle_reveals_and_hides_dotfiles()
  local settings = require("novim.settings")
  local browser = require("novim.browser")
  local workbench = require("novim.workbench")
  workbench.close()

  local fixture = create_project_browser_fixture()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  -- Start with dotfiles hidden
  settings.set("show_dotfiles", false)
  workbench.open({ view = "files" })

  -- 1. Enable show_dotfiles via toggle
  local ok1, err1, new_val = settings.toggle_dotfiles()
  assert_true(ok1 == true, "toggle must succeed: " .. tostring(err1))
  assert_true(new_val == true, "toggle must return true")
  assert_true(settings.get("show_dotfiles") == true, "settings.get must return true")
  workbench.refresh()
  local state_revealed = workbench.get_state()

  -- Root scan with dotfiles revealed
  local root_revealed = browser.get_immediate_entries(fixture, "", 0, true)
  local paths_revealed = {}
  local revealed_dot_count = 0
  for _, entry in ipairs(root_revealed) do
    paths_revealed[entry.path] = entry
    if entry.is_dot then
      revealed_dot_count = revealed_dot_count + 1
    end
  end
  assert_true(revealed_dot_count > 0, "revealed dot entries must be visible at root")

  -- Verify root dotfiles and dot-folders are now visible
  assert_true(paths_revealed[".env"] ~= nil, ".env must be revealed")
  assert_true(paths_revealed[".gitignore"] ~= nil, ".gitignore must be revealed")
  assert_true(paths_revealed[".vscode"] ~= nil, ".vscode must be revealed")
  assert_true(paths_revealed[".github"] ~= nil, ".github must be revealed")

  -- Nested dot entries require scanning their parent directory (lazy boundary)
  local vscode_children = browser.get_immediate_entries(fixture .. "/.vscode", ".vscode", 1, true)
  local vscode_paths = {}
  for _, entry in ipairs(vscode_children) do
    vscode_paths[entry.path] = entry
  end
  assert_true(vscode_paths[".vscode/settings.json"] ~= nil, ".vscode/settings.json must be revealed")

  local src_children = browser.get_immediate_entries(fixture .. "/src", "src", 1, true)
  local src_paths = {}
  for _, entry in ipairs(src_children) do
    src_paths[entry.path] = entry
  end
  assert_true(src_paths["src/.secret_module"] ~= nil, "src/.secret_module must be revealed")

  local secret_children = browser.get_immediate_entries(fixture .. "/src/.secret_module", "src/.secret_module", 2, true)
  local secret_paths = {}
  for _, entry in ipairs(secret_children) do
    secret_paths[entry.path] = entry
  end
  assert_true(secret_paths["src/.secret_module/token.lua"] ~= nil, "nested dot-folder file must be revealed")

  local docs_children = browser.get_immediate_entries(fixture .. "/docs", "docs", 1, true)
  local docs_paths = {}
  for _, entry in ipairs(docs_children) do
    docs_paths[entry.path] = entry
  end
  assert_true(docs_paths["docs/.hidden_note"] ~= nil, "docs/.hidden_note must be revealed")

  -- Normal entries remain visible in the workbench list
  local seen_normal = {}
  for _, entry in ipairs(state_revealed.project_files) do
    seen_normal[entry.path] = true
  end
  assert_true(seen_normal["main.lua"], "main.lua must remain visible")
  assert_true(seen_normal["src"], "src must remain visible")

  -- 2. Disable show_dotfiles via toggle
  local ok2, err2, val_hidden = settings.toggle_dotfiles()
  assert_true(ok2 == true, "toggle must succeed: " .. tostring(err2))
  assert_true(val_hidden == false, "toggle must return false")
  assert_true(settings.get("show_dotfiles") == false, "settings.get must return false")
  workbench.refresh()
  local root_hidden = browser.get_immediate_entries(fixture, "", 0, false)
  local paths_hidden = {}
  for _, entry in ipairs(root_hidden) do
    paths_hidden[entry.path] = entry
  end

  assert_true(paths_hidden[".env"] == nil, ".env must be hidden again")
  assert_true(paths_hidden[".vscode"] == nil, ".vscode must be hidden again")
  assert_true(paths_hidden["main.lua"] ~= nil, "normal files must still be visible")

  local src_hidden = browser.get_immediate_entries(fixture .. "/src", "src", 1, false)
  local src_hidden_paths = {}
  for _, entry in ipairs(src_hidden) do
    src_hidden_paths[entry.path] = entry
  end
  assert_true(src_hidden_paths["src/.secret_module"] == nil, "nested dot-folder must be hidden again")

  workbench.close()
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

-- =========================================================================
-- TASK-007 New Feature Tests (Lazy Root-Only Project Browser)
-- =========================================================================

local function find_project_entry(state, path)
  for _, entry in ipairs(state.project_files) do
    if entry.path == path then
      return entry
    end
  end
  return nil
end

function tests.test_lazy_root_only_initial_state()
  local workbench = require("novim.workbench")
  local settings = require("novim.settings")
  workbench.close()
  settings.set("show_dotfiles", false)

  local fixture = create_project_browser_fixture()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  workbench.open({ view = "files" })
  local st = workbench.get_state()
  assert_true(st.is_open, "workbench must be open")

  -- Only immediate root entries are visible: docs, src, main.lua, README.md
  assert_eq(#st.project_files, 4, "initial list must contain exactly the 4 visible root entries")
  local expected_order = { "docs", "src", "main.lua", "README.md" }
  for i, expected_path in ipairs(expected_order) do
    assert_eq(st.project_files[i].path, expected_path, "entry " .. i .. " must be " .. expected_path)
    assert_eq(st.project_files[i].depth, 0, "initial entries must sit at depth 0")
  end

  -- No descendant may be loaded or rendered before an expansion action
  assert_eq(next(st.expanded_dirs), nil, "a new launch must start with no expanded folders")
  local left_text = table.concat(vim.api.nvim_buf_get_lines(st.buf_left, 0, -1, false), "\n")
  assert_true(left_text:find("utils%.lua") == nil, "src/utils.lua must not render before expansion")
  assert_true(left_text:find("guide%.md") == nil, "docs/guide.md must not render before expansion")
  assert_true(left_text:find("deep%.lua") == nil, "src/nested/deep.lua must not render before expansion")

  workbench.close()
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

function tests.test_folder_double_click_expand_and_collapse()
  local workbench = require("novim.workbench")
  local settings = require("novim.settings")
  workbench.close()
  settings.set("show_dotfiles", false)

  local fixture = create_project_browser_fixture()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  workbench.open({ view = "files" })
  local st = workbench.get_state()
  local src_entry = find_project_entry(st, "src")
  assert_true(src_entry ~= nil, "src must be visible at root")

  -- Expand: scan only immediate visible children of src
  workbench.toggle_dir_expansion(src_entry)
  st = workbench.get_state()
  assert_true(st.expanded_dirs["src"] == true, "src must be marked expanded")
  assert_eq(#st.project_files, 6, "expanding src must reveal exactly its 2 visible children")
  assert_eq(st.project_files[3].path, "src/nested", "src/nested must render right after src")
  assert_eq(st.project_files[3].depth, 1, "src/nested must render at depth 1")
  assert_eq(st.project_files[3].is_dir, true, "src/nested must be a directory entry")
  assert_eq(st.project_files[4].path, "src/utils.lua", "src/utils.lua must render after src/nested")
  assert_eq(st.project_files[4].depth, 1, "src/utils.lua must render at depth 1")
  assert_eq(st.project_files[4].is_dir, false, "src/utils.lua must be a file entry")
  assert_eq(st.project_files[5].path, "main.lua", "root ordering must be preserved after expansion")

  local left_text = table.concat(vim.api.nvim_buf_get_lines(st.buf_left, 0, -1, false), "\n")
  assert_true(left_text:find("utils%.lua") ~= nil, "src/utils.lua must render after expansion")

  -- Collapse: remove all descendants without touching disk
  workbench.toggle_dir_expansion(find_project_entry(st, "src"))
  st = workbench.get_state()
  assert_eq(#st.project_files, 4, "collapse must restore the root-only list")
  assert_eq(next(st.expanded_dirs), nil, "collapse must clear expansion state")
  for _, entry in ipairs(st.project_files) do
    assert_eq(entry.depth, 0, "collapsed list must contain only root entries")
  end
  assert_true(vim.fn.filereadable(fixture .. "/src/utils.lua") == 1, "collapse must not delete files on disk")
  assert_true(vim.fn.isdirectory(fixture .. "/src/nested") == 1, "collapse must not delete folders on disk")

  workbench.close()
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

function tests.test_nested_folder_expands_independently()
  local workbench = require("novim.workbench")
  local settings = require("novim.settings")
  workbench.close()
  settings.set("show_dotfiles", false)

  local fixture = create_project_browser_fixture()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  workbench.open({ view = "files" })

  -- Expand src; its nested folder stays collapsed
  workbench.toggle_dir_expansion(find_project_entry(workbench.get_state(), "src"))
  local st = workbench.get_state()
  assert_true(find_project_entry(st, "src/nested") ~= nil, "src/nested must be visible after src expands")
  assert_true(find_project_entry(st, "src/nested/deep.lua") == nil, "src/nested/deep.lua must stay hidden while nested is collapsed")

  -- Expand the nested folder independently
  workbench.toggle_dir_expansion(find_project_entry(st, "src/nested"))
  st = workbench.get_state()
  assert_true(st.expanded_dirs["src/nested"] == true, "src/nested must be marked expanded")
  local deep = find_project_entry(st, "src/nested/deep.lua")
  assert_true(deep ~= nil, "src/nested/deep.lua must appear after nested expands")
  assert_eq(deep.depth, 2, "src/nested/deep.lua must render at depth 2")
  assert_true(st.expanded_dirs["src"] == true, "parent expansion must be preserved")

  -- Collapsing the parent removes all descendants including nested's children
  workbench.toggle_dir_expansion(find_project_entry(st, "src"))
  st = workbench.get_state()
  assert_eq(next(st.expanded_dirs), nil, "collapsing src must clear nested expansion too")
  assert_true(find_project_entry(st, "src/nested") == nil, "descendants must disappear after parent collapse")
  assert_true(find_project_entry(st, "src/nested/deep.lua") == nil, "nested grandchildren must disappear after parent collapse")
  assert_true(vim.fn.filereadable(fixture .. "/src/nested/deep.lua") == 1, "collapse must not delete files on disk")

  workbench.close()
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

function tests.test_refresh_preserves_expansion_new_launch_resets()
  local workbench = require("novim.workbench")
  local settings = require("novim.settings")
  workbench.close()
  settings.set("show_dotfiles", false)

  local fixture = create_project_browser_fixture()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  workbench.open({ view = "files" })
  workbench.toggle_dir_expansion(find_project_entry(workbench.get_state(), "docs"))

  -- Refresh within the same session preserves valid expansion state
  workbench.refresh()
  local st = workbench.get_state()
  assert_true(st.expanded_dirs["docs"] == true, "refresh must preserve in-session expansion")
  assert_true(find_project_entry(st, "docs/guide.md") ~= nil, "docs/guide.md must remain visible after refresh")
  assert_eq(#st.project_files, 5, "refresh must keep exactly the expanded docs child visible")

  -- New workbench launch starts collapsed at the root
  workbench.close()
  workbench.open({ view = "files" })
  st = workbench.get_state()
  assert_eq(next(st.expanded_dirs), nil, "a new launch must reset expansion state")
  assert_eq(#st.project_files, 4, "a new launch must list only root entries")
  assert_true(find_project_entry(st, "docs/guide.md") == nil, "a new launch must not show expanded descendants")

  workbench.close()
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

function tests.test_large_fixture_startup_stays_lazy()
  local workbench = require("novim.workbench")
  local settings = require("novim.settings")
  workbench.close()
  settings.set("show_dotfiles", false)

  -- Deterministic wide/deep fixture: 12 branches, 8 files each level, 4 nested levels
  local fixture = vim.fn.tempname() .. "_lazy_large_fixture"
  vim.fn.mkdir(fixture, "p")
  for d = 1, 12 do
    local dir_path = fixture .. "/branch_" .. d
    vim.fn.mkdir(dir_path, "p")
    for f = 1, 8 do
      local fh = io.open(dir_path .. "/leaf_" .. f .. ".txt", "w")
      fh:write("filler " .. d .. " " .. f .. "\n")
      fh:close()
    end
    local deep_path = dir_path
    for level = 1, 4 do
      deep_path = deep_path .. "/deep_" .. level
      vim.fn.mkdir(deep_path, "p")
      for f = 1, 8 do
        local fh = io.open(deep_path .. "/deep_leaf_" .. f .. ".txt", "w")
        fh:write("deep filler " .. d .. " " .. level .. " " .. f .. "\n")
        fh:close()
      end
    end
  end

  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  -- Startup observes the lazy boundary structurally, not via a wall-clock budget
  workbench.open({ view = "files" })
  local st = workbench.get_state()
  assert_eq(#st.project_files, 12, "startup must list only the 12 immediate root directories")
  for _, entry in ipairs(st.project_files) do
    assert_eq(entry.depth, 0, "no descendant may load at startup: " .. entry.path)
    assert_eq(entry.is_dir, true, "root fixture entries must be directories")
  end
  assert_eq(next(st.expanded_dirs), nil, "startup must not expand anything")

  -- Expanding one folder scans exactly its immediate children
  workbench.toggle_dir_expansion(find_project_entry(st, "branch_1"))
  st = workbench.get_state()
  assert_eq(#st.project_files, 21, "expanding branch_1 must reveal exactly its 9 immediate children")
  local expanded_dir_count = 0
  for _ in pairs(st.expanded_dirs) do
    expanded_dir_count = expanded_dir_count + 1
  end
  assert_eq(expanded_dir_count, 1, "only branch_1 may be expanded")
  assert_true(find_project_entry(st, "branch_1/deep_1/deep_leaf_1.txt") == nil, "deeper descendants must stay unloaded")

  workbench.close()
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

function tests.test_symlink_cycle_expansion_is_refused()
  local workbench = require("novim.workbench")
  local settings = require("novim.settings")
  local uv = vim.uv or vim.loop
  workbench.close()
  settings.set("show_dotfiles", false)

  local fixture = create_project_browser_fixture()
  -- Symlink loop: fixture/loop_link -> fixture
  assert_true(uv.fs_symlink(fixture, fixture .. "/loop_link"), "fixture must create a root symlink loop")

  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  workbench.open({ view = "files" })
  local st = workbench.get_state()
  local loop_entry = find_project_entry(st, "loop_link")
  assert_true(loop_entry ~= nil, "loop_link must be visible at root")
  assert_eq(loop_entry.is_dir, true, "loop_link must resolve as a directory")

  -- Expanding the loop must be refused without hanging or listing descendants
  workbench.toggle_dir_expansion(loop_entry)
  st = workbench.get_state()
  assert_eq(#st.project_files, 5, "refused expansion must not add entries")
  assert_eq(st.expanded_dirs["loop_link"], nil, "loop_link must not be marked expanded")
  assert_true(find_project_entry(st, "loop_link/main.lua") == nil, "cycle children must not be listed")

  -- A normal directory still expands after the refused cycle attempt
  workbench.toggle_dir_expansion(find_project_entry(st, "src"))
  st = workbench.get_state()
  assert_true(st.expanded_dirs["src"] == true, "normal expansion must still work after a refused cycle")
  assert_true(find_project_entry(st, "src/utils.lua") ~= nil, "src/utils.lua must appear after normal expansion")

  workbench.close()
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

function tests.test_settings_persistence_across_launches()
  local settings = require("novim.settings")

  -- Save setting show_dotfiles = true
  settings.set("show_dotfiles", true)

  -- Verify settings file exists on disk in the isolated state path
  local path = settings.get_settings_file_path()
  assert_true(vim.fn.filereadable(path) == 1, "settings file must exist on disk at " .. path)

  -- Verify file contents is valid JSON
  local content = table.concat(vim.fn.readfile(path), "\n")
  local parsed = vim.json.decode(content)
  assert_true(type(parsed) == "table", "parsed settings must be a table")
  assert_eq(parsed.show_dotfiles, true, "saved show_dotfiles must be true")

  -- Simulate fresh process launch: reset in-memory cache and load from disk
  settings.reset_cache()
  local loaded = settings.load(true)
  assert_eq(loaded.show_dotfiles, true, "fresh load must restore show_dotfiles = true from persistent file")

  -- Set back to false and verify persistence
  settings.set("show_dotfiles", false)
  settings.reset_cache()
  local loaded_false = settings.load(true)
  assert_eq(loaded_false.show_dotfiles, false, "fresh load must restore show_dotfiles = false from persistent file")
end

function tests.test_settings_missing_or_malformed_fallback()
  local settings = require("novim.settings")
  local path = settings.get_settings_file_path()

  -- Case 1: Missing file
  os.remove(path)
  settings.reset_cache()
  local s1 = settings.load(true)
  assert_eq(s1.show_dotfiles, false, "missing settings file must fall back safely to show_dotfiles = false")

  -- Case 2: Malformed JSON file
  local dir = vim.fs.dirname(path) or vim.fn.fnamemodify(path, ":h")
  vim.fn.mkdir(dir, "p")
  local f = io.open(path, "w")
  f:write("THIS IS NOT VALID JSON {{{{ ::: \n")
  f:close()

  settings.reset_cache()
  local s2 = settings.load(true)
  assert_eq(s2.show_dotfiles, false, "malformed JSON settings file must fall back safely to default false without error")

  -- Case 3: Invalid type inside JSON
  local f3 = io.open(path, "w")
  f3:write("{\"show_dotfiles\": \"string_value_not_a_boolean\"}\n")
  f3:close()

  settings.reset_cache()
  local s3 = settings.load(true)
  assert_eq(s3.show_dotfiles, false, "invalid type in settings file must fall back safely to default false")
  -- Restore clean settings file
  settings.set("show_dotfiles", false)
end

function tests.test_settings_write_failure_handling()
  local settings = require("novim.settings")
  local settings_ui = require("novim.settings_ui")
  settings.set("show_dotfiles", false)

  local path = settings.get_settings_file_path()
  os.remove(path)
  -- Create a directory at settings file path to force a write error
  vim.fn.mkdir(path, "p")

  settings.reset_cache()
  local ok, err, eff = settings.toggle_dotfiles()
  assert_true(ok == false, "toggle_dotfiles must return ok = false when write fails")
  assert_true(err ~= nil, "error message must be returned")
  assert_true(eff == false, "effective value must remain false")
  assert_true(settings.get("show_dotfiles") == false, "settings.get must remain false")

  -- Test Settings UI error rendering
  settings_ui.open()
  assert_true(settings_ui.is_open(), "settings UI must open")

  settings_ui.toggle_dotfiles()
  local state = settings.load(true)
  assert_true(state.show_dotfiles == false, "settings must not change on write failure")

  -- Clean up the blocker directory
  vim.fn.delete(path, "rf")
  settings_ui.close()
  settings.reset_cache()
  settings.set("show_dotfiles", false)
end

function tests.test_view_switching_and_header_tabs()
  local workbench = require("novim.workbench")
  workbench.close()

  local fixture = create_project_browser_fixture()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  -- Open in files mode
  workbench.open({ view = "files" })
  local state1 = workbench.get_state()
  assert_eq(state1.view_mode, "files", "initial view mode must be files")

  -- Switch to diff mode
  workbench.set_view("diff")
  local state2 = workbench.get_state()
  assert_eq(state2.view_mode, "diff", "switched view mode must be diff")
  local left_lines_diff = vim.api.nvim_buf_get_lines(state2.buf_left, 0, -1, false)
  local text_diff = table.concat(left_lines_diff, "\n")
  assert_true(text_diff:find("DIFF WORKBENCH") ~= nil, "left pane must render DIFF WORKBENCH")

  -- Switch back to files mode
  workbench.set_view("files")
  local state3 = workbench.get_state()
  assert_eq(state3.view_mode, "files", "switched view mode must be files")
  local left_lines_files = vim.api.nvim_buf_get_lines(state3.buf_left, 0, -1, false)
  local text_files = table.concat(left_lines_files, "\n")
  assert_true(text_files:find("PROJECT BROWSER") ~= nil, "left pane must render PROJECT BROWSER")

  workbench.close()
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

function tests.test_project_browser_preview()
  local browser = require("novim.browser")
  local fixture = create_project_browser_fixture()

  -- 1. Regular text file preview
  local file_entry = {
    path = "main.lua",
    name = "main.lua",
    is_dir = false,
    depth = 0,
    is_dot = false,
    full_path = fixture .. "/main.lua",
  }
  local file_preview, is_text = browser.get_preview(file_entry, fixture)
  assert_true(is_text, "text file must be recognized as text preview")
  local preview_text = table.concat(file_preview, "\n")
  assert_true(preview_text:find("File: main.lua") ~= nil, "preview must contain header with filename")
  assert_true(preview_text:find("print%('hello world'%)") ~= nil, "preview must contain file content")

  -- 2. Directory inspection preview (filtering check)
  local dir_entry = {
    path = "src",
    name = "src",
    is_dir = true,
    depth = 0,
    is_dot = false,
    full_path = fixture .. "/src",
  }

  -- 2a. With dotfiles hidden: .secret_module must NOT appear in directory preview
  local dir_preview_hidden, _ = browser.get_preview(dir_entry, fixture, false)
  local dir_text_hidden = table.concat(dir_preview_hidden, "\n")
  assert_true(dir_text_hidden:find("Directory: src/") ~= nil, "preview must contain directory header")
  assert_true(dir_text_hidden:find("utils.lua") ~= nil, "directory preview must list regular child item utils.lua")
  assert_true(dir_text_hidden:find(".secret_module") == nil, "directory preview must NOT list .secret_module when dotfiles hidden")
  assert_true(dir_text_hidden:find("1 dot%-item hidden") ~= nil, "directory preview must note hidden dot-item count")

  -- 2b. With dotfiles revealed: .secret_module MUST appear in directory preview
  local dir_preview_revealed, _ = browser.get_preview(dir_entry, fixture, true)
  local dir_text_revealed = table.concat(dir_preview_revealed, "\n")
  assert_true(dir_text_revealed:find(".secret_module") ~= nil, "directory preview MUST list .secret_module when revealed")
  assert_true(dir_text_revealed:find("utils.lua") ~= nil, "directory preview must still list utils.lua")

  -- 3. Binary file inspection
  local bin_path = fixture .. "/sample.bin"
  local f_bin = io.open(bin_path, "wb")
  f_bin:write("\0\1\2\3\4\255")
  f_bin:close()

  local bin_entry = {
    path = "sample.bin",
    name = "sample.bin",
    is_dir = false,
    depth = 0,
    is_dot = false,
    full_path = bin_path,
  }
  local bin_preview, is_bin_text = browser.get_preview(bin_entry, fixture)
  assert_true(not is_bin_text, "binary file must not be marked as text")
  local bin_text = table.concat(bin_preview, "\n")
  assert_true(bin_text:find("Binary file") ~= nil, "preview must state binary file content suppressed")

  cleanup_dir(fixture)
end

function tests.test_project_browser_read_only_invariance()
  local workbench = require("novim.workbench")
  local settings = require("novim.settings")
  workbench.close()

  local fixture = create_fixture_repo()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  -- Take exact before-status snapshots
  local before_status = vim.system({ "git", "-C", fixture, "status", "--porcelain=v1", "-z", "-uall" }, { text = true }):wait().stdout
  local before_diff = vim.system({ "git", "-C", fixture, "diff", "HEAD" }, { text = true }):wait().stdout

  -- Open project browser, toggle settings, switch views, navigate items
  workbench.open({ view = "files" })
  workbench.select_file(1)
  workbench.select_file(2)

  settings.toggle_dotfiles()
  workbench.refresh()

  workbench.set_view("diff")
  workbench.select_file(1)
  workbench.select_file(2)

  settings.toggle_dotfiles()
  workbench.refresh()
  workbench.set_view("files")

  workbench.close()

  -- Take exact after-status snapshots
  local after_status = vim.system({ "git", "-C", fixture, "status", "--porcelain=v1", "-z", "-uall" }, { text = true }):wait().stdout
  local after_diff = vim.system({ "git", "-C", fixture, "diff", "HEAD" }, { text = true }):wait().stdout

  -- Assert exact byte-for-byte invariance
  assert_eq(after_status, before_status, "Git status must remain 100% byte-for-byte identical")
  assert_eq(after_diff, before_diff, "Git diff must remain 100% byte-for-byte identical")

  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

-- =========================================================================
-- TASK-004 New Feature Tests (Source Navigation, View Switching, & Editing)
-- =========================================================================

function tests.test_open_regular_file_in_editor()
  local workbench = require("novim.workbench")
  workbench.close()

  local fixture = create_project_browser_fixture()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  workbench.open({ view = "files" })
  local st = workbench.get_state()
  assert_true(st.is_open, "workbench must be open")
  assert_eq(st.view_mode, "files", "view mode must be files")

  -- Find a regular file entry in project_files
  local target_entry = nil
  local target_idx = nil
  for idx, entry in ipairs(st.project_files) do
    if not entry.is_dir and entry.name == "README.md" then
      target_entry = entry
      target_idx = idx
      break
    end
  end
  assert_true(target_entry ~= nil, "fixture must contain README.md")

  -- Select and open the regular file
  workbench.select_file(target_idx)
  local open_ok = workbench.open_file(target_entry)
  assert_true(open_ok, "opening a regular file must succeed")

  -- Verify right window state
  local current_win = vim.api.nvim_get_current_win()
  assert_eq(current_win, st.win_right, "opening file must focus the right window")

  local edit_buf = vim.api.nvim_win_get_buf(st.win_right)
  local buf_name = vim.api.nvim_buf_get_name(edit_buf)
  assert_true(buf_name:find("README.md") ~= nil, "right window buffer must be README.md")
  assert_eq(vim.bo[edit_buf].buftype, "", "editing buffer must be a regular buffer (buftype='')")
  assert_eq(vim.bo[edit_buf].readonly, false, "editing buffer must not be readonly")
  assert_eq(vim.bo[edit_buf].modifiable, true, "editing buffer must be modifiable")

  -- Verify left window remains intact
  assert_true(vim.api.nvim_win_is_valid(st.win_left), "left window must remain valid")
  local left_buf = vim.api.nvim_win_get_buf(st.win_left)
  assert_eq(left_buf, st.buf_left, "left window must retain navigation buffer")

  -- Verify editing capability: modify lines and verify
  vim.api.nvim_buf_set_lines(edit_buf, 0, -1, false, { "# Modified README", "New content line" })
  local modified_lines = vim.api.nvim_buf_get_lines(edit_buf, 0, -1, false)
  assert_eq(modified_lines[1], "# Modified README", "buffer lines must be editable")
  assert_eq(vim.bo[edit_buf].modified, true, "buffer must be marked modified after edits")

  workbench.close()
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

function tests.test_directory_selection_preserves_inspection_no_file_open()
  local workbench = require("novim.workbench")
  workbench.close()

  local fixture = create_project_browser_fixture()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  workbench.open({ view = "files" })
  local st = workbench.get_state()

  -- Find a directory entry
  local dir_entry = nil
  local dir_idx = nil
  for idx, entry in ipairs(st.project_files) do
    if entry.is_dir and entry.name == "src" then
      dir_entry = entry
      dir_idx = idx
      break
    end
  end
  assert_true(dir_entry ~= nil, "fixture must contain src directory")

  -- Attempt to open directory
  workbench.select_file(dir_idx)
  local open_result = workbench.open_file(dir_entry)
  assert_eq(open_result, false, "open_file on a directory must return false")

  -- Verify right pane remains in read-only preview mode
  local current_buf = vim.api.nvim_win_get_buf(st.win_right)
  assert_eq(current_buf, st.buf_right, "right window buffer must remain preview buffer (buf_right)")
  assert_eq(vim.bo[st.buf_right].buftype, "nofile", "preview buffer buftype must remain 'nofile'")
  assert_eq(vim.bo[st.buf_right].readonly, true, "preview buffer must remain readonly")
  assert_eq(vim.bo[st.buf_right].modifiable, false, "preview buffer must remain not modifiable")

  -- Verify right pane content shows directory inspection
  local preview_lines = vim.api.nvim_buf_get_lines(st.buf_right, 0, -1, false)
  local preview_text = table.concat(preview_lines, "\n")
  assert_true(preview_text:find("Directory: src") ~= nil, "preview must contain Directory: src")
  assert_true(preview_text:find("Contents:") ~= nil, "preview must contain Contents list")
  assert_true(preview_text:find("Direct Items:") ~= nil, "preview must contain Direct Items count")

  workbench.close()
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

function tests.test_view_switching_and_active_tab_rendering()
  local workbench = require("novim.workbench")
  workbench.close()

  local fixture = create_fixture_repo()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  -- 1. Open in files view
  workbench.open({ view = "files" })
  local st1 = workbench.get_state()
  assert_eq(st1.view_mode, "files", "initial view mode must be files")

  local header_files = vim.api.nvim_buf_get_lines(st1.buf_left, 1, 2, false)
  assert_true(header_files[1]:find("▶ %[1: Files%]") ~= nil, "header tab 1 must show active indicator in files view")

  -- 2. Switch to diff view
  workbench.set_view("diff")
  local st2 = workbench.get_state()
  assert_eq(st2.view_mode, "diff", "view mode must be diff after set_view('diff')")

  local header_diff = vim.api.nvim_buf_get_lines(st2.buf_left, 1, 2, false)
  assert_true(header_diff[1]:find("▶ %[2: Git Diff%]") ~= nil, "header tab 2 must show active indicator in diff view")

  -- 3. Verify toggle_view switches back to files
  workbench.toggle_view()
  local st3 = workbench.get_state()
  assert_eq(st3.view_mode, "files", "view mode must be files after toggle_view()")

  -- 4. Verify toggle_view switches to diff
  workbench.toggle_view()
  local st4 = workbench.get_state()
  assert_eq(st4.view_mode, "diff", "view mode must be diff after toggle_view()")

  workbench.close()
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

function tests.test_changed_file_diff_rendering_and_return_to_files()
  local workbench = require("novim.workbench")
  local settings = require("novim.settings")
  workbench.close()

  local fixture = create_fixture_repo()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  -- Start in files view with custom dotfile setting
  settings.set("show_dotfiles", false)
  workbench.open({ view = "files" })
  local initial_root = workbench.get_state().root_dir
  assert_true(vim.fs.normalize(initial_root) == vim.fs.normalize(fixture) or initial_root:find(vim.fs.basename(fixture), 1, true) ~= nil, "root_dir must match fixture path")

  -- Switch to Git Diff view
  workbench.set_view("diff")
  local st_diff = workbench.get_state()
  assert_true(st_diff.git_file_count >= 3, "must have loaded changed git files")

  -- Select a modified file
  workbench.select_file(1)
  local diff_lines = vim.api.nvim_buf_get_lines(st_diff.buf_right, 0, -1, false)
  local diff_text = table.concat(diff_lines, "\n")
  assert_true(diff_text:find("diff %-%-git") ~= nil, "right pane must render unified diff against HEAD")

  -- Return to Files view
  workbench.set_view("files")
  local st_returned = workbench.get_state()
  assert_eq(st_returned.view_mode, "files", "view mode must be files")
  assert_eq(st_returned.root_dir, initial_root, "root directory must be preserved")
  assert_eq(settings.get("show_dotfiles"), false, "show_dotfiles setting must be preserved")
  assert_true(st_returned.project_file_count > 0, "project file list must remain intact")

  workbench.close()
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

function tests.test_unsaved_buffer_preservation_on_navigation()
  local workbench = require("novim.workbench")
  workbench.close()

  local fixture = create_project_browser_fixture()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  workbench.open({ view = "files" })
  local st = workbench.get_state()

  -- Find and open a file
  local entry1 = nil
  for _, entry in ipairs(st.project_files) do
    if not entry.is_dir and entry.name == "README.md" then
      entry1 = entry
      break
    end
  end
  assert_true(entry1 ~= nil, "fixture must contain README.md")

  workbench.open_file(entry1)
  local edit_buf = vim.api.nvim_win_get_buf(st.win_right)

  -- Add unsaved changes to the buffer
  vim.api.nvim_buf_set_lines(edit_buf, 0, 0, false, { "UNSAVED EDITED LINE 12345" })
  assert_eq(vim.bo[edit_buf].modified, true, "buffer must have unsaved edits")

  -- Switch back to left pane and navigate/preview other items
  vim.api.nvim_set_current_win(st.win_left)
  workbench.select_file(1) -- Preview item 1 in right pane
  assert_eq(vim.api.nvim_win_get_buf(st.win_right), st.buf_right, "right window should switch to preview buffer")

  -- Switch views
  workbench.set_view("diff")
  workbench.set_view("files")

  -- Re-open README.md
  workbench.open_file(entry1)
  local re_opened_buf = vim.api.nvim_win_get_buf(st.win_right)
  assert_eq(re_opened_buf, edit_buf, "re-opened buffer must be the exact same in-memory buffer")
  local lines = vim.api.nvim_buf_get_lines(re_opened_buf, 0, 1, false)
  assert_eq(lines[1], "UNSAVED EDITED LINE 12345", "unsaved modifications must be completely preserved")

  workbench.close()
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

function tests.test_keyboard_and_mouse_shortcuts()
  local workbench = require("novim.workbench")
  workbench.close()

  local fixture = create_project_browser_fixture()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  workbench.open({ view = "files" })
  local st = workbench.get_state()

  -- Test Tab switching to right window
  vim.api.nvim_set_current_win(st.win_left)
  local tab_map = vim.fn.maparg("<Tab>", "n", false, true)
  assert_true(tab_map ~= nil and tab_map.callback ~= nil, "<Tab> keymap must exist on left buffer")
  tab_map.callback()
  assert_eq(vim.api.nvim_get_current_win(), st.win_right, "<Tab> must switch focus to right window")

  -- Test Tab switching back to left window
  local right_tab_map = vim.fn.maparg("<Tab>", "n", false, true)
  assert_true(right_tab_map ~= nil and right_tab_map.callback ~= nil, "<Tab> keymap must exist on right buffer")
  right_tab_map.callback()
  assert_eq(vim.api.nvim_get_current_win(), st.win_left, "<Tab> must switch focus back to left window")

  -- Test Enter on left pane opens regular file
  local file_idx = nil
  for idx, entry in ipairs(st.project_files) do
    if not entry.is_dir and entry.name == "README.md" then
      file_idx = idx
      break
    end
  end
  assert_true(file_idx ~= nil, "README.md must exist in fixture")

  local target_line = st.header_line_count + file_idx
  vim.api.nvim_win_set_cursor(st.win_left, { target_line, 1 })
  local cr_map = vim.fn.maparg("<CR>", "n", false, true)
  assert_true(cr_map ~= nil and cr_map.callback ~= nil, "<CR> keymap must exist on left buffer")
  cr_map.callback()

  assert_eq(vim.api.nvim_get_current_win(), st.win_right, "<CR> on regular file must focus right window")
  local edit_buf = vim.api.nvim_win_get_buf(st.win_right)
  assert_true(vim.api.nvim_buf_get_name(edit_buf):find("README.md") ~= nil, "editing buffer must be README.md")

  workbench.close()
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

function tests.test_task004_source_navigation_git_invariance()
  local workbench = require("novim.workbench")
  workbench.close()

  local fixture = create_fixture_repo()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  -- Capture baseline git status and diff
  local before_status = vim.system({ "git", "-C", fixture, "status", "--porcelain=v1", "-z", "-uall" }, { text = true }):wait().stdout
  local before_diff = vim.system({ "git", "-C", fixture, "diff", "HEAD" }, { text = true }):wait().stdout

  -- Perform full navigation cycle: open files, open dirs, switch views
  workbench.open({ view = "files" })
  local st = workbench.get_state()

  -- Open a regular file
  for _, entry in ipairs(st.project_files) do
    if not entry.is_dir and entry.name == "main.lua" then
      workbench.open_file(entry)
      break
    end
  end

  -- Attempt to open directory
  for _, entry in ipairs(st.project_files) do
    if entry.is_dir then
      workbench.open_file(entry)
      break
    end
  end

  -- Switch views and navigate diff items
  workbench.set_view("diff")
  workbench.select_file(1)
  workbench.select_file(2)

  -- Return to files view
  workbench.set_view("files")
  workbench.select_file(1)

  workbench.close()

  -- Capture after-navigation git status and diff
  local after_status = vim.system({ "git", "-C", fixture, "status", "--porcelain=v1", "-z", "-uall" }, { text = true }):wait().stdout
  local after_diff = vim.system({ "git", "-C", fixture, "diff", "HEAD" }, { text = true }):wait().stdout

  assert_eq(after_status, before_status, "Git status must remain 100% byte-for-byte identical after navigation")
  assert_eq(after_diff, before_diff, "Git diff must remain 100% byte-for-byte identical after navigation")

  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

-- =========================================================================
-- TASK-008 New Feature Tests (Themes, Settings Key Help, Esc Close, Pane Drag)
-- =========================================================================

--- Collect the lhs strings of all Normal-mode mappings of a buffer.
--- nvim_buf_get_keymap is buffer-scoped, so every returned map belongs to it.
local function buf_local_lhs(buf)
  local lhs_set = {}
  for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
    lhs_set[map.lhs] = true
  end
  return lhs_set
end

--- All lhs spellings nvim_buf_get_keymap may use for a documented key.
--- Space is stored as a literal space; Ctrl keys are canonicalized uppercase.
local function lhs_spellings(key)
  if key == "<Space>" then
    return { key, " " }
  elseif key == "<C-r>" then
    return { key, "<C-R>" }
  end
  return { key }
end

function tests.test_theme_catalog_defaults_and_application()
  local settings = require("novim.settings")
  local themes = require("novim.themes")

  -- Exactly six built-in themes in canonical order
  local list = themes.list()
  assert_eq(#list, 6, "exactly six built-in themes must exist")
  local expected_ids = { "tokyo_night", "nord", "gruvbox_dark", "catppuccin_mocha", "one_dark", "solarized_light" }
  local expected_labels = { "Tokyo Night", "Nord", "Gruvbox Dark", "Catppuccin Mocha", "One Dark", "Solarized Light" }
  for i = 1, 6 do
    assert_eq(list[i].id, expected_ids[i], "theme " .. i .. " id must be " .. expected_ids[i])
    assert_eq(list[i].label, expected_labels[i], "theme " .. i .. " label must be " .. expected_labels[i])
  end

  assert_true(themes.is_valid("tokyo_night"), "tokyo_night must be a valid theme")
  assert_true(not themes.is_valid("dracula"), "unknown themes must be invalid")
  assert_true(not themes.is_valid(42), "non-string ids must be invalid")

  -- Missing settings file defaults to Tokyo Night
  local path = settings.get_settings_file_path()
  os.remove(path)
  settings.reset_cache()
  local defaults = settings.load(true)
  assert_eq(defaults.theme, "tokyo_night", "missing theme value must default to Tokyo Night")
  assert_eq(defaults.show_dotfiles, false, "missing settings must also default show_dotfiles")

  -- Every theme applies without error and restyles the palette highlights
  local normal_fg_per_theme = {}
  for _, id in ipairs(expected_ids) do
    local applied = themes.apply(id)
    assert_eq(applied.id, id, "apply must apply the requested theme " .. id)
    local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
    assert_true(normal.fg ~= nil, id .. " must define Normal foreground")
    assert_true(normal.bg ~= nil, id .. " must define Normal background")
    assert_true(vim.api.nvim_get_hl(0, { name = "WorkbenchHeader" }).fg ~= nil, id .. " must define WorkbenchHeader")
    assert_true(vim.api.nvim_get_hl(0, { name = "diffAdded" }).fg ~= nil, id .. " must define diffAdded")
    normal_fg_per_theme[id] = normal.fg
  end
  assert_eq(vim.o.background, "light", "Solarized Light must switch the background to light")
  assert_true(normal_fg_per_theme["tokyo_night"] ~= normal_fg_per_theme["nord"], "different themes must produce different palettes")

  -- Unknown ids fall back to Tokyo Night without error
  local fallback = themes.apply("dracula")
  assert_eq(fallback.id, "tokyo_night", "unknown theme ids must fall back to Tokyo Night")
  assert_eq(vim.g.colors_name, "tokyo_night", "colors_name must track the applied theme")
end

function tests.test_theme_persistence_and_fallback()
  local settings = require("novim.settings")
  local themes = require("novim.themes")
  local path = settings.get_settings_file_path()

  -- Persist both settings, then restore from disk like a fresh launch
  settings.set("show_dotfiles", true)
  settings.set("theme", "nord")
  assert_true(vim.fn.filereadable(path) == 1, "settings file must exist after saving theme")
  local parsed = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
  assert_eq(parsed.theme, "nord", "saved theme must be nord")
  assert_eq(parsed.show_dotfiles, true, "saved show_dotfiles must remain true")

  settings.reset_cache()
  local reloaded = settings.load(true)
  assert_eq(reloaded.theme, "nord", "theme must persist across launches")
  assert_eq(reloaded.show_dotfiles, true, "existing dot-folder setting must persist alongside the theme")

  -- Invalid theme value falls back safely WITHOUT clobbering unrelated settings
  local f = io.open(path, "w")
  f:write('{"theme": "dracula", "show_dotfiles": true}')
  f:close()
  settings.reset_cache()
  local fallback = settings.load(true)
  assert_eq(fallback.theme, "tokyo_night", "invalid theme value must fall back to the default")
  assert_eq(fallback.show_dotfiles, true, "invalid theme must not overwrite the unrelated show_dotfiles setting")

  -- Malformed JSON falls back safely
  local f2 = io.open(path, "w")
  f2:write("THIS IS NOT JSON {{{{")
  f2:close()
  settings.reset_cache()
  local malformed = settings.load(true)
  assert_eq(malformed.theme, "tokyo_night", "malformed settings file must fall back to the default theme")

  -- Non-string theme value falls back safely
  local f3 = io.open(path, "w")
  f3:write('{"theme": 42}')
  f3:close()
  settings.reset_cache()
  local wrong_type = settings.load(true)
  assert_eq(wrong_type.theme, "tokyo_night", "non-string theme value must fall back to the default")

  -- The generic setter refuses invalid themes without touching state
  local ok, err = settings.set("theme", "dracula")
  assert_true(ok == false, "setting an unknown theme must fail")
  assert_true(err ~= nil, "setting an unknown theme must return an error message")
  assert_eq(settings.get("theme"), "tokyo_night", "rejected theme must not change the current value")

  -- Saving after a fallback rewrites a clean file preserving both settings
  settings.set("show_dotfiles", false)
  settings.reset_cache()
  local after_save = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
  assert_eq(after_save.theme, "tokyo_night", "post-fallback save must write the default theme")
  assert_eq(after_save.show_dotfiles, false, "post-fallback save must keep the changed show_dotfiles")

  -- Restore clean defaults for the remaining suites
  settings.set("show_dotfiles", false)
  settings.set("theme", "tokyo_night")
  assert_true(themes.is_valid(settings.get("theme")), "restored theme must be valid")
end

function tests.test_settings_theme_control_cycles_applies_and_persists()
  local workbench = require("novim.workbench")
  local settings_ui = require("novim.settings_ui")
  local themes = require("novim.themes")
  local settings = require("novim.settings")
  workbench.close()
  settings.set("theme", "tokyo_night")

  local fixture = create_project_browser_fixture()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  workbench.open({ view = "files" })
  local before_hl = vim.api.nvim_get_hl(0, { name = "WorkbenchHeader" }).fg
  workbench.open_settings()
  assert_true(settings_ui.is_open(), "settings panel must open from the workbench")

  -- Cycling forward selects the next catalog entry and re-themes live
  local ok, err = settings_ui.cycle_theme(1)
  assert_true(ok, "cycling to the next theme must succeed: " .. tostring(err))
  assert_eq(settings.get("theme"), "nord", "next theme after Tokyo Night must be Nord")
  local after_hl = vim.api.nvim_get_hl(0, { name = "WorkbenchHeader" }).fg
  assert_true(before_hl ~= after_hl, "theme switch must restyle the workbench palette live")

  -- The panel re-renders with the selected theme
  local text = table.concat(vim.api.nvim_buf_get_lines(settings_ui.get_buf(), 0, -1, false), "\n")
  assert_true(text:find("Nord", 1, true) ~= nil, "settings panel must display the selected theme name")

  -- Cycling backward wraps around the catalog
  settings_ui.cycle_theme(-1)
  assert_eq(settings.get("theme"), "tokyo_night", "previous theme before Tokyo Night must wrap to the default again")
  settings_ui.cycle_theme(-1)
  assert_eq(settings.get("theme"), "solarized_light", "previous theme from the default must wrap to Solarized Light")

  -- The selection persists across a simulated fresh launch
  settings.reset_cache()
  assert_eq(settings.load(true).theme, "solarized_light", "cycled theme must persist across launches")

  settings_ui.close()
  workbench.close()
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)

  settings.set("theme", "tokyo_night")
  themes.apply("tokyo_night")
end

function tests.test_settings_panel_key_help_below_controls_matches_mappings()
  local workbench = require("novim.workbench")
  local settings_ui = require("novim.settings_ui")
  local keymaps = require("novim.keymaps")
  workbench.close()

  local fixture = create_project_browser_fixture()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  workbench.open({ view = "files" })
  local st = workbench.get_state()
  workbench.open_settings()
  assert_true(settings_ui.is_open(), "settings panel must be open")

  local buf = settings_ui.get_buf()
  assert_true(buf ~= nil, "settings buffer must be available")
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local text = table.concat(lines, "\n")

  -- Controls render above the key help section
  local theme_row, help_row
  for i, line in ipairs(lines) do
    if line:find("Theme:", 1, true) then theme_row = i end
    if line:find("Key Bindings (Workbench)", 1, true) then help_row = i end
  end
  assert_true(theme_row ~= nil, "settings panel must render the theme control")
  assert_true(help_row ~= nil, "settings panel must render the key help section")
  assert_true(help_row > theme_row, "key help must render below the controls")

  -- Every documented entry is visibly present in the panel
  local documented = {}
  local function mark_documented(key)
    for _, spelling in ipairs(lhs_spellings(key)) do
      documented[spelling] = true
    end
  end
  for _, entry in ipairs(keymaps.workbench) do
    assert_true(text:find(entry.display, 1, true) ~= nil,
      "key help must document: " .. entry.display)
    for _, key in ipairs(entry.keys) do
      mark_documented(key)
    end
  end
  for _, entry in ipairs(keymaps.settings) do
    assert_true(text:find(entry.display, 1, true) ~= nil,
      "settings help must document: " .. entry.display)
    for _, key in ipairs(entry.keys) do
      mark_documented(key)
    end
  end

  local function key_is_mapped(key, lhs_set)
    for _, spelling in ipairs(lhs_spellings(key)) do
      if lhs_set[spelling] then
        return true
      end
    end
    return false
  end

  -- Every documented workbench shortcut is backed by a real buffer-local mapping
  local left_keys = buf_local_lhs(st.buf_left)
  local right_keys = buf_local_lhs(st.buf_right)
  for _, entry in ipairs(keymaps.workbench) do
    for _, key in ipairs(entry.keys) do
      assert_true(key_is_mapped(key, left_keys) or key_is_mapped(key, right_keys),
        "documented shortcut must be an actual workbench mapping: " .. key)
    end
  end

  -- Reverse direction: every workbench mapping is documented in the help
  for key in pairs(left_keys) do
    assert_true(documented[key], "workbench mapping must appear in the key help: " .. key)
  end
  for key in pairs(right_keys) do
    assert_true(documented[key], "workbench mapping must appear in the key help: " .. key)
  end

  -- The settings panel mappings themselves match their documentation
  local settings_keys = buf_local_lhs(buf)
  for _, entry in ipairs(keymaps.settings) do
    for _, key in ipairs(entry.keys) do
      assert_true(key_is_mapped(key, settings_keys),
        "documented settings shortcut must be an actual mapping: " .. key)
    end
  end

  settings_ui.close()
  workbench.close()
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

function tests.test_settings_single_esc_close_restores_workbench_focus()
  local workbench = require("novim.workbench")
  local settings_ui = require("novim.settings_ui")
  workbench.close()

  local fixture = create_project_browser_fixture()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  workbench.open({ view = "files" })
  local st = workbench.get_state()

  -- One Esc press closes the panel immediately and restores workbench focus
  workbench.open_settings()
  assert_true(settings_ui.is_open(), "settings panel must be open")
  assert_eq(vim.api.nvim_get_current_win(), settings_ui.get_win(), "settings must take focus while open")

  local settings_buf = settings_ui.get_buf()
  local esc_callback = nil
  for _, map in ipairs(vim.api.nvim_buf_get_keymap(settings_buf, "n")) do
    if map.lhs == "<Esc>" then
      esc_callback = map.callback
    end
  end
  assert_true(esc_callback ~= nil, "Esc must have a single-press close mapping in settings")

  esc_callback()
  assert_true(not settings_ui.is_open(), "one Esc press must close settings immediately")
  assert_eq(vim.api.nvim_get_current_win(), st.win_left, "Esc must restore workbench focus")

  -- q remains a direct close action
  workbench.open_settings()
  assert_true(settings_ui.is_open(), "settings panel must reopen")
  settings_buf = settings_ui.get_buf()
  local q_callback = nil
  for _, map in ipairs(vim.api.nvim_buf_get_keymap(settings_buf, "n")) do
    if map.lhs == "q" then
      q_callback = map.callback
    end
  end
  assert_true(q_callback ~= nil, "q must have a direct close mapping in settings")

  q_callback()
  assert_true(not settings_ui.is_open(), "q must close settings directly")
  assert_eq(vim.api.nvim_get_current_win(), st.win_left, "q must restore workbench focus")

  workbench.close()
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

function tests.test_pane_drag_both_directions_with_minimum_clamp()
  local workbench = require("novim.workbench")
  workbench.close()

  local fixture = create_project_browser_fixture()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  workbench.open({ view = "files" })
  local st = workbench.get_state()
  local total = vim.o.columns
  local w0 = vim.api.nvim_win_get_width(st.win_left)
  local sep_col = vim.fn.win_screenpos(st.win_right)[2] - 1
  assert_true(sep_col > w0, "divider column must sit right of the left pane")

  -- Simulated divider drag: press, drag right, drag left, release
  workbench.pane_drag_start(sep_col)
  workbench.pane_drag_move(sep_col + 12)
  local w_wider = vim.api.nvim_win_get_width(st.win_left)
  assert_true(w_wider > w0, "dragging the divider right must widen the left pane")

  workbench.pane_drag_move(sep_col - 8)
  local w_narrower = vim.api.nvim_win_get_width(st.win_left)
  assert_true(w_narrower < w_wider, "dragging the divider left must narrow the left pane")

  workbench.pane_drag_end()
  assert_eq(vim.api.nvim_win_get_width(st.win_left), w_narrower, "release must keep the last dragged width")

  -- Stale drag events after release are ignored
  workbench.pane_drag_move(sep_col + 100)
  assert_eq(vim.api.nvim_win_get_width(st.win_left), w_narrower, "drag move without an active drag must be a no-op")

  -- Dragging far right clamps so the right pane keeps its minimum width
  workbench.pane_drag_start(sep_col)
  workbench.pane_drag_move(total)
  local max_left = vim.api.nvim_win_get_width(st.win_left)
  local right_at_max = vim.api.nvim_win_get_width(st.win_right)
  assert_true(max_left < total, "left pane must clamp before consuming the whole width")
  assert_true(right_at_max >= 20, "right pane must keep its minimum width at the clamp")
  assert_true(vim.api.nvim_win_is_valid(st.win_right), "right window must stay valid at the clamp")

  -- Dragging far left clamps at the left pane minimum
  workbench.pane_drag_move(0)
  local min_left = vim.api.nvim_win_get_width(st.win_left)
  assert_true(min_left >= 15, "left pane must keep its minimum width at the clamp")
  assert_true(vim.api.nvim_win_is_valid(st.win_left), "left window must stay valid at the clamp")
  workbench.pane_drag_end()

  -- The resize helper clamps invalid targets without raising (no E21)
  workbench.resize_left_pane(1)
  assert_true(vim.api.nvim_win_get_width(st.win_left) >= 15, "resize below the minimum must clamp")
  workbench.resize_left_pane(total * 10)
  assert_true(vim.api.nvim_win_get_width(st.win_right) >= 20, "resize above the maximum must clamp")

  -- Dragging preserves the selection and navigation behavior
  workbench.select_file(2)
  local sel_before = workbench.get_state().selected_project_index
  workbench.pane_drag_start(sep_col)
  workbench.pane_drag_move(sep_col + 5)
  workbench.pane_drag_end()
  assert_eq(workbench.get_state().selected_project_index, sel_before, "dragging must not change the selection")
  assert_true(workbench.get_state().is_open, "workbench must remain open after a drag")

  -- The drag mappings back the documented behavior on the left buffer
  local left_keys = buf_local_lhs(st.buf_left)
  assert_true(left_keys["<LeftDrag>"] ~= nil, "<LeftDrag> must be mapped for divider dragging")
  assert_true(left_keys["<LeftRelease>"] ~= nil, "<LeftRelease> must be mapped to end dragging")

  workbench.close()
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

-- =========================================================================
-- Run all tests
-- =========================================================================

local total = 0
local passed = 0
local failed = 0

print("=== Running Diff Workbench & Project Browser Test Suite ===")
for name, fn in pairs(tests) do
  total = total + 1
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
    print(string.format("  ✓ PASS: %s", name))
  else
    failed = failed + 1
    print(string.format("  ✗ FAIL: %s", name))
    print(string.format("    %s", tostring(err)))
  end
end

print(string.format("=== Test Summary: %d total, %d passed, %d failed ===", total, passed, failed))

if failed > 0 then
  vim.cmd("cquit 1")
else
  vim.cmd("qall!")
end
