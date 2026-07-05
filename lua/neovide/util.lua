-- Copyright Epic Games, Inc. All Rights Reserved.
-- CONTAINS AI GENERATED CODE
local M = {}

function M.clamp(value, min, max)
  if value < min then
    return min
  end
  if value > max then
    return max
  end
  return value
end

function M.round(value, decimals)
  decimals = decimals or 0
  local mult = 10 ^ decimals
  return math.floor(value * mult + 0.5) / mult
end

function M.throttle(fn, ms)
  local timer = vim.uv.new_timer()
  local running = false
  return function(...)
    if running then
      return
    end
    running = true
    fn(...)
    timer:start(ms, 0, function()
      running = false
    end)
  end
end

function M.debounce(fn, ms)
  local timer = vim.uv.new_timer()
  return function(...)
    local args = { ... }
    timer:stop()
    timer:start(ms, 0, function()
      timer:stop()
      vim.schedule(function()
        fn(unpack(args))
      end)
    end)
  end
end

function M.deep_equals(a, b)
  if type(a) ~= type(b) then
    return false
  end
  if type(a) ~= "table" then
    return a == b
  end
  for k, v in pairs(a) do
    if not M.deep_equals(v, b[k]) then
      return false
    end
  end
  for k in pairs(b) do
    if a[k] == nil then
      return false
    end
  end
  return true
end

function M.ensure_dir(path)
  if vim.fn.isdirectory(path) == 0 then
    vim.fn.mkdir(path, "p")
  end
end

function M.tbl_keys_sorted(t)
  local keys = vim.tbl_keys(t)
  table.sort(keys)
  return keys
end

return M
