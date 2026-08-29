-- tests/test_smoke.lua
-- Deterministic regression smoke test suite for novim-dev launcher and diff workbench
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

-- Resolve project root dynamically from this test script's location
local script_source = debug.getinfo(1, "S").source
if script_source:sub(1, 1) == "@" then
  script_source = script_source:sub(2)
end
local script_path = vim.fs.normalize(vim.fn.fnamemodify(script_source, ":p"))
local project_root = os.getenv("NOVIM_PROJECT_ROOT")
if not project_root or project_root == "" then
  project_root = vim.fs.dirname(vim.fs.dirname(script_path))
end
project_root = vim.fs.normalize(project_root)

-- Determine run-specific temporary fixture root
local smoke_temp_root = os.getenv("NOVIM_SMOKE_TEMP_ROOT")
if not smoke_temp_root or smoke_temp_root == "" or vim.fn.isdirectory(smoke_temp_root) == 0 then
  smoke_temp_root = vim.fn.tempname() .. "_smoke_root"
  vim.fn.mkdir(smoke_temp_root, "p")
end
smoke_temp_root = vim.fs.normalize(smoke_temp_root)

-- Track all created fixtures to guarantee 100% cleanup even on failure
local created_fixtures = {}
local fixture_seq = 0

local function create_temp_fixture_dir(prefix)
  fixture_seq = fixture_seq + 1
  local dir = smoke_temp_root .. "/" .. (prefix or "fixture") .. "_" .. tostring(fixture_seq)
  vim.fn.mkdir(dir, "p")
  table.insert(created_fixtures, dir)
  return dir
end

local function cleanup_dir(dir)
  if dir and vim.fn.isdirectory(dir) == 1 then
    local res = vim.fn.delete(dir, "rf")
    if res ~= 0 then
      error("Failed to delete fixture directory: " .. dir, 2)
    end
  end
end

local function cleanup_all_fixtures()
  for _, dir in ipairs(created_fixtures) do
    if vim.fn.isdirectory(dir) == 1 then
      local res = vim.fn.delete(dir, "rf")
      if res ~= 0 then
        error("Failed to delete fixture directory during teardown: " .. dir, 2)
      end
    end
  end
end

local function run_cmd(cmd)
  local out = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    error("Command failed: " .. cmd .. "\nOutput: " .. out)
  end
  return out
end

--- Create a fixture Git repository with tracked modified, deleted, renamed, untracked, binary, and clean files
local function create_smoke_git_fixture()
  local fixture_dir = create_temp_fixture_dir("smoke_git_fixture")

  run_cmd("git -C " .. vim.fn.shellescape(fixture_dir) .. " init -q")
  run_cmd("git -C " .. vim.fn.shellescape(fixture_dir) .. " config user.email 'smoke-test@example.com'")
  run_cmd("git -C " .. vim.fn.shellescape(fixture_dir) .. " config user.name 'Smoke Test Runner'")

  -- 1. Base clean tracked file
  local f_clean = fixture_dir .. "/tracked_clean.txt"
  local fc = io.open(f_clean, "w")
  fc:write("clean line 1\nclean line 2\n")
  fc:close()

  -- 2. Base modified tracked file
  local f_mod = fixture_dir .. "/tracked_modified.txt"
  local fm = io.open(f_mod, "w")
  fm:write("line 1\nline 2\nline 3\n")
  fm:close()

  -- 3. Base deleted tracked file
  local f_del = fixture_dir .. "/tracked_deleted.txt"
  local fd = io.open(f_del, "w")
  fd:write("delete this line\n")
  fd:close()

  -- 4. Base rename file
  local f_ren = fixture_dir .. "/base_rename.txt"
  local fr = io.open(f_ren, "w")
  fr:write("rename content\n")
  fr:close()

  run_cmd("git -C " .. vim.fn.shellescape(fixture_dir) .. " add .")
  run_cmd("git -C " .. vim.fn.shellescape(fixture_dir) .. " commit -q -m 'Initial commit'")

  -- Apply working-tree modifications:
  -- Modify tracked_modified.txt
  local fm2 = io.open(f_mod, "w")
  fm2:write("line 1\nMODIFIED line 2\nline 3\nNEW line 4\n")
  fm2:close()

  -- Delete tracked_deleted.txt
  os.remove(f_del)

  -- Rename base_rename.txt to a path with special characters (arrow & spaces)
  run_cmd("git -C " .. vim.fn.shellescape(fixture_dir) .. " mv base_rename.txt \"renamed -> destination.txt\"")

  -- Create untracked regular file
  local f_untracked = fixture_dir .. "/untracked_new.txt"
  local fu = io.open(f_untracked, "w")
  fu:write("untracked line 1\nuntracked line 2\n")
  fu:close()

  -- Create untracked binary file
  local f_bin = fixture_dir .. "/binary_file.bin"
  local fb = io.open(f_bin, "wb")
  fb:write("\0\1\2\3\4\5\255\254")
  fb:close()

  return fixture_dir
end

--- Create a fixture project with regular files, directories, root dotfiles, and nested dot-folders
local function create_smoke_project_fixture()
  local dir = create_temp_fixture_dir("smoke_project_fixture")

  -- Top-level regular files
  local f1 = io.open(dir .. "/main.lua", "w")
  f1:write("local app = {}\nfunction app.run()\n  print('hello smoke')\nend\nreturn app\n")
  f1:close()

  local f2 = io.open(dir .. "/README.md", "w")
  f2:write("# Smoke Project Fixture\nSmoke test documentation.\n")
  f2:close()

  -- Subdirectories with regular files
  vim.fn.mkdir(dir .. "/src", "p")
  local f3 = io.open(dir .. "/src/utils.lua", "w")
  f3:write("local M = {}\nfunction M.add(a, b) return a + b end\nreturn M\n")
  f3:close()

  vim.fn.mkdir(dir .. "/docs", "p")
  local f4 = io.open(dir .. "/docs/architecture.md", "w")
  f4:write("# Architecture\nDetailed system overview.\n")
  f4:close()

  -- Root dotfiles
  local d1 = io.open(dir .. "/.env", "w")
  d1:write("DEV_KEY=smoke_secret_123\n")
  d1:close()

  local d2 = io.open(dir .. "/.gitignore", "w")
  d2:write(".env\n.dev-*\n")
  d2:close()

  -- Nested dot-folders
  vim.fn.mkdir(dir .. "/.vscode", "p")
  local d3 = io.open(dir .. "/.vscode/settings.json", "w")
  d3:write("{\"editor.tabSize\": 2}\n")
  d3:close()

  vim.fn.mkdir(dir .. "/.github/workflows", "p")
  local d4 = io.open(dir .. "/.github/workflows/smoke.yml", "w")
  d4:write("name: Smoke\n")
  d4:close()

  -- Nested dotfile inside regular directory
  vim.fn.mkdir(dir .. "/src/.secret_module", "p")
  local d5 = io.open(dir .. "/src/.secret_module/token.lua", "w")
  d5:write("return 'secret_token'\n")
  d5:close()

  return dir
end

local smoke_tests = {}

-- =========================================================================
-- 1. Launcher Startup, Config Root & Runtime Path Isolation
-- =========================================================================

function smoke_tests.test_smoke_launcher_startup_and_isolated_paths()
  local config_path = vim.fs.normalize(vim.fn.stdpath("config"))
  local data_path = vim.fs.normalize(vim.fn.stdpath("data"))
  local state_path = vim.fs.normalize(vim.fn.stdpath("state"))
  local cache_path = vim.fs.normalize(vim.fn.stdpath("cache"))

  -- Exact expected path derivations from the resolved project root
  local expected_config = vim.fs.normalize(project_root .. "/config/nvim")
  local expected_data = vim.fs.normalize(project_root .. "/.dev-data/nvim")
  local expected_state = vim.fs.normalize(project_root .. "/.dev-state/nvim")
  local expected_cache = vim.fs.normalize(project_root .. "/.dev-cache/nvim")

  -- Verify stdpath exactly matches the checkout's isolated paths
  assert_eq(config_path, expected_config, "stdpath config must exactly match checkout config root")
  assert_eq(data_path, expected_data, "stdpath data must exactly match checkout .dev-data root")
  assert_eq(state_path, expected_state, "stdpath state must exactly match checkout .dev-state root")
  assert_eq(cache_path, expected_cache, "stdpath cache must exactly match checkout .dev-cache root")

  -- Verify installed novim path is not part of any stdpath
  assert_true(not config_path:find("%.local/share/novim"), "stdpath config must not point to installed novim")
  assert_true(not data_path:find("%.local/share/novim"), "stdpath data must not point to installed novim")
  assert_true(not state_path:find("%.local/share/novim"), "stdpath state must not point to installed novim")
  assert_true(not cache_path:find("%.local/share/novim"), "stdpath cache must not point to installed novim")

  -- Verify settings file path is derived from the isolated state directory
  local settings = require("novim.settings")
  local expected_settings_file = vim.fs.normalize(expected_state .. "/novim_settings.json")
  assert_eq(vim.fs.normalize(settings.get_settings_file_path()), expected_settings_file, "settings file path must live under isolated state path")

  -- Verify custom user commands are registered
  local commands = vim.api.nvim_get_commands({})
  assert_true(commands["Workbench"] ~= nil, "Workbench command must be registered")
  assert_true(commands["DiffWorkbench"] ~= nil, "DiffWorkbench command must be registered")
  assert_true(commands["ProjectBrowser"] ~= nil, "ProjectBrowser command must be registered")
  assert_true(commands["Files"] ~= nil, "Files command must be registered")
  assert_true(commands["Settings"] ~= nil, "Settings command must be registered")

  -- Verify Tokyo Night highlights are defined
  local hl_normal = vim.api.nvim_get_hl(0, { name = "Normal" })
  assert_true(hl_normal ~= nil, "Normal highlight must be defined")
  local hl_diff_add = vim.api.nvim_get_hl(0, { name = "diffAdded" })
  assert_true(hl_diff_add ~= nil, "diffAdded highlight must be defined")
  local hl_header = vim.api.nvim_get_hl(0, { name = "WorkbenchHeader" })
  assert_true(hl_header ~= nil, "WorkbenchHeader highlight must be defined")
end

-- =========================================================================
-- 2. Two-Pane Workbench Layout, Divider Constraints & View Switching
-- =========================================================================

function smoke_tests.test_smoke_workbench_two_pane_layout_and_views()
  local fixture = create_smoke_project_fixture()
  local workbench = require("novim.workbench")
  workbench.close()

  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  -- Open workbench in files mode
  workbench.open({ view = "files" })

  local tab = vim.api.nvim_get_current_tabpage()
  local wins = vim.api.nvim_tabpage_list_wins(tab)
  assert_eq(#wins, 2, "workbench must open exactly 2 windows in the tab")

  local win_left = wins[1]
  local win_right = wins[2]
  local buf_left = vim.api.nvim_win_get_buf(win_left)

  -- Left buffer options check
  assert_eq(vim.bo[buf_left].buftype, "nofile", "left buffer must be nofile")
  assert_eq(vim.bo[buf_left].modifiable, false, "left buffer must be non-modifiable")

  -- Left window line numbering disabled
  assert_eq(vim.wo[win_left].number, false, "left window must disable line numbers")

  -- Minimum width / divider bounds check
  local initial_left_width = vim.api.nvim_win_get_width(win_left)
  assert_true(initial_left_width >= 15, "initial width must respect minimum width")

  local target_widen = initial_left_width + 10
  vim.api.nvim_win_set_width(win_left, target_widen)
  local widened_left_width = vim.api.nvim_win_get_width(win_left)
  assert_eq(widened_left_width, target_widen, "left pane width must increase on widen")

  local target_narrow = initial_left_width - 5
  vim.api.nvim_win_set_width(win_left, target_narrow)
  local narrowed_left_width = vim.api.nvim_win_get_width(win_left)
  assert_eq(narrowed_left_width, target_narrow, "left pane width must decrease on narrow")
  assert_true(narrowed_left_width >= 15, "left pane width must be >= 15")

  -- Header tab rendering in files view
  local left_lines = vim.api.nvim_buf_get_lines(buf_left, 0, -1, false)
  local header_text = table.concat(left_lines, "\n")
  assert_true(header_text:find("PROJECT BROWSER") ~= nil, "header must show PROJECT BROWSER in files view")
  assert_true(header_text:find("Files") ~= nil, "header must show Files tab")
  assert_true(header_text:find("Git Diff") ~= nil, "header must show Git Diff tab")
  assert_true(header_text:find("Settings") ~= nil, "header must show Settings tab")

  -- Switch view to diff
  workbench.set_view("diff")
  assert_eq(workbench.get_state().view_mode, "diff", "view mode must switch to diff")
  left_lines = vim.api.nvim_buf_get_lines(buf_left, 0, -1, false)
  header_text = table.concat(left_lines, "\n")
  assert_true(header_text:find("DIFF WORKBENCH") ~= nil, "header must show DIFF WORKBENCH in diff view")

  -- Toggle view back to files
  workbench.toggle_view()
  assert_eq(workbench.get_state().view_mode, "files", "toggle_view must switch back to files")

  -- Close workbench
  workbench.close()
  assert_true(not workbench.get_state().is_open, "workbench.close() must close workbench")

  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

-- =========================================================================
-- 3. Source Navigation, Editing Handoff & Unsaved Buffer Preservation
-- =========================================================================

function smoke_tests.test_smoke_source_navigation_editing_and_buffer_preservation()
  local fixture = create_smoke_project_fixture()
  local workbench = require("novim.workbench")
  workbench.close()

  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(fixture))

  workbench.open({ view = "files" })
  local state = workbench.get_state()
  assert_true(state.is_open, "workbench must be open")
  assert_eq(state.view_mode, "files", "view mode must be files")

  -- Find a regular file entry in project_files
  local target_entry = nil
  local target_idx = nil
  for idx, entry in ipairs(state.project_files) do
    if not entry.is_dir and entry.name == "main.lua" then
      target_entry = entry
      target_idx = idx
      break
    end
  end
  assert_true(target_entry ~= nil, "fixture must contain main.lua")

  -- Select and open main.lua
  workbench.select_file(target_idx)
  local open_ok = workbench.open_file(target_entry)
  assert_true(open_ok, "opening a regular file must succeed")

  -- Verify current window is now the right editor window
  local cur_win = vim.api.nvim_get_current_win()
  assert_eq(cur_win, state.win_right, "open_file must focus the right editor window")
  local edit_buf = vim.api.nvim_win_get_buf(cur_win)
  assert_eq(vim.bo[edit_buf].buftype, "", "editor buffer must be a regular buffer (buftype='')")
  assert_eq(vim.bo[edit_buf].modifiable, true, "editor buffer must be modifiable")

  -- Add in-memory unsaved edits
  vim.api.nvim_buf_set_lines(edit_buf, -1, -1, false, { "-- UNCOMMITTED SMOKE EDIT" })
  assert_true(vim.bo[edit_buf].modified, "buffer must be marked modified after in-memory edit")

  -- Navigate back to left pane and switch view to diff
  vim.api.nvim_set_current_win(state.win_left)
  workbench.set_view("diff")
  assert_eq(workbench.get_state().view_mode, "diff", "view mode should be diff")

  -- Switch back to files view
  workbench.set_view("files")

  -- Verify unsaved buffer content was preserved
  local edit_lines = vim.api.nvim_buf_get_lines(edit_buf, 0, -1, false)
  local found_edit = false
  for _, l in ipairs(edit_lines) do
    if l:find("UNCOMMITTED SMOKE EDIT") then
      found_edit = true
      break
    end
  end
  assert_true(found_edit, "unsaved in-memory edits must be preserved during view switching")
  assert_true(vim.bo[edit_buf].modified, "buffer modified state must remain true")

  -- Find directory 'src' entry in project_files
  local dir_entry = nil
  local dir_idx = nil
  for idx, entry in ipairs(workbench.get_state().project_files) do
    if entry.is_dir and entry.name == "src" then
      dir_entry = entry
      dir_idx = idx
      break
    end
  end
  assert_true(dir_entry ~= nil, "src/ directory must be present in project tree")

  -- Select directory: must remain read-only inspection, NOT open file
  workbench.select_file(dir_idx)
  local dir_open_result = workbench.open_file(dir_entry)
  assert_true(not dir_open_result, "open_file on directory must return false")

  -- Verify right window remains read-only inspection preview
  local preview_buf = vim.api.nvim_win_get_buf(state.win_right)
  assert_eq(vim.bo[preview_buf].buftype, "nofile", "directory selection must keep buftype=nofile preview")
  assert_eq(vim.bo[preview_buf].readonly, true, "directory preview must be readonly")

  -- Close workbench tab: verify modified editor buffer remains intact in vim buffer list
  workbench.close()
  assert_true(vim.api.nvim_buf_is_valid(edit_buf), "editor buffer must remain valid after workbench close")
  assert_true(vim.bo[edit_buf].modified, "editor buffer must retain unsaved modified state")

  -- Clean up buffer
  vim.api.nvim_buf_delete(edit_buf, { force = true })
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(fixture)
end

-- =========================================================================
-- 4. Git Diff Rendering & Byte-for-Byte Git Invariance
-- =========================================================================

function smoke_tests.test_smoke_git_diff_rendering_and_read_only_invariance()
  local git_fixture = create_smoke_git_fixture()
  local git = require("novim.git")
  local workbench = require("novim.workbench")
  workbench.close()

  local old_cwd = vim.fn.getcwd()
  vim.cmd("cd " .. vim.fn.fnameescape(git_fixture))

  -- Capture baseline git status and diff before any workbench action
  local initial_status = run_cmd("git -C " .. vim.fn.shellescape(git_fixture) .. " status --porcelain=v1 -z")
  local initial_diff = run_cmd("git -C " .. vim.fn.shellescape(git_fixture) .. " diff HEAD")

  -- Query changed files directly from git module
  local files, stats, err = git.get_changed_files(git_fixture)
  assert_true(err == nil, "get_changed_files must not return error, got: " .. tostring(err))
  assert_true(#files >= 5, "must detect at least 5 changed/untracked files, got: " .. #files)
  assert_true(stats.total >= 5, "stats total must match files count")

  -- Verify detection of modified, deleted, renamed, untracked, and binary files
  local found_mod = false
  local found_del = false
  local found_ren = false
  local found_untracked = false
  local found_bin = false

  for _, f in ipairs(files) do
    if f.path == "tracked_modified.txt" and f.status == "M" then
      found_mod = true
      local diff_lines, is_bin = git.get_file_diff(f, git_fixture)
      assert_true(not is_bin, "tracked_modified.txt must not be binary")
      local diff_text = table.concat(diff_lines, "\n")
      assert_true(diff_text:find("%+MODIFIED line 2") ~= nil, "diff must contain +MODIFIED line 2")
      assert_true(diff_text:find("%+NEW line 4") ~= nil, "diff must contain +NEW line 4")
    elseif f.path == "tracked_deleted.txt" and f.status == "D" then
      found_del = true
      local diff_lines, is_bin = git.get_file_diff(f, git_fixture)
      assert_true(not is_bin, "tracked_deleted.txt must not be binary")
      local diff_text = table.concat(diff_lines, "\n")
      assert_true(diff_text:find("%-delete this line") ~= nil, "diff must contain -delete this line")
    elseif f.orig_path == "base_rename.txt" and f.status == "R" then
      found_ren = true
      local diff_lines, _ = git.get_file_diff(f, git_fixture)
      assert_true(#diff_lines > 0, "renamed file diff must contain header lines")
    elseif f.path == "untracked_new.txt" and f.is_untracked then
      found_untracked = true
      local diff_lines, is_bin = git.get_file_diff(f, git_fixture)
      assert_true(not is_bin, "untracked_new.txt must not be binary")
      local diff_text = table.concat(diff_lines, "\n")
      assert_true(diff_text:find("%+untracked line 1") ~= nil, "untracked diff must contain new lines")
    elseif f.path == "binary_file.bin" and f.is_untracked then
      found_bin = true
      local diff_lines, is_bin = git.get_file_diff(f, git_fixture)
      assert_true(is_bin, "binary_file.bin must be detected as binary")
      local joined = table.concat(diff_lines, "\n")
      assert_true(joined:find("Binary") ~= nil or joined:find("differ") ~= nil, "binary file diff must show binary notification")
    end
  end

  assert_true(found_mod, "tracked_modified.txt must be detected")
  assert_true(found_del, "tracked_deleted.txt must be detected")
  assert_true(found_ren, "renamed file with special characters must be detected")
  assert_true(found_untracked, "untracked_new.txt must be detected")
  assert_true(found_bin, "binary_file.bin must be detected")

  -- Open workbench in diff view and exercise UI navigation
  workbench.open({ view = "diff" })
  local state = workbench.get_state()
  assert_true(state.is_open, "workbench must be open")
  assert_eq(state.view_mode, "diff", "view mode must be diff")

  -- Exercise file selection and diff preview rendering
  for i = 1, #files do
    workbench.select_file(i)
  end

  -- Test cursor movement without error
  local line_count = vim.api.nvim_buf_line_count(state.buf_left)
  for line_num = state.header_line_count + 1, math.min(line_count, state.header_line_count + 3) do
    local ok, err = pcall(vim.api.nvim_win_set_cursor, state.win_left, { line_num, 2 })
    assert_true(ok, "cursor movement on left pane must succeed without error: " .. tostring(err))
    vim.cmd("doautocmd CursorMoved")
  end

  -- Close workbench
  workbench.close()

  -- Assert exact byte-for-byte Git status and diff invariance
  local post_status = run_cmd("git -C " .. vim.fn.shellescape(git_fixture) .. " status --porcelain=v1 -z")
  local post_diff = run_cmd("git -C " .. vim.fn.shellescape(git_fixture) .. " diff HEAD")

  assert_eq(post_status, initial_status, "git status output must be 100% byte-for-byte identical after workbench use")
  assert_eq(post_diff, initial_diff, "git diff output must be 100% byte-for-byte identical after workbench use")

  -- Non-git directory test: gracefully displays not a git repository message without crashing
  local non_git_dir = create_temp_fixture_dir("smoke_non_git")
  vim.cmd("cd " .. vim.fn.fnameescape(non_git_dir))
  workbench.open({ view = "diff" })
  local non_git_state = workbench.get_state()
  assert_true(non_git_state.is_open, "workbench must open in non-git directory")
  local non_git_lines = vim.api.nvim_buf_get_lines(non_git_state.buf_left, 0, -1, false)
  local found_non_git_msg = false
  for _, l in ipairs(non_git_lines) do
    if l:find("Not a Git Repository") or l:find("Not a Git repository") then
      found_non_git_msg = true
      break
    end
  end
  assert_true(found_non_git_msg, "non-git directory must display non-git message")
  workbench.close()
  cleanup_dir(non_git_dir)

  -- Clean git repo test: displays working tree clean
  local clean_repo = create_temp_fixture_dir("smoke_clean_git")
  run_cmd("git -C " .. vim.fn.shellescape(clean_repo) .. " init -q")
  run_cmd("git -C " .. vim.fn.shellescape(clean_repo) .. " config user.email 'smoke@example.com'")
  run_cmd("git -C " .. vim.fn.shellescape(clean_repo) .. " config user.name 'Smoke'")
  local cf = clean_repo .. "/clean.txt"
  local cfile = io.open(cf, "w")
  cfile:write("clean\n")
  cfile:close()
  run_cmd("git -C " .. vim.fn.shellescape(clean_repo) .. " add .")
  run_cmd("git -C " .. vim.fn.shellescape(clean_repo) .. " commit -q -m 'clean'")

  vim.cmd("cd " .. vim.fn.fnameescape(clean_repo))
  workbench.open({ view = "diff" })
  local clean_state = workbench.get_state()
  local clean_lines = vim.api.nvim_buf_get_lines(clean_state.buf_left, 0, -1, false)
  local found_clean_msg = false
  for _, l in ipairs(clean_lines) do
    if l:find("Working tree clean") then
      found_clean_msg = true
      break
    end
  end
  assert_true(found_clean_msg, "clean repository must display 'Working tree clean' message")
  workbench.close()
  cleanup_dir(clean_repo)

  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
  cleanup_dir(git_fixture)
end

-- =========================================================================
-- 5. Settings Persistence, Dotfile Toggle & Error Recovery
-- =========================================================================

function smoke_tests.test_smoke_settings_persistence_dotfile_toggle_and_error_recovery()
  local settings = require("novim.settings")
  local browser = require("novim.browser")
  local fixture = create_smoke_project_fixture()

  -- Use an isolated settings file in the run-specific temp root to prevent concurrency races
  local settings_temp_dir = create_temp_fixture_dir("smoke_settings_state")
  local test_settings_file = settings_temp_dir .. "/novim_settings.json"
  local orig_get_path = settings.get_settings_file_path
  settings.get_settings_file_path = function()
    return test_settings_file
  end

  local function restore_settings_path()
    settings.get_settings_file_path = orig_get_path
  end

  local ok, test_err = pcall(function()
    -- Reset settings cache and verify clean default
    settings.reset_cache()
    settings.set("show_dotfiles", false)
    assert_eq(settings.get("show_dotfiles"), false, "default show_dotfiles must be false")

    -- Scan root entries with show_dotfiles = false (lazy: root level only)
    local root_entries = browser.get_immediate_entries(fixture, "", 0, false)
    for _, item in ipairs(root_entries) do
      assert_true(not item.is_dot, "dotfile must not be present when show_dotfiles = false: " .. item.name)
      assert_true(not item.path:find("^%.") and not item.path:find("/%."), "nested dotfile must not be present: " .. item.path)
    end

    -- Toggle show_dotfiles to true
    local success, err, effective = settings.toggle_dotfiles()
    assert_true(success, "toggle_dotfiles must succeed")
    assert_eq(effective, true, "effective show_dotfiles must be true")

    -- Scan root entries with show_dotfiles = true
    root_entries = browser.get_immediate_entries(fixture, "", 0, true)
    local found_env = false
    local found_vscode = false
    local visible_dot_count = 0
    for _, item in ipairs(root_entries) do
      if item.name == ".env" then found_env = true end
      if item.name == ".vscode" then found_vscode = true end
      if item.is_dot then visible_dot_count = visible_dot_count + 1 end
    end
    assert_true(found_env, ".env must be revealed when show_dotfiles = true")
    assert_true(found_vscode, ".vscode must be revealed when show_dotfiles = true")
    assert_true(visible_dot_count > 0, "revealed dot entries must be visible at root")

    -- Nested dot-folder requires scanning its parent directory (lazy boundary)
    local src_children = browser.get_immediate_entries(fixture .. "/src", "src", 1, true)
    local found_secret = false
    for _, item in ipairs(src_children) do
      if item.name == ".secret_module" then found_secret = true end
    end
    assert_true(found_secret, ".secret_module must be revealed when show_dotfiles = true")

    -- Persistence check: reset in-memory cache and reload from disk
    settings.reset_cache()
    local reloaded = settings.load(true)
    assert_eq(reloaded.show_dotfiles, true, "reloaded setting from persistent file must retain show_dotfiles = true")

    -- Malformed settings file recovery
    local sf = io.open(test_settings_file, "w")
    if sf then
      sf:write("{ malformed_json: true, unterminated ...")
      sf:close()
    end
    settings.reset_cache()
    local fallback = settings.load(true)
    assert_eq(fallback.show_dotfiles, false, "malformed settings file must safely fallback to default show_dotfiles = false")

    -- Write failure handling: create directory at settings file path
    os.remove(test_settings_file)
    vim.fn.mkdir(test_settings_file, "p")

    settings.reset_cache()
    local toggle_ok, save_err, eff = settings.toggle_dotfiles()
    assert_true(toggle_ok == false, "toggle_dotfiles must return ok = false when write fails")
    assert_true(save_err ~= nil, "error message must be returned on write failure")
    assert_true(eff == false, "effective value must remain false")

    -- Clean up the blocker directory
    vim.fn.delete(test_settings_file, "rf")
  end)

  restore_settings_path()
  settings.reset_cache()
  cleanup_dir(settings_temp_dir)
  cleanup_dir(fixture)

  if not ok then
    error(test_err)
  end
end

-- =========================================================================
-- 6. Theme Selection, Settings Key Help, Immediate Esc Close & Pane Drag
-- =========================================================================

function smoke_tests.test_smoke_theme_selection_key_help_and_esc_close()
  local settings = require("novim.settings")
  local themes = require("novim.themes")
  local workbench = require("novim.workbench")
  local settings_ui = require("novim.settings_ui")
  local fixture = create_smoke_project_fixture()
  local old_cwd = vim.fn.getcwd()

  -- Use an isolated settings file in the run-specific temp root
  local settings_temp_dir = create_temp_fixture_dir("smoke_theme_state")
  local test_settings_file = settings_temp_dir .. "/novim_settings.json"
  local orig_get_path = settings.get_settings_file_path
  settings.get_settings_file_path = function()
    return test_settings_file
  end

  local ok, test_err = pcall(function()
    -- Missing settings file defaults to Tokyo Night; six themes are available
    settings.reset_cache()
    assert_eq(settings.get("theme"), "tokyo_night", "missing theme value must default to Tokyo Night")
    assert_eq(#themes.list(), 6, "exactly six built-in themes must be available")

    vim.cmd("cd " .. vim.fn.fnameescape(fixture))
    workbench.close()
    workbench.open({ view = "files" })
    local st = workbench.get_state()

    workbench.open_settings()
    assert_true(settings_ui.is_open(), "settings panel must open from the workbench")

    -- Key help renders below the theme and dot-folder controls
    local lines = vim.api.nvim_buf_get_lines(settings_ui.get_buf(), 0, -1, false)
    local theme_row, help_row, dot_row
    for i, l in ipairs(lines) do
      if l:find("Show Dot-Folders", 1, true) then dot_row = i end
      if l:find("Theme:", 1, true) then theme_row = i end
      if l:find("Key Bindings (Workbench)", 1, true) then help_row = i end
    end
    assert_true(dot_row ~= nil, "settings panel must render the dot-folder control")
    assert_true(theme_row ~= nil, "settings panel must render the theme control")
    assert_true(help_row ~= nil, "settings panel must render the key help section")
    assert_true(help_row > theme_row and theme_row > dot_row, "key help must render below the controls")
    assert_true(table.concat(lines, "\n"):find("q or Esc Esc", 1, true) ~= nil,
      "key help must document the workbench quit shortcut")

    -- One Esc press closes immediately and restores workbench focus
    local esc_cb = nil
    for _, m in ipairs(vim.api.nvim_buf_get_keymap(settings_ui.get_buf(), "n")) do
      if m.lhs == "<Esc>" then
        esc_cb = m.callback
      end
    end
    esc_cb()
    assert_true(not settings_ui.is_open(), "one Esc press must close settings immediately")
    assert_eq(vim.api.nvim_get_current_win(), st.win_left, "Esc must restore workbench focus")
    -- Theme cycling persists across a simulated fresh launch
    settings_ui.cycle_theme(1)
    assert_eq(settings.get("theme"), "nord", "cycling must select the next built-in theme")
    settings.reset_cache()
    assert_eq(settings.load(true).theme, "nord", "theme selection must persist across launches")

    -- Invalid persisted theme falls back safely and keeps unrelated settings
    local f = io.open(test_settings_file, "w")
    if f then
      f:write('{"theme": "dracula", "show_dotfiles": true}')
      f:close()
    end
    settings.reset_cache()
    local reloaded = settings.load(true)
    assert_eq(reloaded.theme, "tokyo_night", "invalid theme value must fall back to the default")
    assert_eq(reloaded.show_dotfiles, true, "invalid theme must not clobber unrelated settings")

    -- Application-owned divider drag works in both directions with clamping
    workbench.close()
    workbench.open({ view = "files" })
    st = workbench.get_state()
    local total = vim.o.columns
    local w0 = vim.api.nvim_win_get_width(st.win_left)
    local sep_col = vim.fn.win_screenpos(st.win_right)[2] - 1
    workbench.pane_drag_start(sep_col)
    workbench.pane_drag_move(sep_col + 10)
    local w_wider = vim.api.nvim_win_get_width(st.win_left)
    assert_true(w_wider > w0, "dragging right must widen the left pane")
    workbench.pane_drag_move(0)
    local w_min = vim.api.nvim_win_get_width(st.win_left)
    assert_true(w_min < w_wider, "dragging left must narrow the left pane")
    assert_true(w_min >= 15, "left pane must keep its minimum width")
    workbench.pane_drag_move(total)
    assert_true(vim.api.nvim_win_get_width(st.win_right) >= 20, "right pane must keep its minimum width")
    workbench.pane_drag_end()
    assert_true(vim.api.nvim_win_is_valid(st.win_left) and vim.api.nvim_win_is_valid(st.win_right),
      "both panes must stay valid through the drag")

    workbench.close()
  end)

  settings.get_settings_file_path = orig_get_path
  settings.reset_cache()
  cleanup_dir(settings_temp_dir)
  cleanup_dir(fixture)
  vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))

  if not ok then
    error(test_err)
  end
end

-- =========================================================================
-- 6. Deterministic Fixture Cleanup Guarantee
-- =========================================================================

function smoke_tests.test_smoke_deterministic_fixture_cleanup()
  -- Create sample test fixtures
  local f1 = create_smoke_project_fixture()
  local f2 = create_smoke_git_fixture()

  assert_true(vim.fn.isdirectory(f1) == 1, "fixture 1 must exist before cleanup")
  assert_true(vim.fn.isdirectory(f2) == 1, "fixture 2 must exist before cleanup")

  -- Clean up all tracked fixtures
  cleanup_all_fixtures()

  assert_true(vim.fn.isdirectory(f1) == 0, "fixture 1 must be deleted after cleanup")
  assert_true(vim.fn.isdirectory(f2) == 0, "fixture 2 must be deleted after cleanup")
end

-- =========================================================================
-- Run all smoke tests with guaranteed teardown
-- =========================================================================

local total = 0
local passed = 0
local failed = 0
local failures = {}

print("=== Running novim-dev Regression Smoke Test Suite ===")

local test_order = {
  "test_smoke_launcher_startup_and_isolated_paths",
  "test_smoke_workbench_two_pane_layout_and_views",
  "test_smoke_source_navigation_editing_and_buffer_preservation",
  "test_smoke_git_diff_rendering_and_read_only_invariance",
  "test_smoke_settings_persistence_dotfile_toggle_and_error_recovery",
  "test_smoke_theme_selection_key_help_and_esc_close",
  "test_smoke_deterministic_fixture_cleanup",
}

for _, name in ipairs(test_order) do
  local fn = smoke_tests[name]
  total = total + 1
  local ok, err = pcall(fn)
  if ok then
    passed = passed + 1
    print("  ✓ PASS: " .. name)
  else
    failed = failed + 1
    table.insert(failures, { name = name, error = err })
    print("  ✗ FAIL: " .. name)
    print("    Error: " .. tostring(err))
  end
end

-- Guarantee all registered fixtures are deleted
cleanup_all_fixtures()

print(string.format("=== Smoke Test Summary: %d total, %d passed, %d failed ===", total, passed, failed))

if failed > 0 then
  vim.cmd("cquit 1")
else
  vim.cmd("qall!")
end
