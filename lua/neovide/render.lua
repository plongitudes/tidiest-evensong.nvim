-- Copyright Epic Games, Inc. All Rights Reserved.
-- CONTAINS AI GENERATED CODE
local Text = require("neovide.text")
local config = require("neovide.config")
local registry = require("neovide.registry")
local platform_mod = require("neovide.platform")
local util = require("neovide.util")

local M = {}

-- Row-to-data mapping for cursor navigation
-- Each entry: { type = "category"|"setting"|"header"|"blank", key = string?, category = string? }
M.locations = {}

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
  text:append("  ", "NeovideNormal")
  text:append(" Neovide ", "NeovideH1")
  text:append("  ", "NeovideNormal")
  M._push_loc("header")
  text:nl()

  -- Mode pills
  text:append("  ", "NeovideNormal")
  local keys = cfg.keys
  local modes = {
    { key = "settings", icon = icons.settings, label = "Settings" },
    { key = "profiles", icon = icons.profiles, label = "Profiles", hotkey = keys.profiles_view },
    { key = "help", icon = icons.help, label = "Help", hotkey = keys.help_view },
  }
  for i, mode in ipairs(modes) do
    local active = state.mode == mode.key
    local hl = active and "NeovideButtonActive" or "NeovideButton"
    if not active and mode.hotkey then
      text:append(" " .. mode.hotkey .. " ", "NeovideKey")
    end
    text:append(" " .. mode.icon .. mode.label .. " ", hl)
    if i < #modes then
      text:append(" ", "NeovideNormal")
    end
  end

  -- Dirty count
  if state:has_dirty() then
    text:append("  ", "NeovideNormal")
    text:append(" " .. icons.modified .. state:dirty_count() .. " modified ", "NeovideBadgeModified")
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
    text:append("  ", "NeovideNormal")
    text:append(icon, "NeovideCategoryIcon")
    text:append(cat_icon, "NeovideCategoryIcon")
    text:append(cat_name, "NeovideCategory")
    text:append(" (" .. #settings .. ")", "NeovideDimmed")
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
  text:append("    ", "NeovideNormal")

  if not available then
    -- Dimmed unavailable setting
    text:append(setting.display_name, "NeovideDimmed")
    text:append("  ", "NeovideDimmed")
    local reason = platform_mod.unavailable_reason(setting)
    if reason then
      text:append("[" .. reason .. "]", "NeovideBadgeUnavailable")
    end
    M._push_loc("setting", setting.key, setting.category)
    text:nl()
    return
  end

  -- Setting name
  text:append(setting.display_name, "NeovideSettingName")
  text:append("  ", "NeovideNormal")

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
    text:append(icons.bool_true .. "true", "NeovideBoolTrue")
  else
    text:append(icons.bool_false .. "false", "NeovideBoolFalse")
  end
end

function M._render_float(text, value, setting)
  if setting.min ~= nil and setting.max ~= nil then
    -- Slider bar
    local bar_width = 20
    local range = setting.max - setting.min
    local ratio = range > 0 and (value - setting.min) / range or 0
    ratio = util.clamp(ratio, 0, 1)
    local filled = math.floor(ratio * bar_width + 0.5)
    local empty = bar_width - filled

    text:append(string.rep("█", filled), "NeovideSliderFilled")
    text:append(string.rep("░", empty), "NeovideSliderEmpty")
    text:append(" ", "NeovideNormal")
  end
  text:append(tostring(util.round(value, 3)), "NeovideNumberValue")
end

function M._render_integer(text, value, setting)
  if setting.min ~= nil and setting.max ~= nil then
    local bar_width = 20
    local range = setting.max - setting.min
    local ratio = range > 0 and (value - setting.min) / range or 0
    ratio = util.clamp(ratio, 0, 1)
    local filled = math.floor(ratio * bar_width + 0.5)
    local empty = bar_width - filled

    text:append(string.rep("█", filled), "NeovideSliderFilled")
    text:append(string.rep("░", empty), "NeovideSliderEmpty")
    text:append(" ", "NeovideNormal")
  end
  text:append(tostring(value), "NeovideNumberValue")
end

function M._render_enum(text, value, setting)
  local display = value == "" and "(none)" or tostring(value)
  text:append(display, "NeovideEnumValue")
  if setting.choices then
    text:append(" [" .. #setting.choices .. " choices]", "NeovideDimmed")
  end
end

function M._render_color(text, value)
  if value and value ~= "" then
    text:append(tostring(value), "NeovideStringValue")
    text:append(" ", "NeovideNormal")
    text:append("██", "NeovideStringValue")
  else
    text:append("(not set)", "NeovideDimmed")
  end
end

function M._render_string(text, value)
  if value and value ~= "" then
    text:append(tostring(value), "NeovideStringValue")
  else
    text:append("(not set)", "NeovideDimmed")
  end
end

function M._render_badges(text, setting, is_dirty)
  if setting.restart_required then
    text:append(" [restart]", "NeovideBadgeRestart")
  end
  if setting.platform then
    text:append(" [" .. setting.platform .. "]", "NeovideBadgePlatform")
  end
  if setting.nightly then
    text:append(" [nightly]", "NeovideBadgeNightly")
  end
  if is_dirty then
    text:append(" [modified]", "NeovideBadgeModified")
  end
end

function M._profiles(text, state)
  local profiles = require("neovide.profiles")
  local list = profiles.list()

  if #list == 0 then
    text:append("  No saved profiles yet.", "NeovideDimmed")
    M._push_loc("blank")
    text:nl()
    text:nl()
    M._push_loc("blank")
    text:append("  Press ", "NeovideDimmed")
    text:append("S", "NeovideKey")
    text:append(" to save current settings as a profile.", "NeovideDimmed")
    M._push_loc("blank")
    text:nl()
  else
    for _, name in ipairs(list) do
      text:append("  ", "NeovideNormal")
      text:append(" " .. name .. " ", "NeovideProfileName")
      M._push_loc("profile", name)
      text:nl()
    end
  end
end

function M._help(text)
  local cfg = config.get()
  local keys = cfg.keys

  text:append("  Keybindings", "NeovideCategory")
  M._push_loc("header")
  text:nl()
  text:nl()
  M._push_loc("blank")

  local bindings = {
    { key = "j / k", desc = "Navigate settings" },
    { key = "{ / }", desc = "Jump between categories" },
    { key = keys.toggle_category, desc = "Toggle category / toggle boolean / cycle enum" },
    { key = keys.increment .. " / " .. keys.decrement, desc = "Increment / decrement value" },
    { key = keys.edit, desc = "Edit value (free-form input)" },
    { key = keys.reset, desc = "Reset to my defaults" },
    { key = keys.reset_factory, desc = "Reset to factory defaults" },
    { key = keys.apply, desc = "Save settings to disk" },
    { key = keys.save_profile, desc = "Save as profile" },
    { key = keys.profiles_view, desc = "View profiles" },
    { key = keys.help_view, desc = "Toggle help" },
    { key = type(keys.close) == "table" and table.concat(keys.close, " / ") or keys.close, desc = "Close" },
  }

  for _, b in ipairs(bindings) do
    text:append("    ", "NeovideNormal")
    text:append(string.format("%-12s", b.key), "NeovideKey")
    text:append("  " .. b.desc, "NeovideNormal")
    M._push_loc("help")
    text:nl()
  end
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
