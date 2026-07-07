if vim.g.loaded_neovide_nvim then
  return
end
vim.g.loaded_neovide_nvim = true

vim.api.nvim_create_user_command("Evensong", function(cmd)
  require("neovide").open(cmd.fargs[1])
end, {
  nargs = "?",
  complete = function(lead, line, pos)
    return require("neovide").complete(lead, line, pos)
  end,
  desc = "Open the Neovide settings UI",
})
