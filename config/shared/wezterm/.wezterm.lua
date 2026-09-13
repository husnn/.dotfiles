local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.color_scheme = "Catppuccin Mocha"
-- config.color_scheme = "Tokyo Night"

config.font = wezterm.font("JetBrains Mono", { weight = "DemiBold" })
config.font_size = 14

config.enable_tab_bar = false

config.window_decorations = "RESIZE"

config.keys = {
  {key="Enter", mods="SHIFT", action=wezterm.action{SendString="\x1b\r"}},
}

return config
