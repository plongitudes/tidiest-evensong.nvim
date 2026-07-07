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

  -- Keep the focused-setting detail (winbar) in sync as the cursor moves. Buffer-local
  -- autocmd, so it is cleaned up automatically when the scratch buffer is wiped on close.
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = float.buf,
    group = vim.api.nvim_create_augroup("neovide_view_detail", { clear = true }),
    callback = function()
      if float and float:is_open() then
        -- Keep the tracked row in sync with any cursor movement, including unmapped
        -- motions (arrow keys, mouse), then refresh the detail line.
        state.cursor_row = vim.api.nvim_win_get_cursor(float.win)[1]
        M._update_detail()
      end
    end,
  })

  -- Position cursor on first navigable row
  local first = render.nearest_setting_row(1, 1)
  M._set_cursor(first)
  M._update_detail()
end

-- Show the focused setting's description in the window's winbar (a fixed line that
-- does not scroll). Kept non-empty so the bar height stays stable across rows.
function M._update_detail()
  if not (float and float:is_open()) then
    return
  end
  local loc = render.locations[state.cursor_row]
  local detail = " "
  if loc and loc.type == "setting" then
    local setting = registry.get(loc.key)
    if setting and setting.description and setting.description ~= "" then
      -- Escape % so the winbar does not interpret them as statusline items.
      local desc = setting.description:gsub("%%", "%%%%")
      detail = "%#NeovideCategoryIcon# ⓘ %#NeovideDimmed#" .. desc
    end
  end
  vim.wo[float.win].winbar = detail
end

function M.close()
  if float and float:is_open() then
    -- Explicit-save model: closing discards unsaved changes. Revert them live so the
    -- editor returns to how it looked when the menu opened (or the last Apply).
    if state and state:has_dirty() then
      local n = state:dirty_count()
      M._revert_all()
      local apply_key = config.get().keys.apply
      vim.notify(
        ("neovide.nvim: discarded %d unsaved change(s) — press %q to save next time"):format(n, apply_key),
        vim.log.levels.INFO
      )
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
  M._update_detail()
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

  -- Next section: beginning of the following category.
  float:on_key({ keys.next_category, "]]" }, function()
    M._set_cursor(render.next_category_row(state.cursor_row))
  end, "Next section")

  -- Previous section: beginning of the current category, or the previous one if
  -- already on a category header.
  float:on_key({ keys.prev_category, "[[" }, function()
    M._set_cursor(render.prev_category_row(state.cursor_row))
  end, "Previous / current section")

  -- Enter: the single "activate this row" action. Folds a category, toggles a
  -- boolean, cycles an enum, edits any other value type, or applies a profile.
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
      else
        M._edit_setting(setting)
      end
    elseif loc.type == "profile" then
      M._apply_profile(loc.key)
    end
  end, "Activate (fold / toggle / cycle / edit)")

  -- Increment / expand: on a category, expand it; on a setting, raise the value.
  float:on_key(keys.increment, function()
    local loc = render.locations[state.cursor_row]
    if not loc then
      return
    end
    if loc.type == "category" then
      M._set_category_expanded(loc.category, true)
      return
    end
    if loc.type ~= "setting" then
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
  end, "Increment / expand")

  -- Decrement / collapse: on a category, collapse it; on a setting, lower the value.
  float:on_key(keys.decrement, function()
    local loc = render.locations[state.cursor_row]
    if not loc then
      return
    end
    if loc.type == "category" then
      M._set_category_expanded(loc.category, false)
      return
    end
    if loc.type ~= "setting" then
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
  end, "Decrement / collapse")

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

function M._set_category_expanded(category, expanded)
  if state.categories_expanded[category] == expanded then
    return
  end
  state.categories_expanded[category] = expanded
  M._render()
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

-- Entry point for the "edit" keymap. Font settings get a family picker; everything
-- else gets free-form input.
function M._edit_setting(setting)
  if setting.type == "font" then
    M._pick_font(setting)
  else
    M._input_value(setting)
  end
end

-- Two-step font editor: a live-preview family picker, then a size prompt. "c" in the
-- picker drops to free-form input for a full custom guifont spec.
function M._pick_font(setting)
  local current = tostring(state.setting_values[setting.key] or "")
  local size = current:match(":h([%d%.]+)")
  local family = current:match("^(.-):h[%d%.]+")
  if not family or family == "" then
    family = current ~= "" and current or nil
  end

  require("neovide.font_picker").open({
    current_family = family,
    size = size,
    on_choose = function(chosen)
      M._prompt_font_size(setting, chosen, size)
    end,
    on_custom = function()
      M._input_value(setting)
    end,
  })
end

-- Step two of the font editor: choose the point size, prefilled with the current one.
-- Empty input drops the size suffix; invalid input keeps the current size.
function M._prompt_font_size(setting, family, current_size)
  vim.ui.input({ prompt = "Size (pt): ", default = current_size or "14" }, function(input)
    if input == nil then
      input = current_size or "14"
    end
    input = vim.trim(input)
    local value
    if input == "" then
      value = family
    else
      local n = tonumber(input)
      if not n or n <= 0 then
        vim.notify("Invalid font size: " .. input, vim.log.levels.WARN)
        value = current_size and (family .. ":h" .. current_size) or family
      else
        local size_str = (n == math.floor(n)) and tostring(math.floor(n)) or tostring(n)
        value = family .. ":h" .. size_str
      end
    end
    M._set_value(setting, value)
  end)
end

function M._input_value(setting)
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

  -- Persist every dirty TOML setting. toml.set no-ops when the on-disk value already
  -- matches, so writing an unchanged value is cheap — and, unlike the old skip-if-equal-
  -- to-default guard, resetting a toml_* key to its default now correctly overwrites a
  -- stale non-default line in config.toml instead of silently leaving it.
  for key, _ in pairs(state.dirty) do
    local setting = registry.get(key)
    if setting and setting.source == "toml" then
      registry.write_value(setting, state.setting_values[key])
    end
  end

  state:mark_all_clean()
  M._render()
end

-- Revert every unsaved change back to the session baseline (saved_values, captured on
-- open and refreshed on each Apply), re-applying live so the editor returns to that
-- state. TOML settings were never applied live, so clearing them from state is enough.
function M._revert_all()
  local cfg = config.get()
  for _, key in ipairs(vim.tbl_keys(state.dirty)) do
    local setting = registry.get(key)
    local baseline = state.saved_values[key]
    state:set_value(key, baseline)
    if setting and cfg.auto_apply and setting.source ~= "toml" then
      registry.write_value(setting, baseline)
    end
  end
  state.dirty = {}
  M._render()
end

function M._apply_profile(name)
  local profiles = require("neovide.profiles")
  local profile = profiles.load(name)
  if not profile then
    vim.notify("Profile not found: " .. name, vim.log.levels.WARN)
    return
  end
  -- Apply profile settings, coercing any invalid value to its registry default so a
  -- stale/hand-edited profile (e.g. theme = "") can't reach vim.g and crash Neovide.
  local coerced = {}
  for key, value in pairs(profile.settings or {}) do
    local setting, val = registry.coerce_value(key, value, coerced)
    if setting then
      state:set_value(key, val)
      if config.get().auto_apply and setting.source ~= "toml" then
        registry.write_value(setting, val)
      end
    end
  end
  if #coerced > 0 then
    vim.notify("neovide.nvim: ignored invalid profile value(s): " .. table.concat(coerced, ", "), vim.log.levels.WARN)
  end
  vim.notify("Profile '" .. name .. "' applied", vim.log.levels.INFO)
  state.mode = "settings"
  M._render()
  M._set_cursor(render.nearest_setting_row(1, 1))
end

return M
