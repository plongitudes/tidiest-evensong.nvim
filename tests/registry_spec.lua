local registry = require("neovide.registry")

describe("registry.is_valid", function()
  local theme = registry.get("theme")
  local vfx = registry.get("cursor_vfx_mode")
  local opacity = registry.get("opacity")
  local blurred = registry.get("window_blurred")

  it("accepts a listed enum choice", function()
    assert.is_true(registry.is_valid(theme, "dark"))
    assert.is_true(registry.is_valid(theme, "auto"))
  end)

  it("rejects an enum value that is not a listed choice", function()
    -- The bug: "" is not one of theme's choices.
    assert.is_false(registry.is_valid(theme, ""))
    assert.is_false(registry.is_valid(theme, "purple"))
  end)

  it("rejects a non-string value for an enum (type mismatch)", function()
    -- The sibling bug: cursor_vfx_mode = {} (a table, not a string choice).
    assert.is_false(registry.is_valid(vfx, {}))
  end)

  it("accepts the empty string only where it is a real choice", function()
    -- cursor_vfx_mode's default IS "", and "" is in its choices, so it is valid there.
    assert.is_true(registry.is_valid(vfx, ""))
  end)

  it("checks numeric and boolean types", function()
    assert.is_true(registry.is_valid(opacity, 0.95))
    assert.is_false(registry.is_valid(opacity, "0.95"))
    assert.is_true(registry.is_valid(blurred, true))
    assert.is_false(registry.is_valid(blurred, "yes"))
  end)

  it("range-checks numbers against declared min/max", function()
    -- opacity is bounded 0.0..1.0; boundaries are valid, outside is not.
    assert.is_true(registry.is_valid(opacity, 0.0))
    assert.is_true(registry.is_valid(opacity, 1.0))
    assert.is_false(registry.is_valid(opacity, 999.0))
    assert.is_false(registry.is_valid(opacity, -0.5))
  end)
end)

describe("registry theme choices", function()
  it("includes bg_color (Neovide supports it)", function()
    local theme = registry.get("theme")
    assert.is_true(vim.tbl_contains(theme.choices, "bg_color"))
  end)
end)

describe("registry.read_value capture", function()
  local theme = registry.get("theme")
  local vfx = registry.get("cursor_vfx_mode")

  after_each(function()
    vim.g[theme.var_name] = nil
    vim.g[vfx.var_name] = nil
  end)

  it("falls back to default when vim.g holds an invalid enum value", function()
    vim.g[theme.var_name] = ""
    assert.are.equal("auto", registry.read_value(theme))
  end)

  it("falls back to default when vim.g holds a type-mismatched value", function()
    vim.g[vfx.var_name] = {}
    assert.are.equal("", registry.read_value(vfx))
  end)

  it("returns a valid value unchanged", function()
    vim.g[theme.var_name] = "dark"
    assert.are.equal("dark", registry.read_value(theme))
  end)
end)

describe("registry.read_value from TOML", function()
  local frame = registry.get("toml_frame")
  local size = registry.get("toml_font_size")
  local tmpdir, config_path

  local function write(content)
    local f = assert(io.open(config_path, "w"))
    f:write(content)
    f:close()
  end

  before_each(function()
    tmpdir = vim.fn.tempname()
    vim.fn.mkdir(tmpdir, "p")
    config_path = tmpdir .. "/config.toml"
    vim.env.NEOVIDE_CONFIG = config_path
  end)

  after_each(function()
    vim.fn.delete(tmpdir, "rf")
    vim.env.NEOVIDE_CONFIG = nil
  end)

  it("falls back to default on an invalid enum in config.toml", function()
    write('frame = "bogus"\n')
    assert.are.equal("full", registry.read_value(frame))
  end)

  it("returns a valid enum from config.toml unchanged", function()
    write('frame = "none"\n')
    assert.are.equal("none", registry.read_value(frame))
  end)

  it("falls back to default on an out-of-range number in config.toml", function()
    write("[font]\nsize = 999.0\n")
    assert.are.equal(14.0, registry.read_value(size))
  end)
end)
