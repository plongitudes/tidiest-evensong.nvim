-- Copyright Epic Games, Inc. All Rights Reserved.
-- CONTAINS AI GENERATED CODE
local M = {}

local platform = require("neovide.platform")

function M.config_path()
  local env = vim.env.NEOVIDE_CONFIG
  if env and env ~= "" then
    return env
  end
  local os_name = platform.os()
  if os_name == "windows" then
    local appdata = vim.env.APPDATA
    if appdata then
      return appdata .. "\\neovide\\config.toml"
    end
    return vim.fn.expand("~") .. "\\AppData\\Roaming\\neovide\\config.toml"
  elseif os_name == "macos" then
    local xdg = vim.env.XDG_CONFIG_HOME
    if xdg then
      return xdg .. "/neovide/config.toml"
    end
    return vim.fn.expand("~") .. "/.config/neovide/config.toml"
  else
    local xdg = vim.env.XDG_CONFIG_HOME
    if xdg then
      return xdg .. "/neovide/config.toml"
    end
    return vim.fn.expand("~") .. "/.config/neovide/config.toml"
  end
end

-- Minimal TOML parser: handles flat keys, [section] headers, basic types
function M.read(path)
  path = path or M.config_path()
  if vim.fn.filereadable(path) == 0 then
    return {}
  end
  local lines = {}
  local f = io.open(path, "r")
  if not f then
    return {}
  end
  for line in f:lines() do
    table.insert(lines, line)
  end
  f:close()

  local data = {}
  local current_section = nil

  for _, line in ipairs(lines) do
    local trimmed = line:match("^%s*(.-)%s*$")
    -- Skip empty lines and comments
    if trimmed == "" or trimmed:sub(1, 1) == "#" then
      goto continue
    end

    -- Section header [section] or [section.subsection]
    local section = trimmed:match("^%[([^%]]+)%]$")
    if section then
      current_section = section
      -- Ensure nested table exists
      local keys = vim.split(section, ".", { plain = true })
      local node = data
      for _, k in ipairs(keys) do
        if not node[k] then
          node[k] = {}
        end
        node = node[k]
      end
      goto continue
    end

    -- Key = value
    local key, raw_value = trimmed:match("^([%w_%-]+)%s*=%s*(.+)$")
    if key and raw_value then
      local value = M._parse_value(raw_value)
      if current_section then
        local keys = vim.split(current_section, ".", { plain = true })
        local node = data
        for _, k in ipairs(keys) do
          if not node[k] then
            node[k] = {}
          end
          node = node[k]
        end
        node[key] = value
      else
        data[key] = value
      end
    end

    ::continue::
  end

  return data
end

function M._parse_value(raw)
  -- Boolean
  if raw == "true" then
    return true
  end
  if raw == "false" then
    return false
  end
  -- String (quoted)
  local str = raw:match('^"(.-)"$') or raw:match("^'(.-)'$")
  if str then
    return str
  end
  -- Number (float or int)
  local num = tonumber(raw)
  if num then
    return num
  end
  -- Array (basic)
  local arr = raw:match("^%[(.*)%]$")
  if arr then
    local result = {}
    for item in arr:gmatch("[^,]+") do
      item = item:match("^%s*(.-)%s*$")
      table.insert(result, M._parse_value(item))
    end
    return result
  end
  return raw
end

function M.write(path, data)
  path = path or M.config_path()
  local dir = vim.fn.fnamemodify(path, ":h")
  require("neovide.util").ensure_dir(dir)

  local lines = {}

  -- Write top-level flat keys first
  local top_keys = {}
  local section_keys = {}
  for k, v in pairs(data) do
    if type(v) == "table" then
      table.insert(section_keys, k)
    else
      table.insert(top_keys, k)
    end
  end
  table.sort(top_keys)
  table.sort(section_keys)

  for _, k in ipairs(top_keys) do
    table.insert(lines, k .. " = " .. M._format_value(data[k]))
  end

  if #top_keys > 0 and #section_keys > 0 then
    table.insert(lines, "")
  end

  -- Write sections
  for _, section in ipairs(section_keys) do
    M._write_section(lines, section, data[section])
  end

  local f = io.open(path, "w")
  if f then
    f:write(table.concat(lines, "\n") .. "\n")
    f:close()
  end
end

function M._write_section(lines, prefix, tbl)
  local flat_keys = {}
  local nested_keys = {}
  for k, v in pairs(tbl) do
    if type(v) == "table" then
      table.insert(nested_keys, k)
    else
      table.insert(flat_keys, k)
    end
  end
  table.sort(flat_keys)
  table.sort(nested_keys)

  if #flat_keys > 0 then
    table.insert(lines, "[" .. prefix .. "]")
    for _, k in ipairs(flat_keys) do
      table.insert(lines, k .. " = " .. M._format_value(tbl[k]))
    end
    table.insert(lines, "")
  end

  for _, k in ipairs(nested_keys) do
    M._write_section(lines, prefix .. "." .. k, tbl[k])
  end
end

function M._format_value(v)
  if type(v) == "boolean" then
    return v and "true" or "false"
  elseif type(v) == "number" then
    if v == math.floor(v) then
      return tostring(math.floor(v))
    end
    return tostring(v)
  elseif type(v) == "string" then
    return '"' .. v:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
  elseif type(v) == "table" then
    local items = {}
    for _, item in ipairs(v) do
      table.insert(items, M._format_value(item))
    end
    return "[" .. table.concat(items, ", ") .. "]"
  end
  return tostring(v)
end

function M.set(key_path, value)
  local data = M.read()
  local keys = vim.split(key_path, ".", { plain = true })
  local node = data
  for i = 1, #keys - 1 do
    if not node[keys[i]] then
      node[keys[i]] = {}
    end
    node = node[keys[i]]
  end
  node[keys[#keys]] = value
  M.write(nil, data)
end

return M
