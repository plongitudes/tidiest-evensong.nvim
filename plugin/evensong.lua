if vim.g.loaded_evensong then
  return
end
vim.g.loaded_evensong = true

vim.api.nvim_create_user_command("Evensong", function(cmd)
  require("evensong").open(cmd.fargs[1])
end, {
  nargs = "?",
  complete = function(lead, line, pos)
    return require("evensong").complete(lead, line, pos)
  end,
  desc = "Open the Neovide settings UI",
})
