-- Neovide version comparison for the drift banner.
--
-- The registry (evensong.registry) is a hand-maintained mirror of Neovide's settings, pinned to
-- a specific Neovide release via registry.built_against. There is no way to discover Neovide's
-- settings at runtime, so instead of silently drifting we compare the running Neovide against the
-- version we were built against and surface the result in the UI header:
--   * synced  — running Neovide is the same or older; every setting we list is accounted for.
--   * drift   — running Neovide is NEWER; it may expose settings this plugin doesn't know about.
--   * unknown — running version couldn't be determined; stay neutral, never cry wolf.
--
-- Comparison is on major.minor only: Neovide ships new settings in minor releases, so a patch
-- bump is not drift.

local platform = require("evensong.platform")
local registry = require("evensong.registry")

local M = {}

--- Evensong's own version. Pairs with registry.built_against, the Neovide release whose
--- settings this version's registry mirrors.
M.plugin = "0.1.0"

--- Parse a Neovide version string into numeric components. Tolerates a leading "v" and any
--- pre-release/build suffix (e.g. "0.16.0-nightly-abc" -> {0, 16, 0}). Returns nil if no
--- major.minor could be read.
---@param v string|nil
---@return integer[]|nil
function M.parse(v)
  if type(v) ~= "string" then
    return nil
  end
  local major, minor, patch = v:match("^v?(%d+)%.(%d+)%.?(%d*)")
  if not major then
    return nil
  end
  return { tonumber(major), tonumber(minor), tonumber(patch) or 0 }
end

--- Compare two parsed version tuples. Returns -1 if a < b, 0 if equal, 1 if a > b.
---@param a integer[]
---@param b integer[]
---@return integer
function M.compare(a, b)
  for i = 1, 3 do
    local x, y = a[i] or 0, b[i] or 0
    if x < y then
      return -1
    elseif x > y then
      return 1
    end
  end
  return 0
end

--- Drift status of the running Neovide relative to the registry's built-against version.
---@return { state: "synced"|"drift"|"unknown", running: string, built: string }
function M.status()
  local running = platform.neovide_version()
  local built = registry.built_against
  local rv, bv = M.parse(running), M.parse(built)

  if not rv or not bv then
    return { state = "unknown", running = running, built = built }
  end

  -- Compare on major.minor only. Neovide introduces settings in minor releases; patch releases
  -- are bugfixes. Counting a patch bump as drift would cry wolf on every 0.x.N.
  local running_minor = { rv[1], rv[2], 0 }
  local built_minor = { bv[1], bv[2], 0 }

  -- Running newer than what we mirror => there may be settings we don't expose yet.
  local state = M.compare(running_minor, built_minor) > 0 and "drift" or "synced"
  return { state = state, running = running, built = built }
end

return M
