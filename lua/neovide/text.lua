-- Copyright Epic Games, Inc. All Rights Reserved.
-- CONTAINS AI GENERATED CODE
local M = {}
M.__index = M

M.ns = vim.api.nvim_create_namespace("neovide.nvim")

function M.new()
  local self = setmetatable({}, M)
  self.lines = { {} }
  return self
end

function M:append(str, hl)
  local current = self.lines[#self.lines]
  table.insert(current, { str = str, hl = hl })
  return self
end

function M:nl()
  table.insert(self.lines, {})
  return self
end

function M:padding(n)
  n = n or 1
  for _ = 1, n do
    self:nl()
  end
  return self
end

function M:render(buf)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  vim.bo[buf].modifiable = true

  -- Build plain text lines
  local text_lines = {}
  for _, segments in ipairs(self.lines) do
    local line = ""
    for _, seg in ipairs(segments) do
      line = line .. seg.str
    end
    table.insert(text_lines, line)
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, text_lines)

  -- Clear previous extmarks
  vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)

  -- Apply highlights via extmarks
  for i, segments in ipairs(self.lines) do
    local col = 0
    for _, seg in ipairs(segments) do
      if seg.hl then
        local end_col = col + #seg.str
        vim.api.nvim_buf_set_extmark(buf, M.ns, i - 1, col, {
          end_col = end_col,
          hl_group = seg.hl,
        })
      end
      col = col + #seg.str
    end
  end

  vim.bo[buf].modifiable = false
end

return M
