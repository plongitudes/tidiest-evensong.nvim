local toml = require("neovide.toml")

local function write_file(path, content)
  local f = assert(io.open(path, "w"))
  f:write(content)
  f:close()
end

local function read_file(path)
  local f = assert(io.open(path, "r"))
  local content = f:read("*a")
  f:close()
  return content
end

describe("toml writer", function()
  local tmpdir, config_path

  before_each(function()
    tmpdir = vim.fn.tempname()
    vim.fn.mkdir(tmpdir, "p")
    config_path = tmpdir .. "/config.toml"
    -- config_path() honours NEOVIDE_CONFIG, so point the whole module at our temp file.
    vim.env.NEOVIDE_CONFIG = config_path
  end)

  after_each(function()
    vim.fn.delete(tmpdir, "rf")
    vim.env.NEOVIDE_CONFIG = nil
  end)

  it("keeps a decimal point on a float-typed key (font.size)", function()
    toml.set("font.size", 14.0)
    local content = read_file(config_path)
    assert.is_truthy(content:match("size%s*=%s*14%.0"))
    assert.is_nil(content:match("size%s*=%s*14%f[^%.0-9]"))
  end)

  it("does not rewrite the file when the value is unchanged", function()
    write_file(config_path, "# hand-written note\nvsync = true\n")
    toml.set("vsync", true) -- same value already on disk
    local content = read_file(config_path)
    assert.is_truthy(content:match("# hand%-written note"))
  end)

  it("updates only the value when it changes", function()
    write_file(config_path, "vsync = true\n")
    toml.set("vsync", false)
    assert.are.equal(false, toml.read().vsync)
  end)

  it("strips an unquoted trailing comment from a value", function()
    write_file(config_path, 'frame = "full"  # a note\nsize = 14  # pt\n')
    local data = toml.read()
    assert.are.equal("full", data.frame)
    assert.are.equal(14, data.size)
  end)

  it("keeps a # that is inside a quoted string", function()
    write_file(config_path, 'title = "a # b"\n')
    assert.are.equal("a # b", toml.read().title)
  end)

  it("overwrites a stale line when set to a value that differs from disk", function()
    -- H6: resetting a toml key back to its default must overwrite the stored value,
    -- not be skipped. font.size default is 14.0; disk holds a non-default 18.0.
    write_file(config_path, "[font]\nsize = 18.0\n")
    toml.set("font.size", 14.0)
    assert.are.equal(14.0, toml.read().font.size)
    assert.is_truthy(read_file(config_path):match("size%s*=%s*14%.0"))
  end)
end)
