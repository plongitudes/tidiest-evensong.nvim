# Reconciling Evensong with a new Neovide release

A runbook for updating the settings registry when Neovide ships new settings. Written for
future maintainers so the process is repeatable with minimal re-discovery. It distills a
source-vs-docs investigation done against Neovide 0.16.0.

## The shape of things

**Neovide has no runtime settings-discovery mechanism.** A running Neovide does *not*
pre-populate `g:neovide_*` with defaults (it only reads the globals the user sets), exposes no
RPC / `:Neovide…` command / function that lists its settings, and its internal registry stores
only a location string + function pointers — no type, default, range, or version is queryable
at runtime. So Evensong's registry (`lua/evensong/registry.lua`, `M.settings`) is and must be
**hand-maintained**. This document is how you maintain it without guessing.

The two globals Neovide *does* set are `g:neovide` and `g:neovide_version` (plus
`g:neovide_channel_id`). We use `g:neovide_version` only for the drift banner, never to
enumerate settings.

## Getting at the truth through source and existing documentation

You need **both** — neither alone is sufficient.

| Fact | Authority | Why |
|---|---|---|
| Variable name (`g:neovide_*`), type, default, which platform a var is *registered* on | **Rust source** | The docs can contain incorrect naming and stale defaults |
| Slider min/max/step, enum choice **strings** + meanings, "Available since 0.x", platform **effect** caveats, deprecation/warning notes | **Docs** (`website/docs/configuration.md`) | None of this exists anywhere in source |

**The docs are not always correct — trust source for names/types/defaults.** Confirmed drift found in
0.16.0: the docs wrote `g:experimental_layer_grouping` (missing the `neovide_` prefix — a dead
variable), and listed stale progress-bar defaults. Trust the `impl Default` block in source.

### Source files to read

Neovide settings are defined by `#[derive(SettingGroup)]` structs with an optional
`#[setting_prefix = "..."]`. The proc-macro maps each field to a global:

```
g:neovide_<setting_prefix>_<field_name>      # prefix present
g:neovide_<field_name>                        # no #[setting_prefix]
```

Defaults come from each struct's hand-written `impl Default`. The structs are spread across
several files — walk **all** of them, not one:

- `neovide-derive/src/lib.rs` — the derive macro / name-mapping rule (read once to trust it)
- `src/renderer/mod.rs` — `RendererSettings` (no prefix)
- `src/renderer/progress_bar.rs` — `ProgressBarSettings` (prefix `progress_bar`)
- `src/renderer/cursor_renderer/mod.rs` — `CursorSettings` (prefix `cursor`)
- `src/window/settings.rs` — `WindowSettings` (no prefix; has `#[cfg(target_os)]`-gated fields)
- `src/settings/config.rs` — `Config`, the TOML/CLI struct (`#[serde(rename_all = "kebab-case")]`,
  all `Option<T>`) → these are the `source = "toml"` entries, startup-only
- `website/docs/configuration.md` — the hand-written docs (ranges, choices, versions, warnings)

Raw fetch pattern (a Claude session can `WebFetch` these; mind GitHub rate limits — fetch a few
at a time):
`https://raw.githubusercontent.com/neovide/neovide/main/<path>`

This is only reflective of the current state of Neovide 0.16.0. Future versions may change, so
be sure to look in new places once in a while to make sure you're not missing something.

## Procedure

1. **Read the derive macro** (`neovide-derive/src/lib.rs`) once to confirm the name-mapping rule
   still holds (`format!("{prefix}{ident}")` wrapped as a `NeovideGlobal`).
2. **Enumerate every `SettingGroup` field** across the source files above. For each, record:
   exact global name (apply the mapping), type, default (from `impl Default`), and any
   `#[cfg(target_os = "...")]` gate.
3. **Diff against `M.settings`.** Three buckets:
   - **In source, not in registry** → candidate to add (but curate — see step 5).
   - **In registry, not in source** → a removed/renamed Neovide setting; fix or drop it.
   - **In both** → check the name and default still match source (catches silent drift like the
     progress-bar names/defaults).
4. **Pull UX metadata from the docs** for anything you're adding or correcting: slider
   `min`/`max`/`step`, the enum's user-facing choice **strings** (lowercase/snake, e.g.
   `do_not_round`) and their order, `restart_required` intent, and platform-*effect* caveats
   (a setting registered on all platforms may only *do* something on one — gate the registry
   entry to where it has effect, as with `show_border` → macOS).
5. **Curate.** Do **not** expose internal/dev/deprecated toggles. Carry forward the exclusion
   list (kept current in the comment block at the top of `registry.lua`). As of 0.16.0:
   excluded — `debug_renderer`, `observed_lines`, `observed_columns`, `mouse_move_event`,
   `iso_layout`, `cursor_hack`, `has_mouse_grid_detection`, deprecated `input_macos_alt_is_meta`;
   deferred — `pixel_geometry` (verify its enum's accepted strings + default before adding, or a
   wrong choice-list will coerce users' real values via `registry.is_valid`).
6. **Add entries** following the existing `EvensongSetting` shape. `source = "runtime"` +
   `var_name = "neovide_..."` for globals; `source = "toml"` + `toml_key` for `Config` fields
   (these get `restart_required = true`). Put each in a sensible `category`; add new categories
   to `M._category_order` if needed. Enum defaults **must** be one of `choices`.
7. **Bump the pin.** Set `M.built_against` in `registry.lua` to the Neovide version you
   reconciled against. That is the entire drift-banner update — `lua/evensong/version.lua`
   compares it to the running `g:neovide_version` and the header renders green/yellow/neutral
   automatically. No other banner code changes.

   The banner compares **major.minor only**, so you do not need to bump the pin for a patch
   release. You may still bump it to a patch you've *verified*, which is cheap — a patch
   release rarely touches settings, and a file-list diff proves it in one command:

   ```bash
   gh api repos/neovide/neovide/compare/<old>...<new> --jq '.files[].filename'
   ```

   If none of the source files listed above appear, no setting changed and the mirror holds.
   (This is how `0.16.0` was carried forward to `0.16.2`: 29 files changed, but
   `src/window/settings.rs` and `src/settings/config.rs` were untouched, and the sole
   `configuration.md` edit was a wording fix.)
8. **Update `CHANGELOG.md`** — a new section noting the Neovide version, what was added/fixed,
   and refreshed exclusion/deferral/known-drift notes.
9. **Verify** (see below).

## Gotchas worth remembering

- **Name mapping, not docs, for `var_name`.** Derive the global from the field + prefix; only
  cross-check against docs. Docs have shipped at least one wrong name.
- **`#[cfg]` = where registered, not where it works.** For the registry's `platform` field, gate
  to where the setting has *effect* (docs), which can differ from the `#[cfg]` (source).
- **Incorrect enum `choices` are dangerous, not cosmetic.** `registry.is_valid` coerces any value
  not in `choices` to the default (`read_value`, `coerce_value`), so a bad choice-list silently
  overwrites a user's real Neovide value. Verify enum strings against source's `from_value` /
  serde renames before adding. When unsure, defer the setting (like `pixel_geometry`).
- **Incorrect defaults are lower-risk.** A default only surfaces for display when the global is
  unset; it isn't written to `vim.g` unless the user edits/saves. Still, match source.
- **`restart_required` isn't in source.** Only a coarse proxy exists: runtime `SettingGroup`
  globals are live; `Config` (TOML/CLI) fields are startup-only. Author the flag from that split.

## Verification

- `make test` — unit suite (plenary/busted). Add/extend `tests/version_spec.lua` if you touch
  version logic and `tests/registry_spec.lua` to lock any newly-corrected names/platforms.
- Manual, **inside real Neovide** (the plugin no-ops elsewhere — `init.lua` guards on
  `platform.is_neovide()`):
  1. `:Evensong` → banner is green "in sync" when `built_against` matches your Neovide.
  2. `:lua vim.g.neovide_version = "99.0.0"` then reopen → yellow drift caution;
     `:lua vim.g.neovide_version = nil` → neutral "version unknown".
  3. For each **added/fixed** setting, change it with `auto_apply` on and confirm the effect is
    real in Neovide — this is the only way to catch a wrong `var_name`.
