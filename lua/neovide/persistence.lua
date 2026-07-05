local M = {}

local config = require("neovide.config")
local util = require("neovide.util")

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
  local registry = require("neovide.registry")
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
  return {}
end

function M.save(settings)
  local path = get_path()
  local dir = vim.fn.fnamemodify(path, ":h")
  util.ensure_dir(dir)

  local registry = require("neovide.registry")
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
  local f = io.open(path, "w")
  if f then
    f:write(content)
    f:close()
  end
end

function M.apply_saved()
  local registry = require("neovide.registry")
  local coerced = {}

  -- Apply a single value, coercing to the registry default if it fails validation
  -- (so a dirty persisted value like theme = "" can never reach vim.g).
  local function apply(key, value)
    local setting = registry.get(key)
    if not setting then
      return
    end
    if not registry.is_valid(setting, value) then
      table.insert(coerced, key)
      value = setting.default
    end
    registry.write_value(setting, value)
  end

  -- Layer 2: apply user-declared defaults
  for key, value in pairs(config.get().settings) do
    apply(key, value)
  end

  -- Layer 3: apply runtime-persisted overrides on top
  for key, value in pairs(M.load()) do
    apply(key, value)
  end

  if #coerced > 0 then
    vim.notify("neovide.nvim: ignored invalid saved value(s): " .. table.concat(coerced, ", "), vim.log.levels.WARN)
  end
end

return M
