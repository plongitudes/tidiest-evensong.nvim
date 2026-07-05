local config = require("neovide.config")
local persistence = require("neovide.persistence")

local function write_file(path, content)
  local f = assert(io.open(path, "w"))
  f:write(content)
  f:close()
end

local function read_file(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local content = f:read("*a")
  f:close()
  return content
end

describe("persistence with a dirty state file", function()
  local tmpdir, settings_path

  before_each(function()
    tmpdir = vim.fn.tempname()
    vim.fn.mkdir(tmpdir, "p")
    settings_path = tmpdir .. "/settings.lua"
    config.setup({ data_path = tmpdir })
    vim.g.neovide_theme = nil
    vim.g.neovide_cursor_vfx_mode = nil
  end)

  after_each(function()
    vim.fn.delete(tmpdir, "rf")
    vim.g.neovide_theme = nil
    vim.g.neovide_cursor_vfx_mode = nil
  end)

  it("coerces an invalid persisted theme to its default on apply", function()
    write_file(settings_path, 'return { theme = "", cursor_vfx_mode = {} }\n')
    persistence.apply_saved()
    assert.are.equal("auto", vim.g.neovide_theme)
  end)

  it("does not persist an invalid value on save", function()
    persistence.save({ theme = "", cursor_vfx_mode = {} })
    local saved = persistence.load()
    assert.is_nil(saved.theme)
    assert.is_nil(saved.cursor_vfx_mode)
  end)

  it("still persists a valid non-default value on save", function()
    persistence.save({ theme = "dark" })
    local saved = persistence.load()
    assert.are.equal("dark", saved.theme)
  end)
end)
