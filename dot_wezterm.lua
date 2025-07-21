-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()
local mux = wezterm.mux
local act = wezterm.action
-- This is where you actually apply your config choices

config.color_scheme = "Tokyo Night Moon"
config.font = wezterm.font("Hack Nerd Font Mono")
config.font_size = 12

--Keep tab bar available
config.enable_tab_bar = true

-- Static window size
config.initial_cols = 120
config.initial_rows = 50

-- Enables titlebar and border. This is default.. 
config.window_decorations = "TITLE | RESIZE"
config.window_background_opacity = 0.8
config.macos_window_background_blur = 10

-- my coolnight colorscheme:
config.colors = {
	foreground = "#CBE0F0",
	background = "#011423",
	cursor_bg = "#47FF9C",
	cursor_border = "#47FF9C",
	cursor_fg = "#011423",
	selection_bg = "#033259",
	selection_fg = "#CBE0F0",
	ansi = { "#214969", "#E52E2E", "#44FFB1", "#FFE073", "#0FC5ED", "#a277ff", "#24EAF7", "#24EAF7" },
	brights = { "#214969", "#E52E2E", "#44FFB1", "#FFE073", "#A277FF", "#a277ff", "#24EAF7", "#24EAF7" },
}

-- Change background Wallpaper
config.background = {
  {
    source = {
      File = "/home/miker/Documents/wallpapers/backiee-288178-landscape.jpg",
    },
    -- Optional: adjust how the image is displayed
    hsb = { brightness = 0.1 }, -- Dim the image so text is readable
    width = "100%",
    height = "100%",
  },
}

--Configure Hotkeys
config.disable_default_key_bindings = true
config.keys = {
	{ key = 'R', mods = 'SHIFT|CTRL', action = act.ReloadConfiguration },
	{ key = '+', mods = 'CTRL', action = act.IncreaseFontSize },
	{ key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
	{ key = '0', mods = 'CTRL', action = act.ResetFontSize },
	{ key = 'c', mods = 'CTRL', action = act.CopyTo 'Clipboard' },
	{ key = 'N', mods = 'CTRL', action = act.SpawnWindow },
	{ key = 'U', mods = 'CTRL', action = act.CharSelect{ copy_on_select = true, copy_to =  'ClipboardAndPrimarySelection' } },
	{ key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard' },
	{ key = 'f', mods = 'CTRL', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
	{ key = 'd', mods = 'CTRL', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
	{ key = 't', mods = 'CTRL', action = act.CloseCurrentTab{ confirm = false } },
	{ key = 'q', mods = 'CTRL', action = act.CloseCurrentPane{ confirm = false} },
	{ key = 'r', mods = 'LEADER', action = act.ActivateKeyTable { name = 'resize_pane', one_shot = false } },
}

-- and finally, return the configuration to wezterm
return config
