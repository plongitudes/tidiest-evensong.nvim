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

  it("persists changes on Apply and keeps them applied", function()
    view.open()
    view._set_value(registry.get("opacity"), 0.5)
    view._save_all()
    view.close()
    assert.are.equal(0.5, persistence.load().opacity)
    assert.are.equal(0.5, vim.g.neovide_opacity)
  end)
end)
