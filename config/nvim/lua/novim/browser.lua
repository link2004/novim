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

--- Scan only the immediate visible entries of one directory (lazy model).
--- Directories are listed before files; both groups sort case-insensitively.
--- Dotfile filtering applies at every level; callers decide when to scan a
--- directory, so no traversal happens unless a parent folder was expanded.
---@param dir_path string absolute directory to scan
---@param rel_prefix string relative path prefix from project root ("" at root)
---@param depth integer 0-indexed nesting depth of the returned entries
---@param show_dotfiles boolean whether dot-prefixed entries are visible
---@return ProjectEntry[] entries
function M.get_immediate_entries(dir_path, rel_prefix, depth, show_dotfiles)
  show_dotfiles = (show_dotfiles == true)

  local raw_entries = scan_dir_entries(dir_path)

  local dirs = {}
  local files = {}

  for _, item in ipairs(raw_entries) do
    local name = item.name
    local is_dot = (name:sub(1, 1) == ".")

    -- If dotfiles are hidden, skip any entry whose name starts with '.'
    if show_dotfiles or not is_dot then
      local item_rel_path = (rel_prefix == "") and name or (rel_prefix .. "/" .. name)
      local item_full_path = dir_path .. "/" .. name

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
        local st = uv.fs_stat(item_full_path)
        if st then
          entry.size = st.size
        end
        table.insert(files, entry)
      end
    end
  end

  -- Sort directories and files alphabetically (case-insensitive)
  table.sort(dirs, function(a, b)
    return a.name:lower() < b.name:lower()
  end)
  table.sort(files, function(a, b)
    return a.name:lower() < b.name:lower()
  end)

  local result = {}
  for _, dir_entry in ipairs(dirs) do
    table.insert(result, dir_entry)
  end
  for _, file_entry in ipairs(files) do
    table.insert(result, file_entry)
  end
  return result
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
---@param show_dotfiles? boolean
---@return string[] lines
---@return boolean is_text_preview
function M.get_preview(entry, root_dir, show_dotfiles)
  root_dir = root_dir or vim.fn.getcwd()
  if show_dotfiles == nil then
    local s_ok, settings = pcall(require, "novim.settings")
    if s_ok and settings then
      show_dotfiles = settings.get("show_dotfiles") == true
    else
      show_dotfiles = false
    end
  else
    show_dotfiles = (show_dotfiles == true)
  end

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
    local raw_children = scan_dir_entries(entry.full_path)
    local child_entries = {}
    local hidden_dot_count = 0

    for _, child in ipairs(raw_children) do
      local is_dot = (child.name:sub(1, 1) == ".")
      if is_dot and not show_dotfiles then
        hidden_dot_count = hidden_dot_count + 1
      else
        table.insert(child_entries, child)
      end
    end

    local items_summary = #child_entries .. " item(s)"
    if hidden_dot_count > 0 then
      items_summary = items_summary .. string.format(" (%d dot-item%s hidden)", hidden_dot_count, hidden_dot_count > 1 and "s" or "")
    end

    local lines = {
      "# ===================================================================",
      "# Directory: " .. entry.path .. "/",
      "# ===================================================================",
      "# Relative Path: " .. entry.path .. "/",
      "# Full Path:     " .. entry.full_path,
      "# Type:          Directory" .. (entry.is_dot and " (Dot-Folder / Hidden by default)" or ""),
      "# Depth:         " .. entry.depth,
      "# Direct Items:  " .. items_summary,
      "# ───────────────────────────────────────────────────────────────────",
      "# Contents:",
    }

    if #child_entries == 0 then
      if hidden_dot_count > 0 then
        table.insert(lines, "#   (No visible items; " .. hidden_dot_count .. " dot-item(s) hidden. Press 's' to show.)")
      else
        table.insert(lines, "#   (Empty directory)")
      end
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
