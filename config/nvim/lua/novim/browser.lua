-- novim/browser.lua - Read-Only Project File Browser
-- Part of novim custom derivative

local uv = vim.uv or vim.loop

local M = {}

---@class ProjectEntry
---@field path string relative path from project root
---@field name string basename of entry
---@field is_dir boolean
---@field depth integer 0-indexed nesting depth
---@field is_dot boolean whether name starts with '.'
---@field size? integer file size in bytes
---@field full_path string absolute path to file
---@field child_count? integer number of immediate children if directory

--- Check if a buffer/content is binary
---@param sample string
---@return boolean
local function is_binary_content(sample)
  if not sample or sample == "" then return false end
  return sample:find("\0") ~= nil
end

--- Scan a single directory and return immediate entries
---@param dir_path string
---@return { name: string, type: string }[]
local function scan_dir_entries(dir_path)
  local entries = {}
  local handle, err = uv.fs_scandir(dir_path)
  if not handle then
    -- Directory unreadable or error
    return entries
  end

  while true do
    local name, type_str = uv.fs_scandir_next(handle)
    if not name then break end
    table.insert(entries, { name = name, type = type_str or "unknown" })
  end

  return entries
end

--- Recursively scan project files and directories from root
---@param root_dir? string
---@param show_dotfiles? boolean
---@param max_depth? integer
---@return ProjectEntry[] entries
---@return { file_count: integer, dir_count: integer, dot_count: integer } stats
function M.get_tree(root_dir, show_dotfiles, max_depth)
  root_dir = root_dir or vim.fn.getcwd()
  show_dotfiles = (show_dotfiles == true)
  max_depth = max_depth or 15

  local result = {}
  local stats = { file_count = 0, dir_count = 0, dot_count = 0 }
  local visited_dirs = {}

  local function walk(current_abs_dir, rel_prefix, depth)
    if depth > max_depth then return end

    -- Avoid symlink cycles
    local real_dir = uv.fs_realpath(current_abs_dir) or current_abs_dir
    if visited_dirs[real_dir] then return end
    visited_dirs[real_dir] = true

    local raw_entries = scan_dir_entries(current_abs_dir)

    -- Separate into directories and files, applying dotfile filtering
    local dirs = {}
    local files = {}

    for _, item in ipairs(raw_entries) do
      local name = item.name
      local is_dot = (name:sub(1, 1) == ".")

      if is_dot then
        stats.dot_count = stats.dot_count + 1
      end

      -- If dotfiles are hidden, skip any entry whose name starts with '.'
      if show_dotfiles or not is_dot then
        local item_rel_path = (rel_prefix == "") and name or (rel_prefix .. "/" .. name)
        local item_full_path = current_abs_dir .. "/" .. name

        -- Determine if directory
        local is_dir = (item.type == "directory")
        if item.type == "link" or item.type == "unknown" then
          local st = uv.fs_stat(item_full_path)
          if st and st.type == "directory" then
            is_dir = true
          end
        end

        local entry = {
          path = item_rel_path,
          name = name,
          is_dir = is_dir,
          depth = depth,
          is_dot = is_dot,
          full_path = item_full_path,
        }

        if is_dir then
          table.insert(dirs, entry)
        else
          table.insert(files, entry)
        end
      end
    end

    -- Sort directories alphabetically (case-insensitive)
    table.sort(dirs, function(a, b)
      return a.name:lower() < b.name:lower()
    end)

    -- Sort files alphabetically (case-insensitive)
    table.sort(files, function(a, b)
      return a.name:lower() < b.name:lower()
    end)

    -- Add directories and recursively traverse them
    for _, dir_entry in ipairs(dirs) do
      stats.dir_count = stats.dir_count + 1
      table.insert(result, dir_entry)

      -- Recursively walk subdirectory
      walk(dir_entry.full_path, dir_entry.path, depth + 1)
    end

    -- Add files
    for _, file_entry in ipairs(files) do
      stats.file_count = stats.file_count + 1
      local st = uv.fs_stat(file_entry.full_path)
      if st then
        file_entry.size = st.size
      end
      table.insert(result, file_entry)
    end
  end

  walk(root_dir, "", 0)
  return result, stats
end

--- Format file size in human-readable string
---@param bytes? integer
---@return string
function M.format_size(bytes)
  if not bytes or bytes < 0 then return "0 B" end
  if bytes < 1024 then
    return string.format("%d B", bytes)
  elseif bytes < 1024 * 1024 then
    return string.format("%.1f KB (%d bytes)", bytes / 1024, bytes)
  else
    return string.format("%.2f MB (%d bytes)", bytes / (1024 * 1024), bytes)
  end
end

--- Generate read-only preview lines for a selected project entry
---@param entry? ProjectEntry
---@param root_dir? string
---@return string[] lines
---@return boolean is_text_preview
function M.get_preview(entry, root_dir)
  root_dir = root_dir or vim.fn.getcwd()

  if not entry then
    return {
      "# ===================================================================",
      "# Project File Browser (Read-Only)",
      "# ===================================================================",
      "#",
      "# No file or directory selected.",
      "#",
      "# Navigation:",
      "#   [j] / [k] or [↑] / [↓]  Select project files and folders",
      "#   [s]                     Open Settings (toggle dot-folders)",
      "#   [r]                     Refresh project listing",
      "#   [2] or [d]              Switch to Git Diff workbench",
      "#   [?]                     Show full help",
      "#   [q] or [Esc Esc]        Close browser",
    }, false
  end

  if entry.is_dir then
    -- Directory inspection
    local child_entries = scan_dir_entries(entry.full_path)
    local lines = {
      "# ===================================================================",
      "# Directory: " .. entry.path .. "/",
      "# ===================================================================",
      "# Relative Path: " .. entry.path .. "/",
      "# Full Path:     " .. entry.full_path,
      "# Type:          Directory" .. (entry.is_dot and " (Dot-Folder / Hidden by default)" or ""),
      "# Depth:         " .. entry.depth,
      "# Direct Items:  " .. #child_entries .. " item(s)",
      "# ───────────────────────────────────────────────────────────────────",
      "# Contents:",
    }

    if #child_entries == 0 then
      table.insert(lines, "#   (Empty directory)")
    else
      local sorted_children = vim.deepcopy(child_entries)
      table.sort(sorted_children, function(a, b)
        if (a.type == "directory") ~= (b.type == "directory") then
          return a.type == "directory"
        end
        return a.name:lower() < b.name:lower()
      end)

      for i, child in ipairs(sorted_children) do
        if i > 50 then
          table.insert(lines, string.format("#   ... and %d more items", #sorted_children - 50))
          break
        end
        local prefix = (child.type == "directory") and "📁 " or "📄 "
        table.insert(lines, string.format("#   %s%s%s", prefix, child.name, (child.type == "directory") and "/" or ""))
      end
    end

    table.insert(lines, "# ───────────────────────────────────────────────────────────────────")
    table.insert(lines, "# Press [s] to toggle dot-folder visibility in Settings.")
    return lines, false
  end

  -- File inspection
  local st = uv.fs_stat(entry.full_path)
  local size = (st and st.size) or entry.size or 0
  local size_str = M.format_size(size)

  local header = {
    "# ===================================================================",
    "# File: " .. entry.path,
    "# ===================================================================",
    "# Relative Path: " .. entry.path,
    "# Full Path:     " .. entry.full_path,
    "# Type:          Regular File" .. (entry.is_dot and " (Dot-File / Hidden by default)" or ""),
    "# Size:          " .. size_str,
    "# ───────────────────────────────────────────────────────────────────",
    "# File Content Preview (Read-Only):",
    "# ───────────────────────────────────────────────────────────────────",
  }

  -- If file size is 0
  if size == 0 then
    local lines = vim.deepcopy(header)
    table.insert(lines, "# (Empty file)")
    return lines, false
  end

  -- Read file safely
  local f, err = io.open(entry.full_path, "rb")
  if not f then
    local lines = vim.deepcopy(header)
    table.insert(lines, "# [Unable to read file: " .. tostring(err) .. "]")
    return lines, false
  end

  local sample = f:read(8192) or ""
  if is_binary_content(sample) then
    f:close()
    local lines = vim.deepcopy(header)
    table.insert(lines, "# [Binary file - content preview suppressed in text inspector]")
    table.insert(lines, "# Size: " .. size_str)
    return lines, false
  end

  -- Read text lines up to 500 lines
  f:seek("set", 0)
  local preview_lines = vim.deepcopy(header)
  local line_idx = 1
  for line in f:lines() do
    if line_idx > 500 then
      table.insert(preview_lines, string.format("# ... [Preview capped at 500 lines. Total size: %s]", size_str))
      break
    end
    table.insert(preview_lines, string.format("%4d │ %s", line_idx, line))
    line_idx = line_idx + 1
  end
  f:close()

  return preview_lines, true
end

return M
