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
      local value = M._parse_value(M._strip_comment(raw_value))
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

-- Strip a trailing inline `# comment` from a raw value, but leave a `#` that is
-- inside a quoted string intact (e.g. title = "a # b"). Simple quote tracking, in
-- keeping with the rest of this minimal parser (no escaped-quote handling).
function M._strip_comment(raw)
  local in_single, in_double = false, false
  for i = 1, #raw do
    local c = raw:sub(i, i)
    if c == '"' and not in_single then
      in_double = not in_double
    elseif c == "'" and not in_double then
      in_single = not in_single
    elseif c == "#" and not in_single and not in_double then
      return (raw:sub(1, i - 1):gsub("%s+$", ""))
    end
  end
  return raw
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

-- NOTE: this regenerates config.toml from the parsed table — comments are not
-- preserved and keys are re-sorted. The plugin owns/reformats config.toml; keep any
-- hand-written comments elsewhere. toml.set skips the rewrite entirely when the value
-- is unchanged, so a file the plugin never modifies stays byte-for-byte intact.
function M.write(path, data)
  path = path or M.config_path()
  local float_keys = require("neovide.registry").float_toml_keys()

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
    table.insert(lines, k .. " = " .. M._format_value(data[k], float_keys[k]))
  end

  if #top_keys > 0 and #section_keys > 0 then
    table.insert(lines, "")
  end

  -- Write sections
  for _, section in ipairs(section_keys) do
    M._write_section(lines, section, data[section], float_keys)
  end

  local content = table.concat(lines, "\n") .. "\n"
  local ok, err = require("neovide.util").write_atomic(path, content)
  if not ok then
    vim.notify("neovide.nvim: failed to write " .. path .. ": " .. tostring(err), vim.log.levels.WARN)
  end
end

function M._write_section(lines, prefix, tbl, float_keys)
  float_keys = float_keys or {}
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
      table.insert(lines, k .. " = " .. M._format_value(tbl[k], float_keys[prefix .. "." .. k]))
    end
    table.insert(lines, "")
  end

  for _, k in ipairs(nested_keys) do
    M._write_section(lines, prefix .. "." .. k, tbl[k], float_keys)
  end
end

-- is_float forces a decimal point on whole numbers ("14" -> "14.0") for keys whose
-- setting is float-typed; a bare integer would change the TOML type and Neovide's
-- Rust-side deserialization rejects an integer where it expects a float.
function M._format_value(v, is_float)
  if type(v) == "boolean" then
    return v and "true" or "false"
  elseif type(v) == "number" then
    if is_float then
      return (v == math.floor(v)) and string.format("%.1f", v) or tostring(v)
    end
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
  local last = keys[#keys]
  -- Skip the whole-file (comment-stripping) rewrite when the on-disk value already
  -- matches. This is what keeps an untouched config.toml intact and stops
  -- apply_saved from rewriting the file on every launch for unchanged toml_* keys.
  if require("neovide.util").deep_equals(node[last], value) then
    return
  end
  node[last] = value
  M.write(nil, data)
end

return M
