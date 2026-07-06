local Float = require("neovide.float")
local fonts = require("neovide.fonts")
local util = require("neovide.util")

local M = {}

-- Live-preview font family picker. Opens a floating list of installed fonts; as the
-- cursor moves, that font is applied to the editor (guifont) so it previews in place.
-- The original guifont is ALWAYS restored when the picker closes — final application
-- is left to the caller's on_choose (via the normal set-value path), so the result
-- still respects auto_apply and dirty tracking.
--
--   opts.current_family  string?      preselect this family
--   opts.size            string?      current size (e.g. "14"); builds the preview
--   opts.on_choose       fun(family)  called with the chosen family
--   opts.on_custom       fun()?       called if the user wants free-form input instead
function M.open(opts)
  opts = opts or {}
  local list = fonts.list()
  if #list == 0 then
    vim.notify("neovide.nvim: no fonts found to pick from", vim.log.levels.WARN)
    return
  end

  local original_guifont = vim.o.guifont
  local size = opts.size
  local on_choose = opts.on_choose or function() end
  local done = false

  local function apply_preview(family)
    if done or not family then
      return
    end
    vim.o.guifont = (size and size ~= "") and (family .. ":h" .. size) or family
  end
  -- Debounced so holding j/k doesn't thrash Neovide's font engine.
  local preview = util.debounce(apply_preview, 40)

  local float = Float.new({ title = " Select Font ", backdrop = false })
  float:open()
  local buf, win = float.buf, float.win

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, list)
  vim.bo[buf].modifiable = false
  vim.wo[win].winbar = "  j/k preview · <CR> keep · c custom · q/<Esc> cancel"

  local augroup = vim.api.nvim_create_augroup("neovide_font_picker", { clear = true })

  -- Tear down, restore the original font, then run the follow-up action. Restoring
  -- unconditionally keeps preview side effects from leaking; on_choose re-applies.
  local function finish(action)
    if done then
      return
    end
    done = true
    pcall(vim.api.nvim_clear_autocmds, { group = augroup })
    vim.o.guifont = original_guifont
    if float:is_open() then
      float:close()
    end
    action()
  end

  vim.api.nvim_create_autocmd("CursorMoved", {
    group = augroup,
    buffer = buf,
    callback = function()
      preview(list[vim.api.nvim_win_get_cursor(win)[1]])
    end,
  })

  float:on_key({ "<CR>" }, function()
    local family = list[vim.api.nvim_win_get_cursor(win)[1]]
    finish(function()
      if family then
        on_choose(family)
      end
    end)
  end, "Choose font")

  float:on_key({ "q", "<Esc>" }, function()
    finish(function() end)
  end, "Cancel font picker")

  if opts.on_custom then
    float:on_key({ "c" }, function()
      finish(opts.on_custom)
    end, "Custom guifont")
  end

  -- Preselect the current family and prime the preview immediately (undebounced).
  local start_idx = 1
  for i, name in ipairs(list) do
    if name == opts.current_family then
      start_idx = i
      break
    end
  end
  vim.api.nvim_win_set_cursor(win, { start_idx, 0 })
  apply_preview(list[start_idx])
end

return M
