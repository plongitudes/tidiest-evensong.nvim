-- Copyright Epic Games, Inc. All Rights Reserved.
-- CONTAINS AI GENERATED CODE
local M = {}

M.highlights = {
  NeovideNormal = { link = "NormalFloat", default = true },
  NeovideBorder = { link = "FloatBorder", default = true },
  NeovideTitle = { link = "Title", default = true },
  NeovideH1 = { link = "IncSearch", default = true },
  NeovideCategory = { link = "Title", default = true },
  NeovideCategoryIcon = { link = "@punctuation.special", default = true },
  NeovideSettingName = { link = "Identifier", default = true },
  NeovideBoolTrue = { link = "DiagnosticOk", default = true },
  NeovideBoolFalse = { link = "DiagnosticError", default = true },
  NeovideNumberValue = { link = "Number", default = true },
  NeovideStringValue = { link = "@string", default = true },
  NeovideEnumValue = { link = "Constant", default = true },
  NeovideSliderFilled = { link = "Constant", default = true },
  NeovideSliderEmpty = { link = "LineNr", default = true },
  NeovideBadgeRestart = { link = "DiagnosticWarn", default = true },
  NeovideBadgePlatform = { link = "DiagnosticInfo", default = true },
  NeovideBadgeNightly = { link = "DiagnosticHint", default = true },
  NeovideBadgeModified = { link = "DiagnosticWarn", default = true },
  NeovideBadgeUnavailable = { link = "DiagnosticError", default = true },
  NeovideButton = { link = "CursorLine", default = true },
  NeovideButtonActive = { link = "Visual", default = true },
  NeovideKey = { link = "Statement", default = true },
  NeovideDimmed = { link = "Conceal", default = true },
  NeovideProfileName = { link = "Title", default = true },
  NeovideProfileActive = { link = "DiagnosticOk", default = true },
  NeovideBackdrop = { bg = "#000000", default = true },
}

function M.setup()
  for name, hl in pairs(M.highlights) do
    vim.api.nvim_set_hl(0, name, hl)
  end
end

function M.register_autocmd()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("neovide_colors", { clear = true }),
    callback = function()
      M.setup()
    end,
  })
end

return M
