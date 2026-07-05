-- Copyright Epic Games, Inc. All Rights Reserved.
-- CONTAINS AI GENERATED CODE
local M = {}

local config = require("neovide.config")
local registry = require("neovide.registry")
local util = require("neovide.util")

local function profiles_dir()
  return config.get().data_path .. "/profiles"
end

function M.list()
  local dir = profiles_dir()
  if vim.fn.isdirectory(dir) == 0 then
    return {}
  end
  local files = vim.fn.glob(dir .. "/*.lua", false, true)
  local names = {}
  for _, f in ipairs(files) do
    local name = vim.fn.fnamemodify(f, ":t:r")
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

function M.load(name)
  local path = profiles_dir() .. "/" .. name .. ".lua"
  if vim.fn.filereadable(path) == 0 then
    return nil
  end
  local ok, data = pcall(dofile, path)
  if ok and type(data) == "table" then
    return data
  end
  return nil
end

function M.save(name, settings, desc)
  local dir = profiles_dir()
  util.ensure_dir(dir)

  -- Only snapshot runtime settings (not TOML)
  local to_save = {}
  for key, value in pairs(settings) do
    local setting = registry.get(key)
    if setting and setting.source ~= "toml" then
      to_save[key] = value
    end
  end

  local profile = {
    name = name,
    description = desc or "",
    created_at = os.date("%Y-%m-%d %H:%M:%S"),
    settings = to_save,
  }

  local path = dir .. "/" .. name .. ".lua"
  local content = "return " .. vim.inspect(profile) .. "\n"
  local f = io.open(path, "w")
  if f then
    f:write(content)
    f:close()
  end
end

function M.delete(name)
  local path = profiles_dir() .. "/" .. name .. ".lua"
  if vim.fn.filereadable(path) == 1 then
    os.remove(path)
  end
end

function M.apply(profile)
  if not profile or not profile.settings then
    return
  end
  for key, value in pairs(profile.settings) do
    local setting = registry.get(key)
    if setting then
      registry.write_value(setting, value)
    end
  end
end

return M
