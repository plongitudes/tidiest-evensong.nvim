-- Copyright Epic Games, Inc. All Rights Reserved.
-- CONTAINS AI GENERATED CODE
local config = require("neovide.config")

local M = {}
M.__index = M

function M.new(opts)
  local self = setmetatable({}, M)
  self.opts = opts or {}
  self.win = nil
  self.buf = nil
  self.backdrop_win = nil
  self.backdrop_buf = nil
  self.augroup = vim.api.nvim_create_augroup("neovide_float", { clear = true })
  return self
end

function M:open()
  if self.win and vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_set_current_win(self.win)
    return
  end

  local cfg = config.get()

  -- Create main buffer
  self.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[self.buf].buftype = "nofile"
  vim.bo[self.buf].bufhidden = "wipe"
  vim.bo[self.buf].swapfile = false
  vim.bo[self.buf].filetype = "neovide"

  -- Calculate dimensions
  local win_config = self:_win_config()

  -- Create backdrop
  self:_create_backdrop(win_config)

  -- Create main window
  self.win = vim.api.nvim_open_win(self.buf, true, win_config)

  vim.wo[self.win].winhighlight = "Normal:NeovideNormal,FloatBorder:NeovideBorder"
  vim.wo[self.win].cursorline = true
  vim.wo[self.win].wrap = false
  vim.wo[self.win].signcolumn = "no"
  vim.wo[self.win].number = false
  vim.wo[self.win].relativenumber = false
  vim.wo[self.win].spell = false
  vim.wo[self.win].list = false
  vim.wo[self.win].conceallevel = 3
  vim.wo[self.win].concealcursor = "nvic"

  -- Resize handler
  vim.api.nvim_create_autocmd("VimResized", {
    group = self.augroup,
    callback = function()
      if self.win and vim.api.nvim_win_is_valid(self.win) then
        local new_config = self:_win_config()
        vim.api.nvim_win_set_config(self.win, new_config)
        self:_update_backdrop(new_config)
      end
    end,
  })

  -- Cleanup on close
  vim.api.nvim_create_autocmd("WinClosed", {
    group = self.augroup,
    pattern = tostring(self.win),
    once = true,
    callback = function()
      self:close()
    end,
  })
end

function M:_win_config()
  local cfg = config.get()
  local editor_width = vim.o.columns
  local editor_height = vim.o.lines - vim.o.cmdheight

  local width = math.floor(editor_width * cfg.size.width)
  local height = math.floor(editor_height * cfg.size.height)
  local col = math.floor((editor_width - width) / 2)
  local row = math.floor((editor_height - height) / 2)

  return {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = cfg.border,
    zindex = 50,
    title = " Neovide Settings ",
    title_pos = "center",
  }
end

function M:_create_backdrop(win_config)
  local cfg = config.get()
  if cfg.backdrop <= 0 then
    return
  end

  self.backdrop_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[self.backdrop_buf].buftype = "nofile"

  self.backdrop_win = vim.api.nvim_open_win(self.backdrop_buf, false, {
    relative = "editor",
    width = vim.o.columns,
    height = vim.o.lines,
    col = 0,
    row = 0,
    style = "minimal",
    focusable = false,
    zindex = 49,
  })

  vim.wo[self.backdrop_win].winhighlight = "Normal:NeovideBackdrop"
  vim.wo[self.backdrop_win].winblend = cfg.backdrop
end

function M:_update_backdrop(win_config)
  if self.backdrop_win and vim.api.nvim_win_is_valid(self.backdrop_win) then
    vim.api.nvim_win_set_config(self.backdrop_win, {
      relative = "editor",
      width = vim.o.columns,
      height = vim.o.lines,
      col = 0,
      row = 0,
    })
  end
end

function M:close()
  if self.backdrop_win and vim.api.nvim_win_is_valid(self.backdrop_win) then
    vim.api.nvim_win_close(self.backdrop_win, true)
    self.backdrop_win = nil
  end
  if self.win and vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_close(self.win, true)
    self.win = nil
  end
  vim.api.nvim_clear_autocmds({ group = self.augroup })
  self.buf = nil
end

function M:is_open()
  return self.win ~= nil and vim.api.nvim_win_is_valid(self.win)
end

function M:on_key(key, fn, desc)
  if not self.buf then
    return
  end
  local keys = type(key) == "table" and key or { key }
  for _, k in ipairs(keys) do
    vim.keymap.set("n", k, fn, {
      buffer = self.buf,
      nowait = true,
      desc = desc,
      silent = true,
    })
  end
end

return M
