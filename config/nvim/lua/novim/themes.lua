-- novim/themes.lua - Application-owned built-in palettes for novim custom derivative
-- Part of novim custom derivative
--
-- Six built-in themes rendered from fixed application-owned palettes.
-- No plugin manager, third-party runtime dependency, or network action is
-- involved: every color below ships with the bundled configuration.

local M = {}

--- Default theme identifier (Tokyo Night)
M.default_id = "tokyo_night"

--- Normalized palette slot schema (all values are hex strings):
---   bg / bg_float / bg_highlight / bg_popup / bg_search / bg_statusline /
---   bg_visual / bg_tab_active  background surfaces
---   fg / fg_dark         primary and dimmed foreground
---   fg_gutter            line-number / gutter foreground
---   comment              comments, subheaders, inactive elements
---   dark3                very dim UI text (NonText, SpecialKey)
---   primary              main accent (headers, active tab, key hints)
---   primary_border       floating window border accent
---   bright               bright alternative accent (types, specials)
---   operator             operator-class accent
---   secondary            muted summary foreground
---   success / warn / accent / error / error_deep
---   purple / cyan        additional syntax accents
---   border               vertical split / window separator
---   diff_add_bg / diff_change_bg / diff_delete_bg / diff_text_bg
---   changed_line_bg      inserted-line background tint

local palettes = {
  tokyo_night = {
    id = "tokyo_night",
    label = "Tokyo Night",
    dark = true,
    bg = "#1a1b26",
    bg_float = "#16161e",
    bg_highlight = "#292e42",
    bg_popup = "#16161e",
    bg_search = "#3d59a1",
    bg_statusline = "#16161e",
    bg_visual = "#283457",
    bg_tab_active = "#24283b",
    fg = "#c0caf5",
    fg_dark = "#a9b1d6",
    fg_gutter = "#3b4261",
    comment = "#565f89",
    dark3 = "#545c7e",
    primary = "#7aa2f7",
    primary_border = "#3d59a1",
    bright = "#2ac3de",
    operator = "#89ddff",
    secondary = "#9aa5ce",
    success = "#9ece6a",
    warn = "#e0af68",
    accent = "#ff9e64",
    error = "#f7768e",
    error_deep = "#db4b4b",
    purple = "#bb9af7",
    cyan = "#7dcfff",
    border = "#414868",
    diff_add_bg = "#20303b",
    diff_change_bg = "#1f2231",
    diff_delete_bg = "#37222c",
    diff_text_bg = "#394b70",
    changed_line_bg = "#1e3a2a",
  },
  nord = {
    id = "nord",
    label = "Nord",
    dark = true,
    bg = "#2e3440",
    bg_float = "#2e3440",
    bg_highlight = "#3b4252",
    bg_popup = "#3b4252",
    bg_search = "#434c5e",
    bg_statusline = "#3b4252",
    bg_visual = "#434c5e",
    bg_tab_active = "#3b4252",
    fg = "#d8dee9",
    fg_dark = "#e5e9f0",
    fg_gutter = "#4c566a",
    comment = "#616e88",
    dark3 = "#4c566a",
    primary = "#88c0d0",
    primary_border = "#5e81ac",
    bright = "#8fbcbb",
    operator = "#81a1c1",
    secondary = "#eceff4",
    success = "#a3be8c",
    warn = "#ebcb8b",
    accent = "#d08770",
    error = "#bf616a",
    error_deep = "#bf616a",
    purple = "#b48ead",
    cyan = "#8fbcbb",
    border = "#4c566a",
    diff_add_bg = "#39483e",
    diff_change_bg = "#3b4252",
    diff_delete_bg = "#46353a",
    diff_text_bg = "#434c5e",
    changed_line_bg = "#39483e",
  },
  gruvbox_dark = {
    id = "gruvbox_dark",
    label = "Gruvbox Dark",
    dark = true,
    bg = "#282828",
    bg_float = "#1d2021",
    bg_highlight = "#3c3836",
    bg_popup = "#3c3836",
    bg_search = "#504945",
    bg_statusline = "#32302f",
    bg_visual = "#504945",
    bg_tab_active = "#3c3836",
    fg = "#ebdbb2",
    fg_dark = "#bdae93",
    fg_gutter = "#665c54",
    comment = "#928374",
    dark3 = "#7c6f64",
    primary = "#83a598",
    primary_border = "#458588",
    bright = "#8ec07c",
    operator = "#8ec07c",
    secondary = "#a89984",
    success = "#b8bb26",
    warn = "#fabd2f",
    accent = "#fe8019",
    error = "#fb4934",
    error_deep = "#cc241d",
    purple = "#d3869b",
    cyan = "#8ec07c",
    border = "#665c54",
    diff_add_bg = "#3a432e",
    diff_change_bg = "#45403d",
    diff_delete_bg = "#473131",
    diff_text_bg = "#504945",
    changed_line_bg = "#3a432e",
  },
  catppuccin_mocha = {
    id = "catppuccin_mocha",
    label = "Catppuccin Mocha",
    dark = true,
    bg = "#1e1e2e",
    bg_float = "#181825",
    bg_highlight = "#313244",
    bg_popup = "#313244",
    bg_search = "#45475a",
    bg_statusline = "#181825",
    bg_visual = "#45475a",
    bg_tab_active = "#313244",
    fg = "#cdd6f4",
    fg_dark = "#a6adc8",
    fg_gutter = "#45475a",
    comment = "#6c7086",
    dark3 = "#7f849c",
    primary = "#89b4fa",
    primary_border = "#585b70",
    bright = "#94e2d5",
    operator = "#89dceb",
    secondary = "#bac2de",
    success = "#a6e3a1",
    warn = "#f9e2af",
    accent = "#fab387",
    error = "#f38ba8",
    error_deep = "#eba0ac",
    purple = "#cba6f7",
    cyan = "#89dceb",
    border = "#45475a",
    diff_add_bg = "#313d35",
    diff_change_bg = "#313244",
    diff_delete_bg = "#45343c",
    diff_text_bg = "#45475a",
    changed_line_bg = "#313d35",
  },
  one_dark = {
    id = "one_dark",
    label = "One Dark",
    dark = true,
    bg = "#282c34",
    bg_float = "#21252b",
    bg_highlight = "#3e4451",
    bg_popup = "#21252b",
    bg_search = "#3e4451",
    bg_statusline = "#21252b",
    bg_visual = "#3e4451",
    bg_tab_active = "#3e4451",
    fg = "#abb2bf",
    fg_dark = "#9da5b4",
    fg_gutter = "#4b5263",
    comment = "#5c6370",
    dark3 = "#4b5263",
    primary = "#61afef",
    primary_border = "#4b5263",
    bright = "#56b6c2",
    operator = "#56b6c2",
    secondary = "#828997",
    success = "#98c379",
    warn = "#e5c07b",
    accent = "#d19a66",
    error = "#e06c75",
    error_deep = "#be5046",
    purple = "#c678dd",
    cyan = "#56b6c2",
    border = "#5c6370",
    diff_add_bg = "#2e3a30",
    diff_change_bg = "#2f3a4a",
    diff_delete_bg = "#403035",
    diff_text_bg = "#3e4451",
    changed_line_bg = "#2e3a30",
  },
  solarized_light = {
    id = "solarized_light",
    label = "Solarized Light",
    dark = false,
    bg = "#fdf6e3",
    bg_float = "#eee8d5",
    bg_highlight = "#eee8d5",
    bg_popup = "#eee8d5",
    bg_search = "#e8e1ca",
    bg_statusline = "#eee8d5",
    bg_visual = "#eee8d5",
    bg_tab_active = "#e3dcc9",
    fg = "#586e75",
    fg_dark = "#657b83",
    fg_gutter = "#93a1a1",
    comment = "#93a1a1",
    dark3 = "#93a1a1",
    primary = "#268bd2",
    primary_border = "#93a1a1",
    bright = "#2aa198",
    operator = "#2aa198",
    secondary = "#839496",
    success = "#859900",
    warn = "#b58900",
    accent = "#cb4b16",
    error = "#dc322f",
    error_deep = "#cb4b16",
    purple = "#d33682",
    cyan = "#2aa198",
    border = "#93a1a1",
    diff_add_bg = "#e9eddb",
    diff_change_bg = "#ece7d4",
    diff_delete_bg = "#f2dfdc",
    diff_text_bg = "#e0d9c4",
    changed_line_bg = "#e9eddb",
  },
}

--- Canonical theme order (exactly six built-in themes)
local theme_order = {
  "tokyo_night",
  "nord",
  "gruvbox_dark",
  "catppuccin_mocha",
  "one_dark",
  "solarized_light",
}

--- List built-in themes in canonical order.
---@return { id: string, label: string, dark: boolean }[]
function M.list()
  local out = {}
  for _, id in ipairs(theme_order) do
    local p = palettes[id]
    table.insert(out, { id = p.id, label = p.label, dark = p.dark })
  end
  return out
end

--- Check whether a theme identifier is one of the built-in themes.
---@param id any
---@return boolean
function M.is_valid(id)
  return type(id) == "string" and palettes[id] ~= nil
end

--- Resolve a palette by id, falling back to the default theme for
--- missing or invalid identifiers (never errors).
---@param id? string
---@return table palette
function M.get(id)
  return palettes[id] or palettes[M.default_id]
end

--- Apply a built-in palette to the editor and workbench highlight groups.
--- Unknown ids fall back to Tokyo Night. Returns the applied palette.
---@param id? string
---@return table palette
function M.apply(id)
  local t = M.get(id)

  vim.o.background = t.dark and "dark" or "light"
  vim.g.colors_name = t.id

  local function hl(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- Editor surfaces
  hl("Normal", { fg = t.fg, bg = t.bg })
  hl("NormalFloat", { fg = t.fg, bg = t.bg_float })
  hl("Cursor", { fg = t.bg, bg = t.fg })
  hl("CursorLine", { bg = t.bg_highlight })
  hl("CursorLineNr", { fg = t.warn, bold = true })
  hl("LineNr", { fg = t.fg_gutter })
  hl("SignColumn", { fg = t.fg_gutter, bg = t.bg })
  hl("VertSplit", { fg = t.border })
  hl("WinSeparator", { fg = t.border })
  hl("StatusLine", { fg = t.fg_dark, bg = t.bg_statusline })
  hl("StatusLineNC", { fg = t.comment, bg = t.bg_statusline })
  hl("Pmenu", { fg = t.fg, bg = t.bg_popup })
  hl("PmenuSel", { bg = t.bg_highlight })
  hl("Visual", { bg = t.bg_visual })
  hl("Search", { fg = t.fg, bg = t.bg_search })
  hl("IncSearch", { fg = t.bg, bg = t.accent })
  hl("MatchParen", { fg = t.accent, bold = true })
  hl("NonText", { fg = t.dark3 })
  hl("SpecialKey", { fg = t.dark3 })
  hl("Directory", { fg = t.primary })
  hl("Title", { fg = t.primary, bold = true })
  hl("ErrorMsg", { fg = t.error })
  hl("WarningMsg", { fg = t.warn })
  hl("MoreMsg", { fg = t.primary })
  hl("Question", { fg = t.primary })
  hl("Folded", { fg = t.comment, bg = t.bg_highlight })
  hl("FoldColumn", { fg = t.comment, bg = t.bg })
  hl("DiffAdd", { bg = t.diff_add_bg })
  hl("DiffChange", { bg = t.diff_change_bg })
  hl("DiffDelete", { fg = t.error_deep, bg = t.diff_delete_bg })
  hl("DiffText", { bg = t.diff_text_bg })
  hl("FloatBorder", { fg = t.primary_border, bg = t.bg_float })

  -- Diff syntax
  hl("diffAdded", { fg = t.success })
  hl("diffRemoved", { fg = t.error_deep })
  hl("diffChanged", { fg = t.primary })
  hl("diffFile", { fg = t.primary, bold = true })
  hl("diffNewFile", { fg = t.success, bold = true })
  hl("diffOldFile", { fg = t.error, bold = true })
  hl("diffLine", { fg = t.purple })
  hl("diffIndexLine", { fg = t.comment })
  hl("diffSubname", { fg = t.secondary })

  -- Syntax
  hl("Comment", { fg = t.comment, italic = true })
  hl("Constant", { fg = t.accent })
  hl("String", { fg = t.success })
  hl("Character", { fg = t.success })
  hl("Number", { fg = t.accent })
  hl("Boolean", { fg = t.accent })
  hl("Float", { fg = t.accent })
  hl("Identifier", { fg = t.purple })
  hl("Function", { fg = t.primary })
  hl("Statement", { fg = t.purple })
  hl("Conditional", { fg = t.purple })
  hl("Repeat", { fg = t.purple })
  hl("Label", { fg = t.primary })
  hl("Operator", { fg = t.operator })
  hl("Keyword", { fg = t.purple, italic = true })
  hl("Exception", { fg = t.purple })
  hl("PreProc", { fg = t.cyan })
  hl("Include", { fg = t.primary })
  hl("Define", { fg = t.purple })
  hl("Macro", { fg = t.purple })
  hl("PreCondit", { fg = t.cyan })
  hl("Type", { fg = t.bright })
  hl("StorageClass", { fg = t.primary })
  hl("Structure", { fg = t.primary })
  hl("Typedef", { fg = t.primary })
  hl("Special", { fg = t.bright })
  hl("SpecialChar", { fg = t.bright })
  hl("Tag", { fg = t.primary })
  hl("Delimiter", { fg = t.fg })
  hl("SpecialComment", { fg = t.comment })
  hl("Debug", { fg = t.accent })
  hl("Underlined", { underline = true })
  hl("Error", { fg = t.error })
  hl("Todo", { fg = t.bg, bg = t.warn, bold = true })

  -- netrw (file tree)
  hl("netrwDir", { fg = t.primary })
  hl("netrwClassify", { fg = t.primary })
  hl("netrwLink", { fg = t.purple })
  hl("netrwSymLink", { fg = t.cyan })
  hl("netrwExe", { fg = t.success })
  hl("netrwComment", { fg = t.comment })
  hl("netrwList", { fg = t.primary })
  hl("netrwTreeBar", { fg = t.fg_gutter })

  -- Inserted-line tracking and gitsigns
  hl("ChangedLine", { bg = t.changed_line_bg })
  hl("GitSignsAdd", { fg = t.success })
  hl("GitSignsChange", { fg = t.primary })
  hl("GitSignsDelete", { fg = t.error })

  -- Workbench UI highlights
  hl("WorkbenchHeader", { fg = t.primary, bold = true })
  hl("WorkbenchSubHeader", { fg = t.comment, italic = true })
  hl("WorkbenchDivider", { fg = t.bg_highlight })
  hl("WorkbenchSummary", { fg = t.secondary })
  hl("WorkbenchClean", { fg = t.success, bold = true })
  hl("WorkbenchError", { fg = t.error, bold = true })

  hl("WorkbenchTabActive", { fg = t.primary, bg = t.bg_tab_active, bold = true })
  hl("WorkbenchTabInactive", { fg = t.comment, bg = t.bg })
  hl("WorkbenchTabAction", { fg = t.warn })

  hl("WorkbenchStatusM", { fg = t.warn, bold = true })
  hl("WorkbenchStatusA", { fg = t.success, bold = true })
  hl("WorkbenchStatusU", { fg = t.cyan, bold = true })
  hl("WorkbenchStatusD", { fg = t.error, bold = true })
  hl("WorkbenchStatusR", { fg = t.purple, bold = true })

  hl("WorkbenchBrowserDir", { fg = t.primary, bold = true })
  hl("WorkbenchBrowserFile", { fg = t.fg })
  hl("WorkbenchBrowserDot", { fg = t.comment, italic = true })

  hl("WorkbenchPath", { fg = t.fg })
  hl("WorkbenchActiveMarker", { fg = t.primary, bold = true })
  hl("WorkbenchKeyHint", { fg = t.primary })

  return t
end

return M
