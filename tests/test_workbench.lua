-- tests/test_workbench.lua
-- Unit and integration tests for novim diff workbench

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

  run_cmd("git -C " .. vim.fn.shellescape(fixture_dir) .. " add .")
  run_cmd("git -C " .. vim.fn.shellescape(fixture_dir) .. " commit -q -m 'Initial commit'")

  -- Working tree modifications:
  -- 1. Modify tracked_modified.txt
  local f1_mod = io.open(file1, "w")
  f1_mod:write("initial line 1\nMODIFIED line 2\ninitial line 3\nNEW line 4\n")
  f1_mod:close()

  -- 2. Delete tracked_deleted.txt
  os.remove(file2)

  -- 3. Create untracked file
  local file_untracked = fixture_dir .. "/untracked_new.txt"
  local f_untracked = io.open(file_untracked, "w")
  f_untracked:write("untracked line 1\nuntracked line 2\n")
  f_untracked:close()

  -- 4. Create untracked binary file
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

function tests.test_git_module()
  local git = require("novim.git")
  assert_true(git.is_git_available(), "git must be available")

  local fixture = create_fixture_repo()
  local is_git, repo_root = git.get_repo_info(fixture)
  assert_true(is_git, "must identify git repo")
  assert_true(git.has_head(fixture), "must detect HEAD commit")

  local files, stats, err = git.get_changed_files(fixture)
  assert_true(err == nil, "no error getting changed files: " .. tostring(err))
  assert_true(#files >= 4, "must find at least 4 changed/untracked files, found: " .. #files)
  assert_true(stats.total >= 4, "stats total must match file count")
  assert_true(stats.modified >= 1, "must have at least 1 modified file")
  assert_true(stats.deleted >= 1, "must have at least 1 deleted file")
  assert_true(stats.untracked >= 2, "must have at least 2 untracked files")

  -- Check diff for modified file
  local mod_file = nil
  for _, f in ipairs(files) do
    if f.path == "tracked_modified.txt" then
      mod_file = f
      break
    end
  end
  assert_true(mod_file ~= nil, "tracked_modified.txt must be found")
  assert_eq(mod_file.status, "M", "status must be M")
  local mod_diff, is_bin = git.get_file_diff(mod_file, fixture)
  assert_true(#mod_diff > 0, "diff must not be empty")
  assert_true(not is_bin, "text file must not be binary")
  local mod_diff_str = table.concat(mod_diff, "\n")
  assert_true(mod_diff_str:find("+MODIFIED line 2") ~= nil, "diff must show modified line")
  assert_true(mod_diff_str:find("+NEW line 4") ~= nil, "diff must show added line")

  -- Check diff for untracked file (all-additions diff)
  local untracked_file = nil
  for _, f in ipairs(files) do
    if f.path == "untracked_new.txt" then
      untracked_file = f
      break
    end
  end
  assert_true(untracked_file ~= nil, "untracked_new.txt must be found")
  assert_true(untracked_file.is_untracked, "must be marked untracked")
  local untracked_diff, u_is_bin = git.get_file_diff(untracked_file, fixture)
  assert_true(#untracked_diff > 0, "untracked diff must not be empty")
  assert_true(not u_is_bin, "text untracked must not be binary")
  local u_diff_str = table.concat(untracked_diff, "\n")
  assert_true(u_diff_str:find("+untracked line 1") ~= nil, "untracked diff must show addition lines")

  -- Check diff for deleted file
  local del_file = nil
  for _, f in ipairs(files) do
    if f.path == "tracked_deleted.txt" then
      del_file = f
      break
    end
  end
  assert_true(del_file ~= nil, "tracked_deleted.txt must be found")
  assert_true(del_file.is_deleted, "must be marked deleted")
  local del_diff, d_is_bin = git.get_file_diff(del_file, fixture)
  assert_true(#del_diff > 0, "deleted diff must not be empty")
  local d_diff_str = table.concat(del_diff, "\n")
  assert_true(d_diff_str:find("-to be deleted") ~= nil, "diff must show deleted line")

  -- Check binary file detection
  local bin_file = nil
  for _, f in ipairs(files) do
    if f.path == "binary_file.bin" then
      bin_file = f
      break
    end
  end
  assert_true(bin_file ~= nil, "binary_file.bin must be found")
  local bin_diff, b_is_bin = git.get_file_diff(bin_file, fixture)
  assert_true(b_is_bin, "binary file must be identified as binary")

  cleanup_dir(fixture)
end

function tests.test_workbench_ui_integration()
  local fixture = create_fixture_repo()
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  local workbench = require("novim.workbench")
  workbench.open()

  local state = workbench.get_state()
  assert_true(state.is_open, "workbench must be marked open")
  assert_true(state.is_git, "must detect git repo in cwd")
  assert_true(state.file_count >= 4, "must have loaded changed files")
  assert_true(state.win_left ~= nil and vim.api.nvim_win_is_valid(state.win_left), "left window must be valid")
  assert_true(state.win_right ~= nil and vim.api.nvim_win_is_valid(state.win_right), "right window must be valid")

  -- Verify buffer properties
  assert_eq(vim.bo[state.buf_left].buftype, "nofile", "left buffer buftype must be nofile")
  assert_eq(vim.bo[state.buf_right].buftype, "nofile", "right buffer buftype must be nofile")
  assert_eq(vim.bo[state.buf_left].modifiable, false, "left buffer must not be modifiable")
  assert_eq(vim.bo[state.buf_right].modifiable, false, "right buffer must not be modifiable")
  assert_eq(vim.bo[state.buf_left].readonly, true, "left buffer must be readonly")
  assert_eq(vim.bo[state.buf_right].readonly, true, "right buffer must be readonly")

  -- Verify left pane contents
  local left_lines = vim.api.nvim_buf_get_lines(state.buf_left, 0, -1, false)
  local left_text = table.concat(left_lines, "\n")
  assert_true(left_text:find("DIFF WORKBENCH") ~= nil, "left pane must contain header")
  assert_true(left_text:find("tracked_modified.txt") ~= nil, "left pane must list modified file")
  assert_true(left_text:find("untracked_new.txt") ~= nil, "left pane must list untracked file")
  assert_true(left_text:find("tracked_deleted.txt") ~= nil, "left pane must list deleted file")

  -- Verify right pane contents for first selection
  local right_lines = vim.api.nvim_buf_get_lines(state.buf_right, 0, -1, false)
  assert_true(#right_lines > 0, "right pane must contain diff lines")

  -- Test selecting another file
  workbench.select_file(2)
  local updated_state = workbench.get_state()
  assert_eq(updated_state.selected_index, 2, "selected index must be updated")
  local right_lines_2 = vim.api.nvim_buf_get_lines(state.buf_right, 0, -1, false)
  assert_true(#right_lines_2 > 0, "right pane must update on file selection")

  -- Test resizing left window (divider dragging simulation)
  local initial_width = vim.api.nvim_win_get_width(state.win_left)
  vim.api.nvim_win_set_width(state.win_left, initial_width + 10)
  assert_eq(vim.api.nvim_win_get_width(state.win_left), initial_width + 10, "left window must widen")
  vim.api.nvim_win_set_width(state.win_left, initial_width - 5)
  assert_eq(vim.api.nvim_win_get_width(state.win_left), initial_width - 5, "left window must narrow")

  -- Verify minimum width setting
  assert_true(vim.o.winminwidth >= 15, "winminwidth must be at least 15")

  -- Test help popup
  workbench.show_help()
  local help_wins = vim.api.nvim_list_wins()
  assert_true(#help_wins > 2, "help window must open")
  -- Close help window (simulate pressing q)
  vim.cmd("wincmd c")

  -- Verify Git status invariance (no mutations occurred)
  local status_after = vim.fn.system("git -C " .. vim.fn.shellescape(fixture) .. " status --short")
  assert_true(#status_after > 0, "status must remain unchanged")
  assert_true(status_after:find("tracked_modified.txt") ~= nil, "modified file still in status")
  assert_true(status_after:find("untracked_new.txt") ~= nil, "untracked file still in status")

  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

function tests.test_non_git_directory()
  local temp_dir = vim.fn.tempname() .. "_nongit"
  vim.fn.mkdir(temp_dir, "p")
  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(temp_dir))

  local workbench = require("novim.workbench")
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

  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(temp_dir)
end

function tests.test_clean_repository()
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

  local workbench = require("novim.workbench")
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
