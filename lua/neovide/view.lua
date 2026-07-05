local Float = require("neovide.float")
local State = require("neovide.state")
local render = require("neovide.render")
local registry = require("neovide.registry")
local config = require("neovide.config")
local platform_mod = require("neovide.platform")
local persistence = require("neovide.persistence")
local util = require("neovide.util")

local M = {}

local float = nil
local state = nil

function M.open(arg)
  if float and float:is_open() then
    float:close()
  end

  state = State.new()

  -- Handle argument for initial view
  if arg then
    local lower = arg:lower()
    if lower == "profiles" then
      state.mode = "profiles"
    elseif lower == "help" then
      state.mode = "help"
    else
      -- Try to match a category name
      for _, cat in ipairs(registry.categories()) do
        if cat:lower() == lower or cat:lower():find(lower, 1, true) then
          -- Collapse all, expand only this one
          for _, c in ipairs(registry.categories()) do
            state.categories_expanded[c] = false
          end
          state.categories_expanded[cat] = true
          break
        end
      end
    end
  end

  float = Float.new()
  float:open()

  M._render()
  M._setup_keymaps()

  -- Position cursor on first navigable row
  local first = render.nearest_setting_row(1, 1)
  M._set_cursor(first)
end

function M.close()
  if float and float:is_open() then
    if state and state:has_dirty() then
      M._save_all()
    end
    float:close()
  end
  state = nil
  float = nil
end

function M.toggle()
  if float and float:is_open() then
    M.close()
  else
    M.open()
  end
end

function M._render()
  if not float or not float.buf then
    return
  end
  local cursor_before = state.cursor_row
  render.build(state, float.buf)
  -- Restore cursor position
  M._set_cursor(cursor_before)
end

function M._set_cursor(row)
  if not float or not float.win or not vim.api.nvim_win_is_valid(float.win) then
    return
  end
  local max_lines = vim.api.nvim_buf_line_count(float.buf)
  row = util.clamp(row, 1, max_lines)
  state.cursor_row = row
  vim.api.nvim_win_set_cursor(float.win, { row, 0 })
end

function M._setup_keymaps()
  local cfg = config.get()
  local keys = cfg.keys

  -- Close
  float:on_key(keys.close, function()
    M.close()
  end, "Close")

  -- Navigation
  float:on_key("j", function()
    local next = render.nearest_setting_row(state.cursor_row + 1, 1)
    M._set_cursor(next)
  end, "Next setting")

  float:on_key("k", function()
    local prev = render.nearest_setting_row(state.cursor_row - 1, -1)
    M._set_cursor(prev)
  end, "Previous setting")

  float:on_key("}", function()
    local next = render.next_category_row(state.cursor_row)
    M._set_cursor(next)
  end, "Next category")

  float:on_key("{", function()
    local prev = render.prev_category_row(state.cursor_row)
    M._set_cursor(prev)
  end, "Previous category")

  -- Enter: toggle bool / expand category / cycle enum
  float:on_key(keys.toggle_category, function()
    local loc = render.locations[state.cursor_row]
    if not loc then
      return
    end

    if loc.type == "category" then
      state.categories_expanded[loc.category] = not state.categories_expanded[loc.category]
      M._render()
    elseif loc.type == "setting" then
      local setting = registry.get(loc.key)
      if not setting or not platform_mod.is_available(setting) then
        return
      end
      if setting.type == "boolean" then
        M._toggle_bool(setting)
      elseif setting.type == "enum" then
        M._cycle_enum(setting, 1)
      end
    elseif loc.type == "profile" then
      M._apply_profile(loc.key)
    end
  end, "Toggle / expand")

  -- Increment/Decrement
  float:on_key(keys.increment, function()
    local loc = render.locations[state.cursor_row]
    if not loc or loc.type ~= "setting" then
      return
    end
    local setting = registry.get(loc.key)
    if not setting or not platform_mod.is_available(setting) then
      return
    end
    if setting.type == "float" or setting.type == "integer" then
      M._adjust_number(setting, 1)
    elseif setting.type == "enum" then
      M._cycle_enum(setting, 1)
    end
  end, "Increment / next")

  float:on_key(keys.decrement, function()
    local loc = render.locations[state.cursor_row]
    if not loc or loc.type ~= "setting" then
      return
    end
    local setting = registry.get(loc.key)
    if not setting or not platform_mod.is_available(setting) then
      return
    end
    if setting.type == "float" or setting.type == "integer" then
      M._adjust_number(setting, -1)
    elseif setting.type == "enum" then
      M._cycle_enum(setting, -1)
    end
  end, "Decrement / prev")

  -- Edit (free-form input)
  float:on_key(keys.edit, function()
    local loc = render.locations[state.cursor_row]
    if not loc or loc.type ~= "setting" then
      return
    end
    local setting = registry.get(loc.key)
    if not setting or not platform_mod.is_available(setting) then
      return
    end
    M._edit_setting(setting)
  end, "Edit value")

  -- Reset to user default
  float:on_key(keys.reset, function()
    local loc = render.locations[state.cursor_row]
    if not loc or loc.type ~= "setting" then
      return
    end
    local setting = registry.get(loc.key)
    if not setting or not platform_mod.is_available(setting) then
      return
    end
    M._set_value(setting, persistence.user_default(setting.key))
  end, "Reset to my defaults")

  -- Reset to factory default
  float:on_key(keys.reset_factory, function()
    local loc = render.locations[state.cursor_row]
    if not loc or loc.type ~= "setting" then
      return
    end
    local setting = registry.get(loc.key)
    if not setting or not platform_mod.is_available(setting) then
      return
    end
    M._set_value(setting, setting.default)
  end, "Reset to factory defaults")

  -- Apply (save to disk)
  float:on_key(keys.apply, function()
    M._save_all()
    vim.notify("Neovide settings saved", vim.log.levels.INFO)
  end, "Save settings")

  -- Save profile
  float:on_key(keys.save_profile, function()
    vim.ui.input({ prompt = "Profile name: " }, function(name)
      if name and name ~= "" then
        local profiles = require("neovide.profiles")
        profiles.save(name, state.setting_values)
        vim.notify("Profile '" .. name .. "' saved", vim.log.levels.INFO)
        if state.mode == "profiles" then
          M._render()
        end
      end
    end)
  end, "Save profile")

  -- Profiles view
  float:on_key(keys.profiles_view, function()
    if state.mode == "profiles" then
      state.mode = "settings"
    else
      state.mode = "profiles"
    end
    M._render()
    M._set_cursor(render.nearest_setting_row(1, 1))
  end, "Toggle profiles view")

  -- Help view
  float:on_key(keys.help_view, function()
    if state.mode == "help" then
      state.mode = "settings"
    else
      state.mode = "help"
    end
    M._render()
    M._set_cursor(1)
  end, "Toggle help")

  -- Scroll with gg and G
  float:on_key("gg", function()
    M._set_cursor(render.nearest_setting_row(1, 1))
  end, "Go to top")

  float:on_key("G", function()
    M._set_cursor(render.nearest_setting_row(#render.locations, -1))
  end, "Go to bottom")
end

-- ─── Value Manipulation ────────────────────────────────────────────

function M._toggle_bool(setting)
  local current = state.setting_values[setting.key]
  M._set_value(setting, not current)
end

function M._cycle_enum(setting, direction)
  if not setting.choices or #setting.choices == 0 then
    return
  end
  local current = state.setting_values[setting.key]
  local idx = 1
  for i, choice in ipairs(setting.choices) do
    if choice == current then
      idx = i
      break
    end
  end
  idx = idx + direction
  if idx > #setting.choices then
    idx = 1
  elseif idx < 1 then
    idx = #setting.choices
  end
  M._set_value(setting, setting.choices[idx])
end

function M._adjust_number(setting, direction)
  local current = state.setting_values[setting.key] or setting.default
  local step = setting.step or 1
  local new_value = current + (step * direction)
  if setting.min ~= nil then
    new_value = math.max(new_value, setting.min)
  end
  if setting.max ~= nil then
    new_value = math.min(new_value, setting.max)
  end
  if setting.type == "integer" then
    new_value = math.floor(new_value + 0.5)
  else
    new_value = util.round(new_value, 3)
  end
  M._set_value(setting, new_value)
end

function M._edit_setting(setting)
  local current = state.setting_values[setting.key]
  local prompt = setting.display_name
  if setting.type == "enum" and setting.choices then
    prompt = prompt .. " (" .. table.concat(setting.choices, "/") .. ")"
  end
  prompt = prompt .. ": "

  vim.ui.input({ prompt = prompt, default = tostring(current or "") }, function(input)
    if input == nil then
      return
    end
    local value
    if setting.type == "boolean" then
      value = input == "true" or input == "1" or input == "yes"
    elseif setting.type == "float" then
      value = tonumber(input)
      if not value then
        return
      end
      if setting.min then
        value = math.max(value, setting.min)
      end
      if setting.max then
        value = math.min(value, setting.max)
      end
    elseif setting.type == "integer" then
      value = tonumber(input)
      if not value then
        return
      end
      value = math.floor(value + 0.5)
      if setting.min then
        value = math.max(value, setting.min)
      end
      if setting.max then
        value = math.min(value, setting.max)
      end
    elseif setting.type == "enum" then
      if setting.choices then
        local found = false
        for _, c in ipairs(setting.choices) do
          if c == input then
            found = true
            break
          end
        end
        if not found then
          vim.notify("Invalid choice: " .. input, vim.log.levels.WARN)
          return
        end
      end
      value = input
    else
      value = input
    end
    M._set_value(setting, value)
  end)
end

function M._set_value(setting, value)
  state:set_value(setting.key, value)

  -- Live preview for runtime and vim_option sources
  local cfg = config.get()
  if cfg.auto_apply and setting.source ~= "toml" then
    registry.write_value(setting, value)
  end

  M._render()
end

function M._save_all()
  -- Save runtime settings
  persistence.save(state.setting_values)

  -- Write only dirty TOML settings that differ from built-in defaults
  for key, _ in pairs(state.dirty) do
    local setting = registry.get(key)
    if setting and setting.source == "toml" then
      local value = state.setting_values[key]
      local util = require("neovide.util")
      if not util.deep_equals(value, setting.default) then
        registry.write_value(setting, value)
      end
    end
  end

  state:mark_all_clean()
  M._render()
end

function M._apply_profile(name)
  local profiles = require("neovide.profiles")
  local profile = profiles.load(name)
  if not profile then
    vim.notify("Profile not found: " .. name, vim.log.levels.WARN)
    return
  end
  -- Apply profile settings
  for key, value in pairs(profile.settings or {}) do
    local setting = registry.get(key)
    if setting then
      state:set_value(key, value)
      if config.get().auto_apply and setting.source ~= "toml" then
        registry.write_value(setting, value)
      end
    end
  end
  vim.notify("Profile '" .. name .. "' applied", vim.log.levels.INFO)
  state.mode = "settings"
  M._render()
  M._set_cursor(render.nearest_setting_row(1, 1))
end

return M
