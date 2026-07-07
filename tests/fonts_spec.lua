local fonts = require("evensong.fonts")

describe("fonts.list", function()
  local list = fonts.list()

  it("returns a non-empty list of strings", function()
    assert.is_true(#list > 0)
    for _, name in ipairs(list) do
      assert.are.equal("string", type(name))
      assert.is_true(#name > 0)
    end
  end)

  it("excludes hidden/internal font names", function()
    for _, name in ipairs(list) do
      assert.are_not.equal(".", name:sub(1, 1))
    end
  end)

  it("is sorted case-insensitively", function()
    for i = 2, #list do
      assert.is_true(list[i - 1]:lower() <= list[i]:lower())
    end
  end)
end)
