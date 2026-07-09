local version = require("evensong.version")
local registry = require("evensong.registry")

describe("version.plugin", function()
  it("is a parseable semver", function()
    assert.is_not_nil(version.parse(version.plugin))
  end)
end)

describe("version.parse", function()
  it("parses a plain semver", function()
    assert.are.same({ 0, 16, 0 }, version.parse("0.16.0"))
  end)

  it("tolerates a leading v", function()
    assert.are.same({ 0, 17, 0 }, version.parse("v0.17.0"))
  end)

  it("ignores a pre-release / build suffix", function()
    assert.are.same({ 0, 16, 0 }, version.parse("0.16.0-nightly-abc123"))
  end)

  it("defaults a missing patch to 0", function()
    assert.are.same({ 0, 16, 0 }, version.parse("0.16"))
  end)

  it("returns nil for junk or nil", function()
    assert.is_nil(version.parse("unknown"))
    assert.is_nil(version.parse("not-a-version"))
    assert.is_nil(version.parse(nil))
  end)
end)

describe("version.compare", function()
  it("orders by major, then minor, then patch", function()
    assert.are.equal(0, version.compare({ 0, 16, 0 }, { 0, 16, 0 }))
    assert.are.equal(-1, version.compare({ 0, 15, 9 }, { 0, 16, 0 }))
    assert.are.equal(1, version.compare({ 0, 17, 0 }, { 0, 16, 0 }))
    assert.are.equal(-1, version.compare({ 0, 16, 1 }, { 0, 16, 2 }))
    assert.are.equal(1, version.compare({ 1, 0, 0 }, { 0, 99, 99 }))
  end)
end)

describe("version.status", function()
  after_each(function()
    vim.g.neovide_version = nil
  end)

  it("reports synced when the running Neovide matches built_against", function()
    vim.g.neovide_version = registry.built_against
    assert.are.equal("synced", version.status().state)
  end)

  it("reports synced when the running Neovide is older", function()
    vim.g.neovide_version = "0.10.0"
    assert.are.equal("synced", version.status().state)
  end)

  it("reports drift when the running Neovide is newer", function()
    vim.g.neovide_version = "0.99.0"
    local s = version.status()
    assert.are.equal("drift", s.state)
    assert.are.equal("0.99.0", s.running)
    assert.are.equal(registry.built_against, s.built)
  end)

  it("ignores patch bumps -- settings land in minor releases, so a patch is not drift", function()
    local built = version.parse(registry.built_against)
    vim.g.neovide_version = ("%d.%d.99"):format(built[1], built[2])
    assert.are.equal("synced", version.status().state)
  end)

  it("still reports drift on a minor bump", function()
    local built = version.parse(registry.built_against)
    vim.g.neovide_version = ("%d.%d.0"):format(built[1], built[2] + 1)
    assert.are.equal("drift", version.status().state)
  end)

  it("reports unknown when the running version is absent or unparseable", function()
    vim.g.neovide_version = nil
    assert.are.equal("unknown", version.status().state)
    vim.g.neovide_version = "garbage"
    assert.are.equal("unknown", version.status().state)
  end)
end)
