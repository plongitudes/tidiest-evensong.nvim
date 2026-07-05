local M = {}

function M.new()
  local self = {
    mode = "settings",
    categories_expanded = {},
    cursor_row = 1,
    setting_values = {},
    dirty = {},
    saved_values = {},
  }

  -- Start with all categories expanded
  local registry = require("neovide.registry")
  for _, cat in ipairs(registry.categories()) do
    self.categories_expanded[cat] = false
  end

  -- Read current values
  for _, setting in ipairs(registry.settings) do
    self.setting_values[setting.key] = registry.read_value(setting)
    self.saved_values[setting.key] = self.setting_values[setting.key]
  end

  return setmetatable(self, { __index = M })
end

function M:snapshot()
  return {
    mode = self.mode,
    categories_expanded = vim.deepcopy(self.categories_expanded),
    cursor_row = self.cursor_row,
    setting_values = vim.deepcopy(self.setting_values),
    dirty = vim.deepcopy(self.dirty),
    saved_values = vim.deepcopy(self.saved_values),
  }
end

function M:restore(data)
  self.mode = data.mode
  self.categories_expanded = data.categories_expanded
  self.cursor_row = data.cursor_row
  self.setting_values = data.setting_values
  self.dirty = data.dirty
  self.saved_values = data.saved_values
end

function M:is_dirty(key)
  return self.dirty[key] == true
end

function M:mark_dirty(key)
  self.dirty[key] = true
end

function M:mark_clean(key)
  self.dirty[key] = nil
  self.saved_values[key] = self.setting_values[key]
end

function M:mark_all_clean()
  self.dirty = {}
  self.saved_values = vim.deepcopy(self.setting_values)
end

function M:has_dirty()
  return next(self.dirty) ~= nil
end

function M:set_value(key, value)
  self.setting_values[key] = value
  local util = require("neovide.util")
  if not util.deep_equals(value, self.saved_values[key]) then
    self.dirty[key] = true
  else
    self.dirty[key] = nil
  end
end

function M:dirty_count()
  local count = 0
  for _ in pairs(self.dirty) do
    count = count + 1
  end
  return count
end

return M
