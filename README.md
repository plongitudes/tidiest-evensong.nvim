# tidiest-evensong.nvim

An in-editor settings manager for [Neovide](https://neovide.dev/). Browse, tweak, and
persist Neovide's runtime settings from a floating UI inside Neovim — no more hunting
through `vim.g.neovide_*` globals or restarting to see what a value does.

> The plugin exposes the module `neovide` and the `:Neovide` command. Settings are applied
> live where Neovide supports it, persisted to disk, and re-applied (with validation) on
> the next launch.

## Features

- Floating settings UI grouped by category (Display, Animation, Cursor, Window, …).
- Live-apply of runtime settings; changes take effect as you edit.
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
})
```

Values in `settings` act as *your* defaults: they are applied on startup and are the
baseline the persistence layer compares against when deciding what to write to disk.

## Usage

```vim
:Neovide            " open the settings UI
:Neovide profiles   " open the profiles view
:Neovide help       " open the help view
:Neovide Window     " open focused on a category (matched by name)
```

Or from Lua: `require("neovide").open()`, `.close()`, `.toggle()`.

### Default keymaps (inside the UI)

| Key            | Action                          |
| -------------- | ------------------------------- |
| `q` / `<Esc>`  | Close (saves if dirty)          |
| `<CR>`         | Toggle category fold            |
| `l` / `h`      | Increment / decrement value     |
| `e`            | Edit value (free-form input)    |
| `r`            | Reset to your default           |
| `R`            | Reset to factory default        |
| `a`            | Apply (save to disk)            |
| `S`            | Save current values as a profile|
| `L`            | Profiles view                   |
| `}` / `{`      | Next / previous category        |
| `?`            | Help view                       |

All keys are configurable via the `keys` table in `setup()`.

## Development

```sh
make test   # run the plenary/busted suite headlessly
stylua .    # format (config in stylua.toml)
```

Tests live in `tests/` and cover the settings registry, value validation, and the
persistence round-trip. CI runs `stylua --check` and the test suite on every push and PR.

## License

[MIT](./LICENSE)
