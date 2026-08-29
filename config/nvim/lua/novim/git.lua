-- novim/git.lua - Pure read-only Git interface for Diff Workbench
-- Part of novim custom derivative

local M = {}

--- Check if git binary is available
---@return boolean
function M.is_git_available()
  return vim.fn.executable("git") == 1
end

--- Run a git command safely and return output lines and exit code
---@param args string[] arguments to git
---@param cwd? string working directory
---@return string[] lines
---@return integer exit_code
---@return string raw_stdout
function M.exec(args, cwd)
  if not M.is_git_available() then
    return { "git executable not found in PATH" }, 127, ""
  end

  local cmd = { "git", "-c", "core.quotepath=false" }
  if cwd and cwd ~= "" then
    table.insert(cmd, "-C")
    table.insert(cmd, cwd)
  end
  for _, arg in ipairs(args) do
    table.insert(cmd, arg)
  end

  local res = vim.system(cmd, { text = true }):wait()
  local stdout = res.stdout or ""
  local lines = {}
  if stdout ~= "" then
    lines = vim.split(stdout, "\n", { plain = true })
    if #lines > 0 and lines[#lines] == "" then
      table.remove(lines, #lines)
    end
  end

  return lines, res.code or 0, stdout
end

--- Check if directory is inside a git repository
---@param cwd? string
---@return boolean is_git
---@return string? repo_root
function M.get_repo_info(cwd)
  local lines, code = M.exec({ "rev-parse", "--is-inside-work-tree", "--show-toplevel" }, cwd)
  if code ~= 0 or #lines == 0 then
    return false, nil
  end

  if lines[1] == "true" and lines[2] and lines[2] ~= "" then
    return true, lines[2]
  elseif lines[1] and lines[1] ~= "true" and lines[1] ~= "false" then
    return true, lines[1]
  end

  -- Fallback check for toplevel
  local top_lines, top_code = M.exec({ "rev-parse", "--show-toplevel" }, cwd)
  if top_code == 0 and #top_lines > 0 and top_lines[1] ~= "" then
    return true, top_lines[1]
  end

  return false, nil
end

--- Check if HEAD commit exists in the repository
---@param cwd? string
---@return boolean has_head
---@return string? head_commit
function M.has_head(cwd)
  local lines, code = M.exec({ "rev-parse", "--verify", "HEAD" }, cwd)
  if code == 0 and #lines > 0 and lines[1] ~= "" then
    return true, lines[1]
  end
  return false, nil
end

---@class ChangedFile
---@field path string relative path (exact bytes preserved)
---@field status string normalized status ("M", "A", "D", "R", "??", "U")
---@field raw_status string raw 2-character porcelain status code
---@field orig_path? string original path if renamed/copied
---@field is_untracked boolean
---@field is_deleted boolean
---@field is_staged boolean

--- Get list of changed and untracked files relative to HEAD
--- Uses NUL-delimited porcelain format (-z) to safely handle all filenames
---@param cwd? string
---@return ChangedFile[] files
---@return { modified: integer, untracked: integer, deleted: integer, added: integer, renamed: integer, total: integer } stats
---@return string? error_msg
function M.get_changed_files(cwd)
  local is_git, repo_root = M.get_repo_info(cwd)
  if not is_git then
    return {}, { modified = 0, untracked = 0, deleted = 0, added = 0, renamed = 0, total = 0 }, "Not a git repository"
  end

  -- Use -z for NUL-delimited safe parsing
  local _, code, raw = M.exec({ "status", "--porcelain=v1", "-z", "-uall" }, repo_root)
  if code ~= 0 then
    return {}, { modified = 0, untracked = 0, deleted = 0, added = 0, renamed = 0, total = 0 }, "Git status failed with code " .. code
  end

  local files = {}
  local stats = { modified = 0, untracked = 0, deleted = 0, added = 0, renamed = 0, total = 0 }

  if not raw or raw == "" then
    return files, stats, nil
  end

  local chunks = vim.split(raw, "\0", { plain = true })
  local idx = 1

  while idx <= #chunks do
    local chunk = chunks[idx]
    if not chunk or chunk == "" then
      break
    end

    if #chunk >= 3 then
      local raw_status = chunk:sub(1, 2)
      local path = chunk:sub(4)
      local orig_path = nil

      local index_char = raw_status:sub(1, 1)
      local worktree_char = raw_status:sub(2, 2)
      local is_rename_or_copy = (index_char == "R" or worktree_char == "R" or index_char == "C" or worktree_char == "C")

      if is_rename_or_copy then
        idx = idx + 1
        if idx <= #chunks and chunks[idx] ~= "" then
          orig_path = chunks[idx]
        end
      end

      local status = "M"
      local is_untracked = false
      local is_deleted = false
      local is_staged = (index_char ~= " " and index_char ~= "?" and index_char ~= "!")

      if raw_status == "??" then
        status = "??"
        is_untracked = true
        stats.untracked = stats.untracked + 1
      elseif index_char == "D" or worktree_char == "D" then
        status = "D"
        is_deleted = true
        stats.deleted = stats.deleted + 1
      elseif index_char == "A" or worktree_char == "A" then
        status = "A"
        stats.added = stats.added + 1
      elseif index_char == "R" or worktree_char == "R" then
        status = "R"
        stats.renamed = stats.renamed + 1
      elseif index_char == "U" or worktree_char == "U" or raw_status == "AA" or raw_status == "DD" then
        status = "U"
        stats.modified = stats.modified + 1
      else
        status = "M"
        stats.modified = stats.modified + 1
      end

      stats.total = stats.total + 1

      table.insert(files, {
        path = path,
        status = status,
        raw_status = raw_status,
        orig_path = orig_path,
        is_untracked = is_untracked,
        is_deleted = is_deleted,
        is_staged = is_staged,
      })
    end

    idx = idx + 1
  end

  return files, stats, nil
end

--- Get diff lines for a specific file relative to HEAD
---@param file ChangedFile
---@param cwd? string
---@return string[] lines
---@return boolean is_binary
function M.get_file_diff(file, cwd)
  local is_git, repo_root = M.get_repo_info(cwd)
  if not is_git then
    return { "# Error: Not a git repository" }, false
  end

  local head_exists = M.has_head(repo_root)

  if file.is_untracked then
    -- Untracked file: show all-additions diff using --no-index against /dev/null
    local out, _ = M.exec({ "diff", "--no-index", "--", "/dev/null", file.path }, repo_root)
    if #out == 0 then
      -- Empty file or unreadable
      local abs_path = repo_root .. "/" .. file.path
      local f = io.open(abs_path, "r")
      if f then
        local content = f:read("*a")
        f:close()
        if content == "" then
          return {
            "diff --git a/" .. file.path .. " b/" .. file.path,
            "new file mode (empty)",
            "--- /dev/null",
            "+++ b/" .. file.path,
            "@@ -0,0 +0,0 @@",
            "# (Empty untracked file)",
          }, false
        end
      end
    end

    -- Check if binary
    for _, l in ipairs(out) do
      if l:match("^Binary files ") or l:match("^GIT binary patch") then
        return out, true
      end
    end
    return out, false
  end

  -- Tracked file (modified, deleted, added, renamed)
  local diff_args = { "diff" }
  if head_exists then
    table.insert(diff_args, "HEAD")
  else
    table.insert(diff_args, "4b825dc642cb6eb9a060e54bf8d69288fbee4904")
  end
  table.insert(diff_args, "--")
  table.insert(diff_args, file.path)

  local out, code = M.exec(diff_args, repo_root)

  -- If empty output but file is added/staged without HEAD
  if #out == 0 and not head_exists then
    out, _ = M.exec({ "diff", "--staged", "--", file.path }, repo_root)
  end

  if #out == 0 then
    if file.is_deleted then
      return {
        "diff --git a/" .. file.path .. " b/" .. file.path,
        "deleted file",
        "--- a/" .. file.path,
        "+++ /dev/null",
        "# (File deleted)",
      }, false
    else
      return {
        "diff --git a/" .. file.path .. " b/" .. file.path,
        "# No textual differences against HEAD",
      }, false
    end
  end

  -- Check if binary
  for _, l in ipairs(out) do
    if l:match("^Binary files ") or l:match("^GIT binary patch") then
      return out, true
    end
  end

  return out, false
end

return M
