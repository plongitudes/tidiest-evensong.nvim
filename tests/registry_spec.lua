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
