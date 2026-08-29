-- novim/settings.lua - Persistent local settings for novim custom derivative
-- Part of novim custom derivative

local themes = require("novim.themes")

local M = {}

-- Default settings
local DEFAULTS = {
  show_dotfiles = false,
  theme = themes.default_id,
}

-- In-memory cache of current settings
local current_settings = nil

--- Get the persistent settings file path under Neovim isolated state path
---@return string path
function M.get_settings_file_path()
  local state_dir = vim.fn.stdpath("state")
  if not state_dir or state_dir == "" then
    state_dir = os.getenv("XDG_STATE_HOME") or (vim.fn.stdpath("data") .. "/state")
  end
  return state_dir .. "/novim_settings.json"
end

--- Safely load settings from persistent storage.
--- If the file is missing, empty, or contains malformed JSON,
--- safely returns default settings without throwing errors.
---@param force_reload? boolean
---@return { show_dotfiles: boolean } settings
function M.load(force_reload)
  if current_settings and not force_reload then
    return vim.deepcopy(current_settings)
  end

  local settings = vim.deepcopy(DEFAULTS)
  local path = M.get_settings_file_path()

  if vim.fn.filereadable(path) == 1 then
    local ok, content = pcall(function()
      local f = io.open(path, "r")
      if not f then return nil end
      local text = f:read("*a")
      f:close()
      return text
    end)

    if ok and content and content ~= "" then
      local decode_ok, decoded = pcall(vim.json.decode, content)
      if decode_ok and type(decoded) == "table" then
        if type(decoded.show_dotfiles) == "boolean" then
          settings.show_dotfiles = decoded.show_dotfiles
        end
        if type(decoded.theme) == "string" and themes.is_valid(decoded.theme) then
          settings.theme = decoded.theme
        end
      end
    end
  end

  current_settings = vim.deepcopy(settings)
  return settings
end

--- Safely save settings to persistent storage.
--- Returns success flag and optional error message.
---@param new_settings table
---@return boolean success
---@return string? error_msg
function M.save(new_settings)
  if type(new_settings) ~= "table" then
    return false, "Invalid settings table"
  end

  local path = M.get_settings_file_path()
  local dir = vim.fs.dirname(path) or vim.fn.fnamemodify(path, ":h")

  if vim.fn.isdirectory(dir) == 0 then
    local mkdir_ok, mkdir_err = pcall(vim.fn.mkdir, dir, "p")
    if not mkdir_ok then
      return false, "Failed to create settings directory: " .. tostring(mkdir_err)
    end
  end

  local settings_to_save = vim.deepcopy(current_settings or DEFAULTS)
  if type(new_settings.show_dotfiles) == "boolean" then
    settings_to_save.show_dotfiles = new_settings.show_dotfiles
  end
  if type(new_settings.theme) == "string" and themes.is_valid(new_settings.theme) then
    settings_to_save.theme = new_settings.theme
  end

  local encode_ok, json_str = pcall(vim.json.encode, settings_to_save)
  if not encode_ok or not json_str then
    return false, "Failed to encode settings to JSON"
  end

  local write_ok, write_err = pcall(function()
    local f = io.open(path, "w")
    if not f then
      error("Cannot open " .. path .. " for writing")
    end
    f:write(json_str .. "\n")
    f:close()
  end)

  if not write_ok then
    return false, "Failed to write settings file: " .. tostring(write_err)
  end

  current_settings = vim.deepcopy(settings_to_save)
  return true, nil
end

--- Get a specific setting value
---@param key string
---@return any
function M.get(key)
  local s = M.load()
  return s[key]
end

--- Get all current settings
---@return table
function M.get_all()
  return M.load()
end

--- Set a specific setting value and save it.
--- Theme values are validated against the built-in catalog before persisting.
---@param key string
---@param value any
---@return boolean success
---@return string? error_msg
function M.set(key, value)
  if key == "theme" and (type(value) ~= "string" or not themes.is_valid(value)) then
    return false, "Invalid theme: " .. tostring(value)
  end
  local s = M.load()
  s[key] = value
  return M.save(s)
end

--- Toggle dotfiles visibility setting and save immediately.
--- Returns success flag, optional error message, and effective boolean value.
--- If save fails, the in-memory setting is NOT updated and the previous value is retained.
---@return boolean success
---@return string? error_msg
---@return boolean effective_value
function M.toggle_dotfiles()
  local cur = M.get("show_dotfiles")
  local target = not cur
  local ok, err = M.set("show_dotfiles", target)
  if not ok then
    return false, err, cur
  end
  return true, nil, target
end

--- Reset in-memory cache (for testing)
function M.reset_cache()
  current_settings = nil
end

return M
