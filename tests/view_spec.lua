local config = require("neovide.config")
local view = require("neovide.view")
local registry = require("neovide.registry")
local persistence = require("neovide.persistence")

local function tmpdir()
  local d = vim.fn.tempname()
  vim.fn.mkdir(d, "p")
  return d
end

describe("view explicit-save model", function()
  before_each(function()
    config.setup({ data_path = tmpdir() })
    vim.g.neovide_opacity = nil
  end)

  after_each(function()
    view.close()
    vim.g.neovide_opacity = nil
  end)

  it("applies changes live while the menu is open", function()
    view.open()
    view._set_value(registry.get("opacity"), 0.5)
    assert.are.equal(0.5, vim.g.neovide_opacity)
  end)

  it("reverts unsaved changes on close and persists nothing", function()
    view.open()
    view._set_value(registry.get("opacity"), 0.5)
    view.close()
    assert.are.equal(1.0, vim.g.neovide_opacity) -- back to the baseline default
    assert.is_nil(persistence.load().opacity)
  end)

  it("reverts unsaved changes when reopened rather than adopting them", function()
    view.open()
    view._set_value(registry.get("opacity"), 0.5)
    view.open("Display") -- reopen while dirty (e.g. :Neovide Display)
    assert.are.equal(1.0, vim.g.neovide_opacity) -- preview reverted, not adopted
  end)

  it("persists changes on Apply and keeps them applied", function()
    view.open()
    view._set_value(registry.get("opacity"), 0.5)
    view._save_all()
    view.close()
    assert.are.equal(0.5, persistence.load().opacity)
    assert.are.equal(0.5, vim.g.neovide_opacity)
  end)

  -- L5: Esc at the font-size prompt aborts, like every other input cancel path.
  it("aborts the font change when Esc is pressed at the size prompt", function()
    view.open()
    local called = false
    local orig_set, orig_input = view._set_value, vim.ui.input
    view._set_value = function()
      called = true
    end
    vim.ui.input = function(_, cb)
      cb(nil)
    end -- simulate Esc
    view._prompt_font_size(registry.get("guifont"), "Foo", "12")
    view._set_value, vim.ui.input = orig_set, orig_input
    assert.is_false(called)
  end)

  it("commits family:size when a size is entered at the prompt", function()
    view.open()
    local got
    local orig_set, orig_input = view._set_value, vim.ui.input
    view._set_value = function(_, value)
      got = value
    end
    vim.ui.input = function(_, cb)
      cb("16")
    end
    view._prompt_font_size(registry.get("guifont"), "Foo", "12")
    view._set_value, vim.ui.input = orig_set, orig_input
    assert.are.equal("Foo:h16", got)
  end)
end)

describe("view Apply with a TOML setting", function()
  local toml = require("neovide.toml")
  local config_path

  before_each(function()
    local d = tmpdir()
    config.setup({ data_path = d })
    config_path = d .. "/config.toml"
    vim.env.NEOVIDE_CONFIG = config_path
  end)

  after_each(function()
    view.close()
    vim.env.NEOVIDE_CONFIG = nil
  end)

  -- H6: resetting a toml_* key to its default and pressing Apply must overwrite the
  -- stale non-default line on disk, not silently skip the write.
  it("persists a reset-to-default TOML value on Apply", function()
    local f = assert(io.open(config_path, "w"))
    f:write("[font]\nsize = 18.0\n")
    f:close()

    view.open()
    view._set_value(registry.get("toml_font_size"), 14.0) -- 14.0 is the default
    view._save_all()

    assert.are.equal(14.0, toml.read().font.size)
  end)
end)
