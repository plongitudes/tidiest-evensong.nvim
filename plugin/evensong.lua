if vim.g.loaded_evensong then
  return
end
vim.g.loaded_evensong = true

-- Evensong is Neovide-only. In plain Neovim there is nothing to configure, so bail
-- before registering the command — the plugin leaves no footprint outside Neovide.
if vim.g.neovide == nil then
  return
end

vim.api.nvim_create_user_command("Evensong", function(cmd)
  require("evensong").open(cmd.fargs[1])
end, {
  nargs = "?",
  complete = function(lead, line, pos)
    return require("evensong").complete(lead, line, pos)
  end,
  desc = "Open the Neovide settings UI",
})
