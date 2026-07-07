local M = {}

local config = require("evensong.config")
local util = require("evensong.util")

local function get_path()
  local data_path = config.get().data_path
  return data_path .. "/settings.lua"
end

--- Return the effective default for a key: user-declared override if present,
--- otherwise the built-in registry default.
function M.user_default(key)
  local user_settings = config.get().settings
  if user_settings[key] ~= nil then
    return user_settings[key]
  end
  local registry = require("evensong.registry")
  local setting = registry.get(key)
  return setting and setting.default
end

function M.load()
  local path = get_path()
  if vim.fn.filereadable(path) == 0 then
    return {}
  end
  local ok, data = pcall(dofile, path)
  if ok and type(data) == "table" then
    return data
  end
  -- The file exists but could not be parsed (corrupt/truncated). Surface it rather
  -- than silently dropping the user's entire saved settings.
  vim.notify("evensong: could not read saved settings (" .. path .. "); using defaults", vim.log.levels.WARN)
  return {}
end

function M.save(settings)
  local path = get_path()

  local registry = require("evensong.registry")
  -- Only save values that differ from user_default and are runtime/vim_option source
  local to_save = {}
  for key, value in pairs(settings) do
    local setting = registry.get(key)
    if setting and setting.source ~= "toml" and registry.is_valid(setting, value) then
      local default = M.user_default(key)
      if not util.deep_equals(value, default) then
        to_save[key] = value
      end
    end
  end

  local content = "return " .. vim.inspect(to_save) .. "\n"
  local ok, err = util.write_atomic(path, content)
  if not ok then
    vim.notify("evensong: failed to save settings: " .. tostring(err), vim.log.levels.WARN)
  end
end

function M.apply_saved()
  local registry = require("evensong.registry")
  -- Track coercion per key (not as a flat list): a later layer applying a *valid*
  -- value for the same key clears an earlier layer's coercion, so we never warn
  -- about a key that ends up with a good value.
  local coerced = {}

  -- Apply a single value, coercing to the registry default if it fails validation
  -- (so a dirty persisted value like theme = "" can never reach vim.g).
  local function apply(key, value)
    local setting, val, was_coerced = registry.coerce_value(key, value)
    if setting then
      coerced[key] = was_coerced or nil
      registry.write_value(setting, val)
    end
  end

  -- Layer 2: apply user-declared defaults
  for key, value in pairs(config.get().settings) do
    apply(key, value)
  end

  -- Layer 3: apply runtime-persisted overrides on top
  for key, value in pairs(M.load()) do
    apply(key, value)
  end

  local names = vim.tbl_keys(coerced)
  if #names > 0 then
    table.sort(names)
    vim.notify("evensong: ignored invalid saved value(s): " .. table.concat(names, ", "), vim.log.levels.WARN)
  end
end

return M
