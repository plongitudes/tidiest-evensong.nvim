-- Copyright Epic Games, Inc. All Rights Reserved.
-- CONTAINS AI GENERATED CODE
local M = {}

function M.os()
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    return "windows"
  elseif vim.fn.has("macunix") == 1 then
    return "macos"
  else
    return "linux"
  end
end

function M.is_neovide()
  return vim.g.neovide ~= nil
end

function M.neovide_version()
  return vim.g.neovide_version or "unknown"
end

function M.is_available(setting)
  if setting.platform and setting.platform ~= M.os() then
    return false
  end
  if setting.nightly and not M.is_nightly() then
    return false
  end
  return true
end

function M.is_nightly()
  local version = M.neovide_version()
  if version == "unknown" then
    return false
  end
  return version:match("nightly") ~= nil or version:match("dev") ~= nil
end

function M.unavailable_reason(setting)
  if setting.platform and setting.platform ~= M.os() then
    return setting.platform .. " only"
  end
  if setting.nightly and not M.is_nightly() then
    return "nightly only"
  end
  return nil
end

return M
