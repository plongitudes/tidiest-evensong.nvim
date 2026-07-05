-- Copyright Epic Games, Inc. All Rights Reserved.
-- CONTAINS AI GENERATED CODE
local M = {}

local config = require("neovide.config")
local colors = require("neovide.colors")

function M.setup(opts)
  config.setup(opts)
  colors.setup()
  colors.register_autocmd()

  if require("neovide.platform").is_neovide() then
    require("neovide.persistence").apply_saved()
  end
end

function M.open(arg)
  if not require("neovide.platform").is_neovide() then
    vim.notify("neovide.nvim: Not running inside Neovide", vim.log.levels.WARN)
    return
  end
  require("neovide.view").open(arg)
end

function M.close()
  require("neovide.view").close()
end

function M.toggle()
  require("neovide.view").toggle()
end

function M.complete(lead)
  local items = { "settings", "profiles", "help" }
  local registry = require("neovide.registry")
  for _, cat in ipairs(registry.categories()) do
    table.insert(items, cat)
  end
  if lead and lead ~= "" then
    return vim.tbl_filter(function(item)
      return item:lower():find(lead:lower(), 1, true) == 1
    end, items)
  end
  return items
end

return M
