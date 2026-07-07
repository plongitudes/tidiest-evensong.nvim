local config = require("neovide.config")
local State = require("neovide.state")

describe("state dirty tracking", function()
  local tmpdir

  before_each(function()
    tmpdir = vim.fn.tempname()
    vim.fn.mkdir(tmpdir, "p")
    config.setup({ data_path = tmpdir })
    -- Isolate from any real config.toml the registry might read during State.new().
    vim.env.NEOVIDE_CONFIG = tmpdir .. "/config.toml"
  end)

  after_each(function()
    vim.fn.delete(tmpdir, "rf")
    vim.env.NEOVIDE_CONFIG = nil
  end)

  -- L2: mark_clean must deepcopy so the baseline can't alias a table-valued setting.
  it("mark_clean stores a deep copy of the value, not an alias", function()
    local s = State.new()
    local tbl = { a = 1 }
    s.setting_values["k"] = tbl
    s:mark_clean("k")
    assert.are_not.equal(tbl, s.saved_values["k"]) -- distinct reference
    assert.are.same(tbl, s.saved_values["k"]) -- equal contents
    tbl.a = 2
    assert.are.equal(1, s.saved_values["k"].a) -- baseline unaffected by later mutation
  end)
end)
