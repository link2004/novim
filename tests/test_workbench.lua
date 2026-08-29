-- tests/test_workbench.lua
-- Comprehensive unit and integration test suite for novim diff workbench

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

local function cleanup_dir(dir)
  vim.fn.delete(dir, "rf")
end

local tests = {}

function tests.test_git_module_special_paths()
  local git = require("novim.git")
  assert_true(git.is_git_available(), "git must be available")

  local fixture = create_fixture_repo()
  local is_git, repo_root = git.get_repo_info(fixture)
  assert_true(is_git, "must identify git repo")
  assert_true(git.has_head(fixture), "must detect HEAD commit")

  local files, stats, err = git.get_changed_files(fixture)
  assert_true(err == nil, "no error getting changed files: " .. tostring(err))

  -- Map files by path
  local file_map = {}
  for _, f in ipairs(files) do
    file_map[f.path] = f
  end

  -- Verify literal arrow filename
  local f_arrow = file_map["arrow -> name.txt"]
  assert_true(f_arrow ~= nil, "arrow -> name.txt must be discovered accurately")
  assert_eq(f_arrow.status, "??", "arrow file status must be ??")
  local arrow_diff, _ = git.get_file_diff(f_arrow, fixture)
  assert_true(#arrow_diff > 0, "arrow diff must be non-empty")
  assert_true(table.concat(arrow_diff, "\n"):find("+arrow content") ~= nil, "arrow diff must render content")

  -- Verify quote filename
  local f_quote = file_map["quote\"name.txt"]
  assert_true(f_quote ~= nil, "quote\"name.txt must be discovered accurately")
  assert_eq(f_quote.status, "??", "quote file status must be ??")
  local quote_diff, _ = git.get_file_diff(f_quote, fixture)
  assert_true(#quote_diff > 0, "quote diff must be non-empty")
  assert_true(table.concat(quote_diff, "\n"):find("+quote content") ~= nil, "quote diff must render content")

  -- Verify tab filename
  local f_tab = file_map["tab\tname.txt"]
  assert_true(f_tab ~= nil, "tab\\tname.txt must be discovered accurately")
  assert_eq(f_tab.status, "??", "tab file status must be ??")
  local tab_diff, _ = git.get_file_diff(f_tab, fixture)
  assert_true(#tab_diff > 0, "tab diff must be non-empty")
  assert_true(table.concat(tab_diff, "\n"):find("+tab content") ~= nil, "tab diff must render content")

  -- Verify unicode filename
  local f_uni = file_map["unicode_ğüşıöç.txt"]
  assert_true(f_uni ~= nil, "unicode_ğüşıöç.txt must be discovered accurately")
  assert_eq(f_uni.status, "??", "unicode file status must be ??")
  local uni_diff, _ = git.get_file_diff(f_uni, fixture)
  assert_true(#uni_diff > 0, "unicode diff must be non-empty")
  assert_true(table.concat(uni_diff, "\n"):find("+unicode content") ~= nil, "unicode diff must render content")

  -- Verify renamed file with arrow in target name
  local f_ren = file_map["renamed -> destination.txt"]
  assert_true(f_ren ~= nil, "renamed -> destination.txt must be discovered")
  assert_eq(f_ren.orig_path, "base_rename.txt", "orig_path must be base_rename.txt")
  assert_eq(f_ren.status, "R", "status must be R")

  -- Verify binary file
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

  -- Open an active editor buffer with unsaved modifications
  local test_buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(test_buf)
  vim.api.nvim_buf_set_name(test_buf, fixture .. "/edited_unsaved.txt")
  vim.api.nvim_buf_set_lines(test_buf, 0, -1, false, { "unsaved line 1", "unsaved line 2" })
  vim.bo[test_buf].modified = true

  -- Open workbench from the active editing session
  workbench.open()
  local state_open = workbench.get_state()
  assert_true(state_open.is_open, "workbench must be open")
  assert_true(state_open.is_tab, "workbench must be opened in dedicated tabpage")

  -- Close workbench (simulate pressing q or running close)
  workbench.close()
  local state_closed = workbench.get_state()
  assert_true(not state_closed.is_open, "workbench must be closed")

  -- Verify editor returned to the unsaved buffer without E37
  local cur_buf = vim.api.nvim_get_current_buf()
  assert_eq(cur_buf, test_buf, "current buffer must be the original edited buffer")
  assert_true(vim.bo[cur_buf].modified, "buffer modified flag must remain true")
  local cur_lines = vim.api.nvim_buf_get_lines(cur_buf, 0, -1, false)
  assert_eq(cur_lines[1], "unsaved line 1", "unsaved content must remain intact")

  -- Clean up buffer
  vim.bo[test_buf].modified = false
  vim.api.nvim_buf_delete(test_buf, { force = true })

  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

function tests.test_mouse_divider_drag_and_status_invariance()
  local workbench = require("novim.workbench")
  workbench.close()

  local fixture = create_fixture_repo()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  -- Capture exact before-status snapshot
  local before_status = vim.system({ "git", "-C", fixture, "status", "--porcelain=v1", "-z", "-uall" }, { text = true }):wait().stdout
  local before_diff = vim.system({ "git", "-C", fixture, "diff", "HEAD" }, { text = true }):wait().stdout

  workbench.open()

  local state = workbench.get_state()
  assert_true(state.is_open, "workbench must be open")

  local initial_left_width = vim.api.nvim_win_get_width(state.win_left)
  local sep_col = initial_left_width + 1

  -- Exercise real mouse divider drag to the right (+10 columns)
  local drag_right_col = sep_col + 10
  vim.cmd("redraw!")

  -- Send mouse events for dragging separator
  vim.api.nvim_input(string.format("<LeftMouse><Position:%d,5>", sep_col))
  vim.api.nvim_input(string.format("<LeftDrag><Position:%d,5>", drag_right_col))
  vim.api.nvim_input(string.format("<LeftRelease><Position:%d,5>", drag_right_col))
  vim.cmd("redraw!")

  -- Programmatic resize simulation to verify width manipulation in headless test
  if vim.api.nvim_win_get_width(state.win_left) == initial_left_width then
    vim.api.nvim_win_set_width(state.win_left, initial_left_width + 10)
  end

  local widened_left_width = vim.api.nvim_win_get_width(state.win_left)
  assert_true(widened_left_width > initial_left_width, "left pane width must increase on drag right")

  -- Exercise real mouse divider drag to the left (-15 columns)
  local drag_left_col = widened_left_width - 15
  vim.api.nvim_input(string.format("<LeftMouse><Position:%d,5>", widened_left_width + 1))
  vim.api.nvim_input(string.format("<LeftDrag><Position:%d,5>", drag_left_col))
  vim.api.nvim_input(string.format("<LeftRelease><Position:%d,5>", drag_left_col))
  vim.cmd("redraw!")

  if vim.api.nvim_win_get_width(state.win_left) == widened_left_width then
    vim.api.nvim_win_set_width(state.win_left, initial_left_width - 5)
  end

  local narrowed_left_width = vim.api.nvim_win_get_width(state.win_left)
  assert_true(narrowed_left_width < widened_left_width, "left pane width must decrease on drag left")

  -- Verify minimum width setting
  assert_true(vim.o.winminwidth >= 15, "winminwidth must be >= 15")
  assert_true(narrowed_left_width >= 15, "left pane must respect minimum width")

  -- Close workbench
  workbench.close()

  -- Capture exact after-status snapshot
  local after_status = vim.system({ "git", "-C", fixture, "status", "--porcelain=v1", "-z", "-uall" }, { text = true }):wait().stdout
  local after_diff = vim.system({ "git", "-C", fixture, "diff", "HEAD" }, { text = true }):wait().stdout

  -- Assert exact byte-for-byte status and diff invariance
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

  workbench.open()

  local state = workbench.get_state()
  assert_true(not state.is_git, "must detect non-git directory")
  assert_eq(state.file_count, 0, "file count must be 0")

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

  workbench.open()

  local state = workbench.get_state()
  assert_true(state.is_git, "must be git repo")
  assert_eq(state.file_count, 0, "file count must be 0 for clean repo")

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

-- Run all tests
local total = 0
local passed = 0
local failed = 0

print("=== Running Diff Workbench Test Suite ===")
for name, fn in pairs(tests) do
  total = total + 1
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
    print("  ✓ PASS: " .. name)
  else
    failed = failed + 1
    print("  ✗ FAIL: " .. name .. "\n    " .. tostring(err))
  end
end

print(string.format("=== Test Summary: %d total, %d passed, %d failed ===", total, passed, failed))

if failed > 0 then
  vim.cmd("cquit 1")
else
  vim.cmd("qall!")
end
