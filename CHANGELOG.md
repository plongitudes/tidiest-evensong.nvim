# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

Because Evensong mirrors Neovide's settings, each entry notes the **Neovide version the
settings registry was reconciled against** (`registry.built_against`). See
[`doc/reconciling-neovide.md`](doc/reconciling-neovide.md) for the process used to keep the
registry in step with new Neovide releases.

## [Unreleased]

## [0.1.0] - 2026-07-08

Settings registry reconciled against **Neovide 0.16.0**.

### Added

- **Version-drift banner** in the UI header. The settings list is hand-maintained and pinned
  to a Neovide release (Neovide exposes no way to discover its settings at runtime), so the
  header now compares your running Neovide to `registry.built_against` and shows: green
  ("in sync") when they match or your Neovide is older, yellow ("drift") when your Neovide is
  newer and may have settings not listed yet, and a neutral banner when the version is unknown.
- `evensong.version` module — semver parse/compare and drift `status()`.
- `registry.built_against` — the Neovide version the registry mirrors (currently `0.16.0`).
- Eight settings that current Neovide exposes but Evensong did not list:
  `underline_stroke_scale`, `cursor_short_animation_length`, `cursor_cell_color_fallback`,
  `cursor_vfx_particle_highlight_lifetime`, `message_area_drag_selection`,
  `remember_window_position`, `macos_simple_fullscreen` (macOS), `highlight_matching_pair`
  (macOS), and `corner_preference` (Windows).
- Highlight groups `EvensongVersionSynced` and `EvensongVersionDrift`, and a Help-view legend
  entry explaining the banner.
- Tests: `tests/version_spec.lua`, plus a regression block in `tests/registry_spec.lua`
  locking the corrected variable names and platform gating.

### Fixed

- **Progress bar toggle did nothing.** It wrote to `g:neovide_progress_bar`, which Neovide
  ignores; the real global is `g:neovide_progress_bar_enabled`.
- **Progress bar speed did nothing.** It wrote to `g:neovide_progress_bar_speed`; the real
  global is `g:neovide_progress_bar_animation_speed`. Its default (`1.0` → `100.0`) and range
  were corrected to match Neovide.
- **Progress bar height** default corrected (`2` → `3`) to match Neovide's default.
- **`show_border`** was gated to Windows and therefore hidden on macOS, where it is actually
  the platform the setting affects; it is now gated to macOS.
- Removed the `nightly` flag from the four progress-bar settings — they shipped in stable
  Neovide 0.16.0 and were being hidden on stable builds.

### Notes

- Deliberately **not** exposed (internal/dev/deprecated in Neovide's source):
  `debug_renderer`, `observed_lines`, `observed_columns`, `mouse_move_event`, `iso_layout`,
  `cursor_hack`, `has_mouse_grid_detection`, and the deprecated `input_macos_alt_is_meta`.
- **Deferred:** `pixel_geometry` — its enum's exact accepted strings and default were not
  verified against source, and shipping a wrong choice-list would coerce a user's real value.
- **Known default drifts left unchanged** (to avoid altering established behavior; review at the
  next reconciliation): `floating_blur_amount_x`/`_y` (Neovide default `2.0`),
  `cursor_animation_length` (`0.150`), `cursor_vfx_particle_lifetime` (`0.5`).
