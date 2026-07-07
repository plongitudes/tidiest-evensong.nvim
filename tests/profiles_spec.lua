local config = require("evensong.config")
local profiles = require("evensong.profiles")

local function write_file(path, content)
  local f = assert(io.open(path, "w"))
  f:write(content)
  f:close()
end

describe("profiles with an invalid stored value", function()
  local tmpdir, profiles_dir

  before_each(function()
    tmpdir = vim.fn.tempname()
    vim.fn.mkdir(tmpdir, "p")
    profiles_dir = tmpdir .. "/profiles"
    vim.fn.mkdir(profiles_dir, "p")
    config.setup({ data_path = tmpdir })
    vim.g.neovide_theme = nil
    vim.g.neovide_cursor_vfx_mode = nil
  end)

  after_each(function()
    vim.fn.delete(tmpdir, "rf")
    vim.g.neovide_theme = nil
    vim.g.neovide_cursor_vfx_mode = nil
  end)

  it("coerces an invalid profile value to its default on apply", function()
    -- A profile hand-edited or written before validation existed.
    write_file(profiles_dir .. "/bad.lua", 'return { name = "bad", settings = { theme = "", cursor_vfx_mode = {} } }\n')
    local profile = profiles.load("bad")
    assert.is_not_nil(profile)
    profiles.apply(profile)
    assert.are.equal("auto", vim.g.neovide_theme)
  end)

  it("does not bake an invalid value into a saved profile", function()
    profiles.save("test", { theme = "", cursor_vfx_mode = {} }, "desc")
    local profile = profiles.load("test")
    assert.is_not_nil(profile)
    assert.is_nil(profile.settings.theme)
    assert.is_nil(profile.settings.cursor_vfx_mode)
  end)

  it("still stores a valid non-toml value in a saved profile", function()
    profiles.save("test", { theme = "dark" }, "desc")
    local profile = profiles.load("test")
    assert.are.equal("dark", profile.settings.theme)
  end)
end)
