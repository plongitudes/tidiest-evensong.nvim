local M = {}

M.highlights = {
  EvensongNormal = { link = "NormalFloat", default = true },
  EvensongBorder = { link = "FloatBorder", default = true },
  EvensongTitle = { link = "Title", default = true },
  EvensongH1 = { link = "IncSearch", default = true },
  EvensongCategory = { link = "Title", default = true },
  EvensongCategoryIcon = { link = "@punctuation.special", default = true },
  EvensongSettingName = { link = "Identifier", default = true },
  EvensongBoolTrue = { link = "DiagnosticOk", default = true },
  EvensongBoolFalse = { link = "DiagnosticError", default = true },
  EvensongNumberValue = { link = "Number", default = true },
  EvensongStringValue = { link = "@string", default = true },
  EvensongEnumValue = { link = "Constant", default = true },
  EvensongSliderFilled = { link = "Constant", default = true },
  EvensongSliderEmpty = { link = "LineNr", default = true },
  EvensongBadgeRestart = { link = "DiagnosticWarn", default = true },
  EvensongBadgePlatform = { link = "DiagnosticInfo", default = true },
  EvensongBadgeNightly = { link = "DiagnosticHint", default = true },
  EvensongBadgeModified = { link = "DiagnosticWarn", default = true },
  EvensongBadgeUnavailable = { link = "DiagnosticError", default = true },
  EvensongButton = { link = "CursorLine", default = true },
  EvensongButtonActive = { link = "Visual", default = true },
  EvensongKey = { link = "Statement", default = true },
  EvensongDimmed = { link = "Conceal", default = true },
  EvensongProfileName = { link = "Title", default = true },
  EvensongProfileActive = { link = "DiagnosticOk", default = true },
  EvensongBackdrop = { bg = "#000000", default = true },
}

function M.setup()
  for name, hl in pairs(M.highlights) do
    vim.api.nvim_set_hl(0, name, hl)
  end
end

function M.register_autocmd()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("evensong_colors", { clear = true }),
    callback = function()
      M.setup()
    end,
  })
end

return M
