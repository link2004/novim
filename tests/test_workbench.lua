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

  -- Test browser module directly
  local tree, stats = browser.get_tree(fixture, false)
  local paths = {}
  for _, entry in ipairs(tree) do
    paths[entry.path] = entry
  end

  -- Regular top-level and nested files/folders MUST be visible
  assert_true(paths["main.lua"] ~= nil, "main.lua must be visible")
  assert_true(paths["README.md"] ~= nil, "README.md must be visible")
  assert_true(paths["src"] ~= nil, "src/ must be visible")
  assert_true(paths["src/utils.lua"] ~= nil, "src/utils.lua must be visible")
  assert_true(paths["docs"] ~= nil, "docs/ must be visible")
  assert_true(paths["docs/guide.md"] ~= nil, "docs/guide.md must be visible")

  -- Dot-prefixed items at root and nested levels MUST be hidden
  assert_true(paths[".env"] == nil, ".env must be hidden by default")
  assert_true(paths[".gitignore"] == nil, ".gitignore must be hidden by default")
  assert_true(paths[".vscode"] == nil, ".vscode must be hidden by default")
  assert_true(paths[".vscode/settings.json"] == nil, ".vscode/settings.json must be hidden by default")
  assert_true(paths[".github"] == nil, ".github must be hidden by default")
  assert_true(paths[".github/workflows"] == nil, ".github/workflows must be hidden by default")
  assert_true(paths["src/.secret_module"] == nil, "src/.secret_module must be hidden by default")
  assert_true(paths["src/.secret_module/token.lua"] == nil, "nested dot-folder contents must be hidden")
  assert_true(paths["docs/.hidden_note"] == nil, "docs/.hidden_note must be hidden by default")

  -- Test Workbench Project Browser integration
  workbench.open({ view = "files" })
  local state = workbench.get_state()
  assert_true(state.is_open, "workbench must be open")
  assert_eq(state.view_mode, "files", "view mode must be files")

  local left_lines = vim.api.nvim_buf_get_lines(state.buf_left, 0, -1, false)
  local left_text = table.concat(left_lines, "\n")
  assert_true(left_text:find("PROJECT BROWSER") ~= nil, "left header must show PROJECT BROWSER")
  assert_true(left_text:find("main.lua") ~= nil, "main.lua must appear in rendered pane")
  assert_true(left_text:find("src/") ~= nil, "src/ must appear in rendered pane")
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
  local settings_ui = require("novim.settings_ui")
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
  local tree_revealed, _ = browser.get_tree(fixture, true)
  local paths_revealed = {}
  for _, entry in ipairs(tree_revealed) do
    paths_revealed[entry.path] = entry
  end

  -- Verify all dotfiles and dot-folders are now visible
  assert_true(paths_revealed[".env"] ~= nil, ".env must be revealed")
  assert_true(paths_revealed[".gitignore"] ~= nil, ".gitignore must be revealed")
  assert_true(paths_revealed[".vscode"] ~= nil, ".vscode must be revealed")
  assert_true(paths_revealed[".vscode/settings.json"] ~= nil, ".vscode/settings.json must be revealed")
  assert_true(paths_revealed[".github"] ~= nil, ".github must be revealed")
  assert_true(paths_revealed["src/.secret_module"] ~= nil, "src/.secret_module must be revealed")
  assert_true(paths_revealed["src/.secret_module/token.lua"] ~= nil, "nested dot-folder file must be revealed")
  assert_true(paths_revealed["docs/.hidden_note"] ~= nil, "docs/.hidden_note must be revealed")

  -- Normal entries remain visible
  assert_true(paths_revealed["main.lua"] ~= nil, "main.lua must remain visible")
  assert_true(paths_revealed["src/utils.lua"] ~= nil, "src/utils.lua must remain visible")

  -- 2. Disable show_dotfiles via toggle
  local ok2, err2, val_hidden = settings.toggle_dotfiles()
  assert_true(ok2 == true, "toggle must succeed: " .. tostring(err2))
  assert_true(val_hidden == false, "toggle must return false")
  assert_true(settings.get("show_dotfiles") == false, "settings.get must return false")
  workbench.refresh()
  local tree_hidden, _ = browser.get_tree(fixture, false)
  local paths_hidden = {}
  for _, entry in ipairs(tree_hidden) do
    paths_hidden[entry.path] = entry
  end

  assert_true(paths_hidden[".env"] == nil, ".env must be hidden again")
  assert_true(paths_hidden[".vscode"] == nil, ".vscode must be hidden again")
  assert_true(paths_hidden["src/.secret_module"] == nil, "nested dot-folder must be hidden again")
  assert_true(paths_hidden["main.lua"] ~= nil, "normal files must still be visible")

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
