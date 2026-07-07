-- Minimal init for running the plenary/busted test suite headlessly.
-- Puts this plugin and plenary.nvim on the runtimepath.

vim.opt.runtimepath:prepend(vim.fn.getcwd())

-- Discover plenary from common install locations so the harness is portable.
-- Derive the data dir from stdpath so this also resolves on Windows (AppData),
-- not just the Linux/macOS ~/.local/share layout.
local data = vim.fn.stdpath("data")
local candidates = {
  data .. "/lazy/plenary.nvim",
  data .. "/site/pack/*/start/plenary.nvim",
  data .. "/site/pack/*/opt/plenary.nvim",
}
for _, pattern in ipairs(candidates) do
  for _, path in ipairs(vim.fn.glob(pattern, true, true)) do
    if vim.fn.isdirectory(path) == 1 then
      vim.opt.runtimepath:append(path)
    end
  end
end

vim.cmd("runtime plugin/plenary.vim")
