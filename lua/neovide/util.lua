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

-- Returns the debounced function and its uv timer. The caller owns the timer's
-- lifetime: :stop() + :close() it when the debounced work is done, or it leaks a
-- libuv handle per debounce() call (e.g. once per font-picker open).
function M.debounce(fn, ms)
  local timer = vim.uv.new_timer()
  local wrapped = function(...)
    local args = { ... }
    timer:stop()
    timer:start(ms, 0, function()
      timer:stop()
      vim.schedule(function()
        fn(unpack(args))
      end)
    end)
  end
  return wrapped, timer
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

--- Atomically write `content` to `path`: write a sibling temp file, then rename it
--- over the target. Rename is atomic on the same filesystem, so a crash or full disk
--- mid-write can never leave a truncated/empty file (which for config.toml could break
--- Neovide's own startup). Uses vim.uv.fs_rename, which replaces an existing target on
--- Windows too (plain os.rename does not). Ensures the parent directory exists.
---@param path string
---@param content string
---@return boolean ok, string|nil err
function M.write_atomic(path, content)
  M.ensure_dir(vim.fn.fnamemodify(path, ":h"))
  local tmp = path .. ".tmp." .. vim.fn.getpid()
  local f, open_err = io.open(tmp, "w")
  if not f then
    return false, open_err or ("could not open " .. tmp .. " for writing")
  end
  local wrote, write_err = pcall(function()
    assert(f:write(content))
  end)
  f:close()
  if not wrote then
    os.remove(tmp)
    return false, tostring(write_err)
  end
  local renamed, rename_err = vim.uv.fs_rename(tmp, path)
  if not renamed then
    os.remove(tmp)
    return false, rename_err or ("could not rename " .. tmp .. " to " .. path)
  end
  return true
end

function M.tbl_keys_sorted(t)
  local keys = vim.tbl_keys(t)
  table.sort(keys)
  return keys
end

return M
