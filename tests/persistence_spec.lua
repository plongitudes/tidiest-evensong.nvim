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

  it("returns an empty table instead of throwing on a corrupt settings.lua", function()
    write_file(settings_path, "return {\n") -- truncated / syntax error
    local data
    local ok = pcall(function()
      data = persistence.load()
    end)
    assert.is_true(ok)
    assert.are.same({}, data)
  end)

  it("apply_saved does not throw on a corrupt settings.lua", function()
    write_file(settings_path, "return {\n")
    local ok = pcall(persistence.apply_saved)
    assert.is_true(ok)
  end)

  it("does not report a key as ignored when a later layer supplies a valid value", function()
    -- Layer 2 (user default) is invalid, Layer 3 (saved) is valid: the key ends up
    -- good, so it must not appear in the coerced warning.
    config.setup({ data_path = tmpdir, settings = { theme = "" } })
    write_file(settings_path, 'return { theme = "dark" }\n')
    local warnings = {}
    local orig_notify = vim.notify
    vim.notify = function(msg)
      table.insert(warnings, msg)
    end
    local ok = pcall(persistence.apply_saved)
    vim.notify = orig_notify
    assert.is_true(ok)
    assert.are.equal("dark", vim.g.neovide_theme)
    for _, m in ipairs(warnings) do
      assert.is_nil(m:match("ignored invalid"))
    end
  end)

  it("round-trips a saved value through an atomic write", function()
    persistence.save({ theme = "light" })
    -- The temp file used during the atomic write must not linger.
    assert.are.equal(0, vim.fn.filereadable(settings_path .. ".tmp." .. vim.fn.getpid()))
    assert.are.equal("light", persistence.load().theme)
  end)
end)
