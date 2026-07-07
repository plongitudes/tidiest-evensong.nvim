local Text = require("evensong.text")
local config = require("evensong.config")
local registry = require("evensong.registry")
local platform_mod = require("evensong.platform")
local util = require("evensong.util")

local M = {}

-- Row-to-data mapping for cursor navigation
-- Each entry: { type = "category"|"setting"|"header"|"blank", key = string?, category = string? }
M.locations = {}

-- Width of the label column, so every setting's value/slider starts at the same x.
-- Computed once from the widest display_name across the registry (+ a small gap).
local NAME_GAP = 2
local name_col_cache = nil
local function name_col()
  if not name_col_cache then
    local maxw = 0
    for _, s in ipairs(registry.settings) do
      local w = vim.fn.strdisplaywidth(s.display_name)
      if w > maxw then
        maxw = w
      end
    end
    name_col_cache = maxw + NAME_GAP
  end
  return name_col_cache
end

-- Spaces needed to pad `name` out to the label column.
local function name_pad(name)
  return string.rep(" ", math.max(name_col() - vim.fn.strdisplaywidth(name), 1))
end

function M.build(state, buf)
  local text = Text.new()
  M.locations = {}

  if state.mode == "settings" then
    M._header(text, state)
    M._settings(text, state)
  elseif state.mode == "profiles" then
    M._header(text, state)
    M._profiles(text, state)
  elseif state.mode == "help" then
    M._header(text, state)
    M._help(text)
  end

  text:render(buf)
  return M.locations
end

function M._header(text, state)
  local cfg = config.get()
  local icons = cfg.icons

  -- Title line
  text:append("  ", "EvensongNormal")
  text:append(" Neovide ", "EvensongH1")
  text:append("  ", "EvensongNormal")
  M._push_loc("header")
  text:nl()

  -- Mode pills
  text:append("  ", "EvensongNormal")
  local keys = cfg.keys
  local modes = {
    { key = "settings", icon = icons.settings, label = "Settings" },
    { key = "profiles", icon = icons.profiles, label = "Profiles", hotkey = keys.profiles_view },
    { key = "help", icon = icons.help, label = "Help", hotkey = keys.help_view },
  }
  for i, mode in ipairs(modes) do
    local active = state.mode == mode.key
    local hl = active and "EvensongButtonActive" or "EvensongButton"
    if not active and mode.hotkey then
      text:append(" " .. mode.hotkey .. " ", "EvensongKey")
    end
    text:append(" " .. mode.icon .. mode.label .. " ", hl)
    if i < #modes then
      text:append(" ", "EvensongNormal")
    end
  end

  -- Dirty count
  if state:has_dirty() then
    text:append("  ", "EvensongNormal")
    text:append(" " .. icons.modified .. state:dirty_count() .. " modified ", "EvensongBadgeModified")
  end

  M._push_loc("header")
  text:nl()
  text:nl()
  M._push_loc("blank")
end

function M._settings(text, state)
  local cfg = config.get()
  local icons = cfg.icons

  for _, cat_name in ipairs(registry.categories()) do
    local settings = registry.get_by_category(cat_name)
    local expanded = state.categories_expanded[cat_name]

    -- Category header
    local icon = expanded and icons.expanded or icons.collapsed
    local cat_icon = icons.category[cat_name] or "  "
    text:append("  ", "EvensongNormal")
    text:append(icon, "EvensongCategoryIcon")
    text:append(cat_icon, "EvensongCategoryIcon")
    text:append(cat_name, "EvensongCategory")
    text:append(" (" .. #settings .. ")", "EvensongDimmed")
    M._push_loc("category", nil, cat_name)
    text:nl()

    if expanded then
      for _, setting in ipairs(settings) do
        M._setting_row(text, state, setting)
      end
      text:nl()
      M._push_loc("blank")
    end
  end
end

function M._setting_row(text, state, setting)
  local cfg = config.get()
  local available = platform_mod.is_available(setting)
  local value = state.setting_values[setting.key]
  local is_dirty = state:is_dirty(setting.key)

  -- Indent
  text:append("    ", "EvensongNormal")

  if not available then
    -- Dimmed unavailable setting
    text:append(setting.display_name, "EvensongDimmed")
    text:append(name_pad(setting.display_name), "EvensongDimmed")
    local reason = platform_mod.unavailable_reason(setting)
    if reason then
      text:append("[" .. reason .. "]", "EvensongBadgeUnavailable")
    end
    M._push_loc("setting", setting.key, setting.category)
    text:nl()
    return
  end

  -- Setting name
  text:append(setting.display_name, "EvensongSettingName")
  text:append(name_pad(setting.display_name), "EvensongNormal")

  -- Type-specific value rendering
  if setting.type == "boolean" then
    M._render_bool(text, value, cfg)
  elseif setting.type == "float" then
    M._render_float(text, value, setting)
  elseif setting.type == "integer" then
    M._render_integer(text, value, setting)
  elseif setting.type == "enum" then
    M._render_enum(text, value, setting)
  elseif setting.type == "color" then
    M._render_color(text, value)
  elseif setting.type == "font" or setting.type == "string" then
    M._render_string(text, value)
  end

  -- Status badges
  M._render_badges(text, setting, is_dirty)

  M._push_loc("setting", setting.key, setting.category)
  text:nl()
end

function M._render_bool(text, value, cfg)
  local icons = cfg.icons
  if value then
    text:append(icons.bool_true .. "true", "EvensongBoolTrue")
  else
    text:append(icons.bool_false .. "false", "EvensongBoolFalse")
  end
end

-- Slider bar. Uses the lower-half block (▄) rather than the full block (█) so the
-- bar sits in the bottom of the line, leaving a half-line gap above it — this keeps
-- vertically-stacked sliders from fusing into one solid mass, without an extra line.
local BAR_WIDTH = 20
local BAR_GLYPH = "▄"

function M._slider(text, value, min, max)
  local range = max - min
  local ratio = range > 0 and (value - min) / range or 0
  ratio = util.clamp(ratio, 0, 1)
  local filled = math.floor(ratio * BAR_WIDTH + 0.5)
  local empty = BAR_WIDTH - filled

  text:append(string.rep(BAR_GLYPH, filled), "EvensongSliderFilled")
  text:append(string.rep(BAR_GLYPH, empty), "EvensongSliderEmpty")
  text:append(" ", "EvensongNormal")
end

function M._render_float(text, value, setting)
  if setting.min ~= nil and setting.max ~= nil then
    M._slider(text, value, setting.min, setting.max)
  end
  text:append(tostring(util.round(value, 3)), "EvensongNumberValue")
end

function M._render_integer(text, value, setting)
  if setting.min ~= nil and setting.max ~= nil then
    M._slider(text, value, setting.min, setting.max)
  end
  text:append(tostring(value), "EvensongNumberValue")
end

function M._render_enum(text, value, setting)
  local display = value == "" and "(none)" or tostring(value)
  text:append(display, "EvensongEnumValue")
  if setting.choices then
    text:append(" [" .. #setting.choices .. " choices]", "EvensongDimmed")
  end
end

function M._render_color(text, value)
  if value and value ~= "" then
    text:append(tostring(value), "EvensongStringValue")
    text:append(" ", "EvensongNormal")
    text:append("██", "EvensongStringValue")
  else
    text:append("(not set)", "EvensongDimmed")
  end
end

function M._render_string(text, value)
  if value and value ~= "" then
    text:append(tostring(value), "EvensongStringValue")
  else
    text:append("(not set)", "EvensongDimmed")
  end
end

function M._render_badges(text, setting, is_dirty)
  if setting.restart_required then
    text:append(" [restart]", "EvensongBadgeRestart")
  end
  if setting.platform then
    text:append(" [" .. setting.platform .. "]", "EvensongBadgePlatform")
  end
  if setting.nightly then
    text:append(" [nightly]", "EvensongBadgeNightly")
  end
  if is_dirty then
    text:append(" [modified]", "EvensongBadgeModified")
  end
end

function M._profiles(text, state)
  local profiles = require("evensong.profiles")
  local list = profiles.list()

  if #list == 0 then
    text:append("  No saved profiles yet.", "EvensongDimmed")
    M._push_loc("blank")
    text:nl()
    text:nl()
    M._push_loc("blank")
    text:append("  Press ", "EvensongDimmed")
    text:append("S", "EvensongKey")
    text:append(" to save current settings as a profile.", "EvensongDimmed")
    M._push_loc("blank")
    text:nl()
  else
    for _, name in ipairs(list) do
      text:append("  ", "EvensongNormal")
      text:append(" " .. name .. " ", "EvensongProfileName")
      M._push_loc("profile", name)
      text:nl()
    end
  end
end

function M._help(text)
  local cfg = config.get()
  local keys = cfg.keys

  local close_key = type(keys.close) == "table" and table.concat(keys.close, " / ") or keys.close

  -- Every helper emits exactly one line (append… → push → nl) so locations stay aligned.
  local function heading(str)
    text:append("  " .. str, "EvensongCategory")
    M._push_loc("help")
    text:nl()
  end
  local function row(key, desc)
    text:append("    ", "EvensongNormal")
    text:append(string.format("%-11s", key), "EvensongKey")
    text:append("  " .. desc, "EvensongNormal")
    M._push_loc("help")
    text:nl()
  end
  local function raw(fn)
    fn()
    M._push_loc("help")
    text:nl()
  end
  local function blank()
    M._push_loc("blank")
    text:nl()
  end

  raw(function()
    text:append("  ", "EvensongNormal")
    text:append(" Neovide Settings ", "EvensongH1")
  end)
  raw(function()
    text:append("  In-editor manager for Neovide's runtime settings.", "EvensongDimmed")
  end)
  blank()

  heading("Navigation")
  row("j / k", "Move down / up")
  row("{ / }", "Previous / next section  (also [[ / ]])")
  row("gg / G", "Jump to top / bottom")
  blank()

  heading("Editing")
  row(keys.toggle_category, "Activate — fold section · toggle bool · cycle enum · edit value")
  row(keys.decrement .. " / " .. keys.increment, "Collapse / expand section · decrease / increase value")
  row(keys.reset .. " / " .. keys.reset_factory, "Reset to my / factory default")
  blank()

  heading("Session")
  row(keys.apply, "Apply — save changes to disk")
  row(keys.save_profile, "Save current values as a profile")
  row(keys.profiles_view .. " / " .. keys.help_view, "Profiles view / toggle this help")
  row(close_key, "Close & discard unsaved changes")
  blank()

  heading("Legend")
  raw(function()
    text:append("    ", "EvensongNormal")
    text:append(string.rep("▄", 5), "EvensongSliderFilled")
    text:append(string.rep("▄", 3), "EvensongSliderEmpty")
    text:append("   slider — the filled portion is the current value", "EvensongDimmed")
  end)
  local badges = {
    { "[restart]", "EvensongBadgeRestart", "setting needs a Neovide restart to take effect" },
    { "[nightly]", "EvensongBadgeNightly", "requires a Neovide nightly build" },
    { "[macos]", "EvensongBadgePlatform", "platform-specific (also [windows] / [linux])" },
    { "[modified]", "EvensongBadgeModified", "changed but not yet applied" },
  }
  for _, b in ipairs(badges) do
    raw(function()
      text:append("    ", "EvensongNormal")
      text:append(string.format("%-11s", b[1]), b[2])
      text:append("  " .. b[3], "EvensongDimmed")
    end)
  end
  raw(function()
    text:append("    ", "EvensongNormal")
    text:append(string.format("%-11s", "(not set)"), "EvensongDimmed")
    text:append("  no value assigned", "EvensongDimmed")
  end)
  blank()

  raw(function()
    text:append("  See ", "EvensongDimmed")
    text:append(":help evensong", "EvensongKey")
    text:append("  ·  github.com/plongitudes/tidiest-evensong.nvim", "EvensongDimmed")
  end)
end

function M._push_loc(loc_type, key, category)
  table.insert(M.locations, {
    type = loc_type,
    key = key,
    category = category,
  })
end

-- Find the nearest navigable row at or after `row`
function M.nearest_setting_row(row, direction)
  direction = direction or 1
  local start = row
  while start >= 1 and start <= #M.locations do
    local loc = M.locations[start]
    if loc and (loc.type == "setting" or loc.type == "category" or loc.type == "profile") then
      return start
    end
    start = start + direction
  end
  return row
end

function M.next_category_row(from_row)
  for i = from_row + 1, #M.locations do
    if M.locations[i] and M.locations[i].type == "category" then
      return i
    end
  end
  return from_row
end

function M.prev_category_row(from_row)
  for i = from_row - 1, 1, -1 do
    if M.locations[i] and M.locations[i].type == "category" then
      return i
    end
  end
  return from_row
end

return M
