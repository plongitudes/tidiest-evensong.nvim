local M = {}

---@class NeovideConfig
M.defaults = {
  size = { width = 0.8, height = 0.8 },
  border = "rounded",
  backdrop = 60,
  auto_apply = true,
  data_path = nil,
  settings = {},
  icons = {
    bool_true = " ",
    bool_false = " ",
    collapsed = " ",
    expanded = " ",
    modified = " ",
    restart = " ",
    settings = " ",
    profiles = " ",
    help = "󰋖 ",
    category = {
      Display = "󰍹 ",
      ["Floating Windows"] = " ",
      Animation = "󰸌 ",
      Cursor = "󰇀 ",
      ["Cursor VFX"] = "󰸳 ",
      Input = "󰌌 ",
      Window = " ",
      Performance = "󰓅 ",
      ["Progress Bar"] = " ",
      ["Startup (TOML)"] = " ",
    },
  },
  keys = {
    close = { "q", "<Esc>" },
    toggle_category = "<CR>",
    increment = "l",
    decrement = "h",
    edit = "e",
    reset = "r",
    reset_factory = "R",
    save_profile = "S",
    profiles_view = "L",
    help_view = "?",
    next_category = "}",
    prev_category = "{",
    apply = "a",
  },
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
  if not M.options.data_path then
    M.options.data_path = vim.fn.stdpath("data") .. "/neovide.nvim"
  end
end

function M.get()
  return M.options
end

return M
