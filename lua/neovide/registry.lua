local platform = require("neovide.platform")

local M = {}

---@class NeovideSetting
---@field key string
---@field display_name string
---@field description string
---@field category string
---@field type "boolean"|"float"|"integer"|"string"|"enum"|"color"|"font"
---@field default any
---@field min? number
---@field max? number
---@field step? number
---@field choices? string[]
---@field source "runtime"|"toml"|"vim_option"
---@field var_name? string
---@field toml_key? string
---@field vim_option? string
---@field platform? "windows"|"macos"|"linux"|nil
---@field nightly? boolean
---@field restart_required? boolean

---@type NeovideSetting[]
M.settings = {
  -- ══════════════════════════════════════════
  -- Display
  -- ══════════════════════════════════════════
  {
    key = "opacity",
    display_name = "Background Opacity",
    description = "Window background opacity (0.0 = transparent, 1.0 = opaque)",
    category = "Display",
    type = "float",
    default = 1.0,
    min = 0.0,
    max = 1.0,
    step = 0.05,
    source = "runtime",
    var_name = "neovide_opacity",
  },
  {
    key = "normal_opacity",
    display_name = "Normal BG Opacity",
    description = "Opacity of the Normal highlight background specifically",
    category = "Display",
    type = "float",
    default = 1.0,
    min = 0.0,
    max = 1.0,
    step = 0.05,
    source = "runtime",
    var_name = "neovide_normal_opacity",
  },
  {
    key = "scale_factor",
    display_name = "Scale Factor",
    description = "Global scale/zoom factor for the Neovide window",
    category = "Display",
    type = "float",
    default = 1.0,
    min = 0.1,
    max = 4.0,
    step = 0.1,
    source = "runtime",
    var_name = "neovide_scale_factor",
  },
  {
    key = "padding_top",
    display_name = "Padding Top",
    description = "Padding in pixels at the top of the window",
    category = "Display",
    type = "integer",
    default = 0,
    min = 0,
    max = 100,
    step = 1,
    source = "runtime",
    var_name = "neovide_padding_top",
  },
  {
    key = "padding_bottom",
    display_name = "Padding Bottom",
    description = "Padding in pixels at the bottom of the window",
    category = "Display",
    type = "integer",
    default = 0,
    min = 0,
    max = 100,
    step = 1,
    source = "runtime",
    var_name = "neovide_padding_bottom",
  },
  {
    key = "padding_left",
    display_name = "Padding Left",
    description = "Padding in pixels at the left of the window",
    category = "Display",
    type = "integer",
    default = 0,
    min = 0,
    max = 100,
    step = 1,
    source = "runtime",
    var_name = "neovide_padding_left",
  },
  {
    key = "padding_right",
    display_name = "Padding Right",
    description = "Padding in pixels at the right of the window",
    category = "Display",
    type = "integer",
    default = 0,
    min = 0,
    max = 100,
    step = 1,
    source = "runtime",
    var_name = "neovide_padding_right",
  },
  {
    key = "text_gamma",
    display_name = "Text Gamma",
    description = "Gamma correction for text rendering",
    category = "Display",
    type = "float",
    default = 0.0,
    min = -1.0,
    max = 1.0,
    step = 0.1,
    source = "runtime",
    var_name = "neovide_text_gamma",
  },
  {
    key = "text_contrast",
    display_name = "Text Contrast",
    description = "Contrast adjustment for text rendering",
    category = "Display",
    type = "float",
    default = 0.5,
    min = 0.0,
    max = 1.0,
    step = 0.05,
    source = "runtime",
    var_name = "neovide_text_contrast",
  },
  {
    key = "title_background_color",
    display_name = "Title Background",
    description = "Background color of the window title bar",
    category = "Display",
    type = "color",
    default = "",
    source = "runtime",
    var_name = "neovide_title_background_color",
  },
  {
    key = "title_text_color",
    display_name = "Title Text",
    description = "Text color of the window title bar",
    category = "Display",
    type = "color",
    default = "",
    source = "runtime",
    var_name = "neovide_title_text_color",
  },
  {
    key = "guifont",
    display_name = "GUI Font",
    description = "Font family and size (e.g. 'JetBrainsMono Nerd Font:h14')",
    category = "Display",
    type = "font",
    default = "",
    source = "vim_option",
    vim_option = "guifont",
  },
  {
    key = "linespace",
    display_name = "Line Spacing",
    description = "Extra pixel spacing between lines",
    category = "Display",
    type = "integer",
    default = 0,
    min = -10,
    max = 50,
    step = 1,
    source = "vim_option",
    vim_option = "linespace",
  },

  -- ══════════════════════════════════════════
  -- Floating Windows
  -- ══════════════════════════════════════════
  {
    key = "floating_blur_amount_x",
    display_name = "Float Blur X",
    description = "Horizontal blur amount for floating windows",
    category = "Floating Windows",
    type = "float",
    default = 10.0,
    min = 0.0,
    max = 100.0,
    step = 1.0,
    source = "runtime",
    var_name = "neovide_floating_blur_amount_x",
  },
  {
    key = "floating_blur_amount_y",
    display_name = "Float Blur Y",
    description = "Vertical blur amount for floating windows",
    category = "Floating Windows",
    type = "float",
    default = 10.0,
    min = 0.0,
    max = 100.0,
    step = 1.0,
    source = "runtime",
    var_name = "neovide_floating_blur_amount_y",
  },
  {
    key = "floating_shadow",
    display_name = "Float Shadow",
    description = "Enable shadow under floating windows",
    category = "Floating Windows",
    type = "boolean",
    default = true,
    source = "runtime",
    var_name = "neovide_floating_shadow",
  },
  {
    key = "floating_z_height",
    display_name = "Float Z Height",
    description = "Z-height of floating windows (affects shadow)",
    category = "Floating Windows",
    type = "float",
    default = 10.0,
    min = 0.0,
    max = 100.0,
    step = 1.0,
    source = "runtime",
    var_name = "neovide_floating_z_height",
  },
  {
    key = "light_angle_degrees",
    display_name = "Light Angle",
    description = "Angle of light source for floating window shadows (degrees)",
    category = "Floating Windows",
    type = "float",
    default = 45.0,
    min = 0.0,
    max = 360.0,
    step = 5.0,
    source = "runtime",
    var_name = "neovide_light_angle_degrees",
  },
  {
    key = "light_radius",
    display_name = "Light Radius",
    description = "Radius of light source for floating window shadows",
    category = "Floating Windows",
    type = "float",
    default = 5.0,
    min = 0.0,
    max = 100.0,
    step = 1.0,
    source = "runtime",
    var_name = "neovide_light_radius",
  },
  {
    key = "floating_corner_radius",
    display_name = "Float Corner Radius",
    description = "Corner radius for floating windows",
    category = "Floating Windows",
    type = "float",
    default = 0.0,
    min = 0.0,
    max = 50.0,
    step = 1.0,
    source = "runtime",
    var_name = "neovide_floating_corner_radius",
  },

  -- ══════════════════════════════════════════
  -- Animation
  -- ══════════════════════════════════════════
  {
    key = "position_animation_length",
    display_name = "Position Anim Length",
    description = "Duration of window position animations (seconds)",
    category = "Animation",
    type = "float",
    default = 0.15,
    min = 0.0,
    max = 1.0,
    step = 0.01,
    source = "runtime",
    var_name = "neovide_position_animation_length",
  },
  {
    key = "scroll_animation_length",
    display_name = "Scroll Anim Length",
    description = "Duration of scroll animations (seconds)",
    category = "Animation",
    type = "float",
    default = 0.3,
    min = 0.0,
    max = 2.0,
    step = 0.05,
    source = "runtime",
    var_name = "neovide_scroll_animation_length",
  },
  {
    key = "scroll_animation_far_lines",
    display_name = "Scroll Far Lines",
    description = "Number of lines considered 'far' for scroll animations",
    category = "Animation",
    type = "integer",
    default = 1,
    min = 0,
    max = 200,
    step = 1,
    source = "runtime",
    var_name = "neovide_scroll_animation_far_lines",
  },

  -- ══════════════════════════════════════════
  -- Cursor
  -- ══════════════════════════════════════════
  {
    key = "cursor_animation_length",
    display_name = "Cursor Anim Length",
    description = "Duration of cursor movement animation (seconds)",
    category = "Cursor",
    type = "float",
    default = 0.06,
    min = 0.0,
    max = 1.0,
    step = 0.01,
    source = "runtime",
    var_name = "neovide_cursor_animation_length",
  },
  {
    key = "cursor_trail_size",
    display_name = "Cursor Trail Size",
    description = "Length of the cursor trail effect",
    category = "Cursor",
    type = "float",
    default = 0.7,
    min = 0.0,
    max = 1.0,
    step = 0.05,
    source = "runtime",
    var_name = "neovide_cursor_trail_size",
  },
  {
    key = "cursor_antialiasing",
    display_name = "Cursor Antialiasing",
    description = "Enable cursor antialiasing",
    category = "Cursor",
    type = "boolean",
    default = true,
    source = "runtime",
    var_name = "neovide_cursor_antialiasing",
  },
  {
    key = "cursor_animate_in_insert_mode",
    display_name = "Animate in Insert",
    description = "Animate cursor movements in insert mode",
    category = "Cursor",
    type = "boolean",
    default = true,
    source = "runtime",
    var_name = "neovide_cursor_animate_in_insert_mode",
  },
  {
    key = "cursor_animate_command_line",
    display_name = "Animate Command Line",
    description = "Animate cursor in command line",
    category = "Cursor",
    type = "boolean",
    default = true,
    source = "runtime",
    var_name = "neovide_cursor_animate_command_line",
  },
  {
    key = "cursor_unfocused_outline_width",
    display_name = "Unfocused Outline",
    description = "Width of cursor outline when window is unfocused",
    category = "Cursor",
    type = "float",
    default = 1.0 / 8.0,
    min = 0.0,
    max = 1.0,
    step = 0.01,
    source = "runtime",
    var_name = "neovide_cursor_unfocused_outline_width",
  },
  {
    key = "cursor_smooth_blink",
    display_name = "Smooth Blink",
    description = "Enable smooth cursor blinking animation",
    category = "Cursor",
    type = "boolean",
    default = false,
    source = "runtime",
    var_name = "neovide_cursor_smooth_blink",
  },

  -- ══════════════════════════════════════════
  -- Cursor VFX
  -- ══════════════════════════════════════════
  {
    key = "cursor_vfx_mode",
    display_name = "VFX Mode",
    description = "Visual effect mode for cursor",
    category = "Cursor VFX",
    type = "enum",
    default = "",
    choices = { "", "railgun", "torpedo", "pixiedust", "sonicboom", "ripple", "wireframe" },
    source = "runtime",
    var_name = "neovide_cursor_vfx_mode",
  },
  {
    key = "cursor_vfx_opacity",
    display_name = "VFX Opacity",
    description = "Opacity of cursor visual effects",
    category = "Cursor VFX",
    type = "float",
    default = 200.0,
    min = 0.0,
    max = 255.0,
    step = 5.0,
    source = "runtime",
    var_name = "neovide_cursor_vfx_opacity",
  },
  {
    key = "cursor_vfx_particle_lifetime",
    display_name = "Particle Lifetime",
    description = "How long VFX particles live (seconds)",
    category = "Cursor VFX",
    type = "float",
    default = 1.2,
    min = 0.0,
    max = 5.0,
    step = 0.1,
    source = "runtime",
    var_name = "neovide_cursor_vfx_particle_lifetime",
  },
  {
    key = "cursor_vfx_particle_density",
    display_name = "Particle Density",
    description = "Density of VFX particles",
    category = "Cursor VFX",
    type = "float",
    default = 7.0,
    min = 0.0,
    max = 50.0,
    step = 1.0,
    source = "runtime",
    var_name = "neovide_cursor_vfx_particle_density",
  },
  {
    key = "cursor_vfx_particle_speed",
    display_name = "Particle Speed",
    description = "Speed of VFX particles",
    category = "Cursor VFX",
    type = "float",
    default = 10.0,
    min = 0.0,
    max = 50.0,
    step = 1.0,
    source = "runtime",
    var_name = "neovide_cursor_vfx_particle_speed",
  },
  {
    key = "cursor_vfx_particle_phase",
    display_name = "Particle Phase",
    description = "Phase of VFX particle animation",
    category = "Cursor VFX",
    type = "float",
    default = 1.5,
    min = 0.0,
    max = 10.0,
    step = 0.1,
    source = "runtime",
    var_name = "neovide_cursor_vfx_particle_phase",
  },
  {
    key = "cursor_vfx_particle_curl",
    display_name = "Particle Curl",
    description = "Curl factor for VFX particles",
    category = "Cursor VFX",
    type = "float",
    default = 1.0,
    min = 0.0,
    max = 10.0,
    step = 0.1,
    source = "runtime",
    var_name = "neovide_cursor_vfx_particle_curl",
  },

  -- ══════════════════════════════════════════
  -- Input
  -- ══════════════════════════════════════════
  {
    key = "hide_mouse_when_typing",
    display_name = "Hide Mouse on Type",
    description = "Automatically hide the mouse cursor while typing",
    category = "Input",
    type = "boolean",
    default = false,
    source = "runtime",
    var_name = "neovide_hide_mouse_when_typing",
  },
  {
    key = "touch_deadzone",
    display_name = "Touch Deadzone",
    description = "Minimum touch movement (pixels) before registering drag",
    category = "Input",
    type = "float",
    default = 6.0,
    min = 0.0,
    max = 50.0,
    step = 1.0,
    source = "runtime",
    var_name = "neovide_touch_deadzone",
  },
  {
    key = "touch_drag_timeout",
    display_name = "Touch Drag Timeout",
    description = "Timeout in seconds for touch drag recognition",
    category = "Input",
    type = "float",
    default = 0.17,
    min = 0.0,
    max = 2.0,
    step = 0.01,
    source = "runtime",
    var_name = "neovide_touch_drag_timeout",
  },
  {
    key = "input_ime",
    display_name = "IME",
    description = "Enable Input Method Editor support",
    category = "Input",
    type = "boolean",
    default = true,
    source = "runtime",
    var_name = "neovide_input_ime",
  },
  {
    key = "input_macos_option_key_is_meta",
    display_name = "macOS Option as Meta",
    description = "Treat macOS Option key as Meta key",
    category = "Input",
    type = "enum",
    default = "none",
    choices = { "none", "only_left", "only_right", "both" },
    source = "runtime",
    var_name = "neovide_input_macos_option_key_is_meta",
    platform = "macos",
  },

  -- ══════════════════════════════════════════
  -- Window
  -- ══════════════════════════════════════════
  {
    key = "fullscreen",
    display_name = "Fullscreen",
    description = "Toggle fullscreen mode",
    category = "Window",
    type = "boolean",
    default = false,
    source = "runtime",
    var_name = "neovide_fullscreen",
  },
  {
    key = "remember_window_size",
    display_name = "Remember Size",
    description = "Remember and restore window size across sessions",
    category = "Window",
    type = "boolean",
    default = true,
    source = "runtime",
    var_name = "neovide_remember_window_size",
  },
  {
    key = "confirm_quit",
    display_name = "Confirm Quit",
    description = "Show confirmation dialog when quitting with unsaved changes",
    category = "Window",
    type = "boolean",
    default = true,
    source = "runtime",
    var_name = "neovide_confirm_quit",
  },
  {
    key = "detach_on_quit",
    display_name = "Detach on Quit",
    description = "Behavior when closing: 'always_quit', 'always_detach', or 'prompt'",
    category = "Window",
    type = "enum",
    default = "always_quit",
    choices = { "always_quit", "always_detach", "prompt" },
    source = "runtime",
    var_name = "neovide_detach_on_quit",
  },
  {
    key = "theme",
    display_name = "Theme",
    description = "Color theme mode: 'auto', 'dark', or 'light'",
    category = "Window",
    type = "enum",
    default = "auto",
    choices = { "auto", "dark", "light", "bg_color" },
    source = "runtime",
    var_name = "neovide_theme",
  },
  {
    key = "window_blurred",
    display_name = "Window Blurred",
    description = "Blur the window background on supported platforms",
    category = "Window",
    type = "boolean",
    default = false,
    source = "runtime",
    var_name = "neovide_window_blurred",
  },
  {
    key = "show_border",
    display_name = "Show Border",
    description = "Show window border",
    category = "Window",
    type = "boolean",
    default = true,
    source = "runtime",
    var_name = "neovide_show_border",
    platform = "windows",
  },
  {
    key = "unlink_border_highlights",
    display_name = "Unlink Border HL",
    description = "Use separate highlight groups for window borders",
    category = "Window",
    type = "boolean",
    default = false,
    source = "runtime",
    var_name = "neovide_unlink_border_highlights",
  },

  -- ══════════════════════════════════════════
  -- Performance
  -- ══════════════════════════════════════════
  {
    key = "refresh_rate",
    display_name = "Refresh Rate",
    description = "Maximum frame rate while active",
    category = "Performance",
    type = "integer",
    default = 60,
    min = 10,
    max = 240,
    step = 10,
    source = "runtime",
    var_name = "neovide_refresh_rate",
  },
  {
    key = "refresh_rate_idle",
    display_name = "Idle Refresh Rate",
    description = "Frame rate when idle (saves power)",
    category = "Performance",
    type = "integer",
    default = 5,
    min = 1,
    max = 60,
    step = 1,
    source = "runtime",
    var_name = "neovide_refresh_rate_idle",
  },
  {
    key = "no_idle",
    display_name = "No Idle",
    description = "Disable idle mode (always render at full refresh rate)",
    category = "Performance",
    type = "boolean",
    default = false,
    source = "runtime",
    var_name = "neovide_no_idle",
  },
  {
    key = "profiler",
    display_name = "Profiler",
    description = "Show the built-in performance profiler overlay",
    category = "Performance",
    type = "boolean",
    default = false,
    source = "runtime",
    var_name = "neovide_profiler",
  },

  -- ══════════════════════════════════════════
  -- Progress Bar (nightly)
  -- ══════════════════════════════════════════
  {
    key = "progress_bar",
    display_name = "Progress Bar",
    description = "Show progress bar for long-running commands",
    category = "Progress Bar",
    type = "boolean",
    default = true,
    source = "runtime",
    var_name = "neovide_progress_bar",
    nightly = true,
  },
  {
    key = "progress_bar_height",
    display_name = "Bar Height",
    description = "Height of the progress bar in pixels",
    category = "Progress Bar",
    type = "integer",
    default = 2,
    min = 1,
    max = 20,
    step = 1,
    source = "runtime",
    var_name = "neovide_progress_bar_height",
    nightly = true,
  },
  {
    key = "progress_bar_speed",
    display_name = "Bar Speed",
    description = "Animation speed of the progress bar",
    category = "Progress Bar",
    type = "float",
    default = 1.0,
    min = 0.1,
    max = 5.0,
    step = 0.1,
    source = "runtime",
    var_name = "neovide_progress_bar_speed",
    nightly = true,
  },
  {
    key = "progress_bar_hide_delay",
    display_name = "Hide Delay",
    description = "Seconds to wait before hiding the progress bar after completion",
    category = "Progress Bar",
    type = "float",
    default = 0.5,
    min = 0.0,
    max = 5.0,
    step = 0.1,
    source = "runtime",
    var_name = "neovide_progress_bar_hide_delay",
    nightly = true,
  },

  -- ══════════════════════════════════════════
  -- Startup (TOML)
  -- ══════════════════════════════════════════
  {
    key = "toml_neovim_bin",
    display_name = "Neovim Binary",
    description = "Path to the neovim binary",
    category = "Startup (TOML)",
    type = "string",
    default = "",
    source = "toml",
    toml_key = "neovim-bin",
    restart_required = true,
  },
  {
    key = "toml_fork",
    display_name = "Fork",
    description = "Fork neovide to background on launch",
    category = "Startup (TOML)",
    type = "boolean",
    default = false,
    source = "toml",
    toml_key = "fork",
    restart_required = true,
  },
  {
    key = "toml_frame",
    display_name = "Frame Style",
    description = "Window frame style: 'full', 'none', 'buttonless', 'transparent'",
    category = "Startup (TOML)",
    type = "enum",
    default = "full",
    choices = { "full", "none", "buttonless", "transparent" },
    source = "toml",
    toml_key = "frame",
    restart_required = true,
  },
  {
    key = "toml_idle",
    display_name = "Idle on Startup",
    description = "Start in idle mode",
    category = "Startup (TOML)",
    type = "boolean",
    default = true,
    source = "toml",
    toml_key = "idle",
    restart_required = true,
  },
  {
    key = "toml_maximized",
    display_name = "Start Maximized",
    description = "Start neovide maximized",
    category = "Startup (TOML)",
    type = "boolean",
    default = false,
    source = "toml",
    toml_key = "maximized",
    restart_required = true,
  },
  {
    key = "toml_vsync",
    display_name = "VSync",
    description = "Enable vertical sync",
    category = "Startup (TOML)",
    type = "boolean",
    default = true,
    source = "toml",
    toml_key = "vsync",
    restart_required = true,
  },
  {
    key = "toml_srgb",
    display_name = "sRGB",
    description = "Use sRGB color space",
    category = "Startup (TOML)",
    type = "boolean",
    default = false,
    source = "toml",
    toml_key = "srgb",
    restart_required = true,
  },
  {
    key = "toml_tabs",
    display_name = "Tabs",
    description = "Enable native tab support",
    category = "Startup (TOML)",
    type = "boolean",
    default = true,
    source = "toml",
    toml_key = "tabs",
    restart_required = true,
  },
  {
    key = "toml_title_hidden",
    display_name = "Title Hidden",
    description = "Hide the window title bar",
    category = "Startup (TOML)",
    type = "boolean",
    default = false,
    source = "toml",
    toml_key = "title-hidden",
    restart_required = true,
  },
  {
    key = "toml_wsl",
    display_name = "WSL",
    description = "Use WSL for the neovim backend",
    category = "Startup (TOML)",
    type = "boolean",
    default = false,
    source = "toml",
    toml_key = "wsl",
    restart_required = true,
    platform = "windows",
  },
  {
    key = "toml_font_normal",
    display_name = "TOML Font",
    description = "Font family and features configured in TOML [font.normal]",
    category = "Startup (TOML)",
    type = "string",
    default = "",
    source = "toml",
    toml_key = "font.normal.family",
    restart_required = true,
  },
  {
    key = "toml_font_size",
    display_name = "TOML Font Size",
    description = "Font size configured in TOML",
    category = "Startup (TOML)",
    type = "float",
    default = 14.0,
    min = 6.0,
    max = 72.0,
    step = 0.5,
    source = "toml",
    toml_key = "font.size",
    restart_required = true,
  },
}

-- Index for fast lookup
M._by_key = {}
M._by_category = {}
M._category_order = {
  "Display",
  "Floating Windows",
  "Animation",
  "Cursor",
  "Cursor VFX",
  "Input",
  "Window",
  "Performance",
  "Progress Bar",
  "Startup (TOML)",
}

local function build_indexes()
  M._by_key = {}
  M._by_category = {}
  for _, s in ipairs(M.settings) do
    M._by_key[s.key] = s
    if not M._by_category[s.category] then
      M._by_category[s.category] = {}
    end
    table.insert(M._by_category[s.category], s)
  end
end

build_indexes()

function M.get(key)
  return M._by_key[key]
end

function M.get_by_category(cat)
  return M._by_category[cat] or {}
end

function M.categories()
  return M._category_order
end

--- Validate a value against a setting's declared type and (for enums) choices.
--- Returns true if the value can be applied/persisted as-is, false otherwise.
--- Used at the persistence/capture boundaries (read_value, persistence.apply_saved,
--- persistence.save) to keep junk (e.g. theme = "" or cursor_vfx_mode = {}) out of vim.g and disk.
---@param setting NeovideSetting
---@param value any
---@return boolean
function M.is_valid(setting, value)
  local t = setting.type
  if t == "enum" then
    return type(value) == "string" and setting.choices ~= nil and vim.tbl_contains(setting.choices, value)
  elseif t == "boolean" then
    return type(value) == "boolean"
  elseif t == "float" or t == "integer" then
    if type(value) ~= "number" then
      return false
    end
    -- Reject out-of-range numbers when the setting declares bounds, so a corrupt
    -- opacity = 999.0 can't reach vim.g / be persisted.
    if setting.min ~= nil and value < setting.min then
      return false
    end
    if setting.max ~= nil and value > setting.max then
      return false
    end
    return true
  elseif t == "string" or t == "color" or t == "font" then
    return type(value) == "string"
  end
  return true -- unconstrained/unknown type: don't block what we don't model
end

--- Set of dotted TOML key paths (e.g. "font.size") whose setting is float-typed.
--- The TOML writer uses this to keep a decimal point on whole numbers, since
--- Neovide's Rust config deserializer rejects a bare integer for an f32 field.
---@return table<string, boolean>
function M.float_toml_keys()
  local set = {}
  for _, setting in ipairs(M.settings) do
    if setting.source == "toml" and setting.type == "float" and setting.toml_key then
      set[setting.toml_key] = true
    end
  end
  return set
end

function M.read_value(setting)
  if setting.source == "runtime" then
    local val = vim.g[setting.var_name]
    if val == nil or not M.is_valid(setting, val) then
      return setting.default
    end
    return val
  elseif setting.source == "vim_option" then
    local ok, val = pcall(function()
      return vim.o[setting.vim_option]
    end)
    if ok and val ~= nil and val ~= "" then
      return val
    end
    return setting.default
  elseif setting.source == "toml" then
    local toml = require("neovide.toml")
    local data = toml.read()
    if data and setting.toml_key then
      local keys = vim.split(setting.toml_key, ".", { plain = true })
      local node = data
      for _, k in ipairs(keys) do
        if type(node) == "table" then
          node = node[k]
        else
          return setting.default
        end
      end
      -- Validate like the runtime branch: an invalid enum/out-of-range number in
      -- config.toml must not flow unvalidated into the UI and back to disk.
      if node ~= nil and M.is_valid(setting, node) then
        return node
      end
    end
    return setting.default
  end
  return setting.default
end

function M.write_value(setting, value)
  if setting.source == "runtime" then
    vim.g[setting.var_name] = value
  elseif setting.source == "vim_option" then
    vim.o[setting.vim_option] = value
  elseif setting.source == "toml" then
    local toml = require("neovide.toml")
    toml.set(setting.toml_key, value)
  end
end

--- Resolve a key to its setting and a validated value, coercing invalid values to
--- the registry default so junk (e.g. theme = "" from a stale/hand-edited profile or
--- settings.lua) can never reach vim.g. When `coerced` (a list) is supplied, the key
--- is appended on coercion so the caller can emit a single aggregated warning.
--- Returns nil for an unknown key.
---@param key string
---@param value any
---@param coerced string[]|nil
---@return NeovideSetting|nil setting, any value, boolean was_coerced
function M.coerce_value(key, value, coerced)
  local setting = M._by_key[key]
  if not setting then
    return nil
  end
  local was_coerced = not M.is_valid(setting, value)
  if was_coerced then
    if coerced then
      table.insert(coerced, key)
    end
    value = setting.default
  end
  return setting, value, was_coerced
end

return M
