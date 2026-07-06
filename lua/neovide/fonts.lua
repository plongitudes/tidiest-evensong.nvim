local M = {}

-- Curated fallback of popular programming fonts, used when the system has no font
-- enumeration tool (fontconfig) available — e.g. a bare Windows/macOS install.
local FALLBACK = {
  "Cascadia Code",
  "FantasqueSansM Nerd Font",
  "Fira Code",
  "Hack Nerd Font",
  "Inconsolata",
  "IosevkaTerm Nerd Font",
  "JetBrainsMono Nerd Font",
  "Menlo",
  "Monaco",
  "SF Mono",
  "Source Code Pro",
  "Ubuntu Mono",
}

-- Enumerate installed font families via fontconfig (fc-list) for a given match
-- pattern. Returns a sorted list of unique family names, or nil if unusable.
local function query(pattern)
  if vim.fn.executable("fc-list") == 0 then
    return nil
  end
  local out = vim.fn.systemlist({ "fc-list", pattern, "family" })
  if vim.v.shell_error ~= 0 or type(out) ~= "table" then
    return nil
  end
  local set = {}
  for _, line in ipairs(out) do
    -- A line may list the family plus comma-separated style/locale aliases;
    -- keep only the primary (first) name.
    local name = vim.trim(vim.split(line, ",", { plain = true })[1] or "")
    -- Skip empties and hidden/internal fonts (macOS names them ".Foo").
    if name ~= "" and name:sub(1, 1) ~= "." then
      set[name] = true
    end
  end
  if vim.tbl_isempty(set) then
    return nil
  end
  local names = vim.tbl_keys(set)
  table.sort(names, function(a, b)
    return a:lower() < b:lower()
  end)
  return names
end

--- Return a sorted list of available font family names.
--- Prefers monospace families (what a code editor wants); falls back to all
--- installed families, then to a curated list when fontconfig is unavailable.
function M.list()
  return query(":spacing=100") or query(":") or FALLBACK
end

return M
