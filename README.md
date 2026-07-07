# tidiest-evensong.nvim

An in-editor settings manager for [Neovide](https://neovide.dev/). Browse, tweak, and
persist Neovide's runtime settings from a floating UI inside Neovim — no more hunting
through `vim.g.neovide_*` globals or restarting to see what a value does.

> The plugin exposes the module `neovide` and the `:Evensong` command. Settings are applied
> live where Neovide supports it, persisted to disk, and re-applied (with validation) on
> the next launch.

## Features

- Floating settings UI grouped by category (Display, Animation, Cursor, Window, …).
- Live-apply of runtime settings; changes take effect as you edit.
- Live-preview font picker for `guifont` — browse installed monospace fonts (via
  fontconfig) and see each applied to the editor as you move; `<CR>` keeps it and
  prompts for a point size, `c` drops to free-form input, `<Esc>` restores the original.
- Persistence to `stdpath("data")/neovide.nvim/settings.lua`, re-applied on startup.
- Named profiles you can save and re-apply.
- Reads a subset of settings from Neovide's startup `config.toml`.

## Requirements

- Neovim >= 0.10 (uses `vim.uv`).
- Running inside **Neovide** for settings to actually apply (the UI opens anywhere, but
  `M.setup()` only re-applies persisted settings when `require("neovide.platform").is_neovide()`).
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) — only for running the test suite.

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "plongitudes/tidiest-evensong.nvim",
  main = "neovide",
  opts = {},
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use({
  "plongitudes/tidiest-evensong.nvim",
  config = function()
    require("neovide").setup({})
  end,
})
```

## Configuration

`setup()` is optional — the plugin works with zero config. Defaults shown below:

```lua
require("neovide").setup({
  size = { width = 0.8, height = 0.8 }, -- floating UI size, as a fraction of the editor
  border = "rounded",                   -- any nvim_open_win border style
  backdrop = 60,                        -- dim the backdrop behind the UI (0-100)
  auto_apply = true,                    -- apply changes live as you edit
  data_path = nil,                      -- where settings.lua lives; defaults to
                                        --   stdpath("data") .. "/neovide.nvim"
  settings = {},                        -- your own default overrides, keyed by setting key,
                                        --   e.g. { theme = "dark", opacity = 0.95 }
  -- keys = { ... },                    -- override individual keymaps (see below)
  -- icons = { ... },                   -- override UI glyphs (see below)
})
```

Values in `settings` act as *your* defaults: they are applied on startup and are the
baseline the persistence layer compares against when deciding what to write to disk.

The UI glyphs come from the `icons` table. Top-level keys are `bool_true`, `bool_false`,
`collapsed`, `expanded`, `modified`, `restart`, `settings`, `profiles`, and `help`;
`icons.category` maps each category name (e.g. `Display`, `Cursor`, `"Startup (TOML)"`) to
its header glyph. Override any subset — unset keys keep the Nerd Font defaults, so if you
don't use a patched font you can swap in plain text (e.g. `icons = { modified = "*" }`).

## Usage

```vim
:Evensong            " open the settings UI
:Evensong profiles   " open the profiles view
:Evensong help       " open the help view
:Evensong Window     " open focused on a category (matched by name)
```

Or from Lua: `require("neovide").open()`, `.close()`, `.toggle()`.

### Default keymaps (inside the UI)

| Key            | Action                          |
| -------------- | ------------------------------- |
| `<CR>`         | Activate — fold section · toggle bool · cycle enum · edit value |
| `j` / `k`      | Next / previous setting         |
| `l` / `h`      | Expand / collapse section; on a setting, increment / decrement value |
| `}` / `{`      | Next / previous section (also `]]` / `[[`) |
| `gg` / `G`     | Jump to top / bottom            |
| `r` / `R`      | Reset to your / factory default |
| `a`            | Apply — save changes to disk    |
| `S`            | Save current values as a profile|
| `L` / `?`      | Profiles view / help            |
| `q` / `<Esc>`  | Close & discard unsaved changes |

Most keys are configurable via the `keys` table in `setup()`; the built-in motions
`j`/`k`, `gg`/`G`, and `]]`/`[[` are fixed. `<CR>` is the single
"activate this row" key: it folds a section, toggles a boolean, cycles an enum, or edits
any other value type. The description of the focused setting is shown in the window's
top bar as you move.

Changes **preview live** as you edit, but are only **persisted when you Apply** (`a`).
Closing with `q`/`<Esc>` reverts every change you haven't applied — back to how things
were when you opened the menu (or your last Apply) — so you never have to hunt for each
setting's original value.

## Development

```sh
make test   # run the plenary/busted suite headlessly
stylua .    # format (config in stylua.toml)
```

Tests live in `tests/` and cover the settings registry, value validation, and the
persistence round-trip. CI runs `stylua --check` and the test suite on every push and PR.

## License

[MIT](./LICENSE)
