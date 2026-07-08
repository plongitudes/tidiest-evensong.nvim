local M = {}

local config = require("evensong.config")
local colors = require("evensong.colors")

function M.setup(opts)
  -- Neovide-only: skip all setup (config, highlights, persistence) in plain Neovim so
  -- loading the plugin there is a genuine no-op.
  if not require("evensong.platform").is_neovide() then
    return
  end
  config.setup(opts)
  colors.setup()
  colors.register_autocmd()
  require("evensong.persistence").apply_saved()
end

function M.open(arg)
  if not require("evensong.platform").is_neovide() then
    vim.notify("evensong: Not running inside Neovide", vim.log.levels.WARN)
    return
  end
  require("evensong.view").open(arg)
end

function M.close()
  require("evensong.view").close()
end

function M.toggle()
  require("evensong.view").toggle()
end

function M.complete(lead)
  local items = { "settings", "profiles", "help" }
  local registry = require("evensong.registry")
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
