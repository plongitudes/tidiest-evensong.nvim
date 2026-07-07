local config = require("neovide.config")
local font_picker = require("neovide.font_picker")

describe("font_picker restore-on-close", function()
  before_each(function()
    config.setup({})
    vim.o.guifont = "OriginalFont:h12"
  end)

  after_each(function()
    -- Make sure no picker window is left open between tests.
    pcall(function()
      if vim.bo.filetype == "neovide" then
        vim.cmd("close")
      end
    end)
    vim.o.guifont = ""
  end)

  it("previews a font on open, then restores guifont when closed directly", function()
    font_picker.open({ size = "12" })
    -- Opening previews the (pre)selected font live, so guifont changes...
    assert.are_not.equal("OriginalFont:h12", vim.o.guifont)
    -- ...and closing by any means other than a keymap must restore it (H5).
    vim.cmd("close")
    assert.are.equal("OriginalFont:h12", vim.o.guifont)
  end)

  it("survives repeated open/close cycles without leaking or erroring", function()
    for _ = 1, 3 do
      font_picker.open({ size = "12" })
      local ok = pcall(function()
        vim.cmd("close")
      end)
      assert.is_true(ok)
      assert.are.equal("OriginalFont:h12", vim.o.guifont)
    end
  end)
end)
