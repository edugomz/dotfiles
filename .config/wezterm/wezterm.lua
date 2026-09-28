local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- config.font = wezterm.font("CaskaydiaMono Nerd Font")

config.color_scheme = 'Bamboo'
config.enable_tab_bar = false

config.keys = {
	{
		key = "Enter",
		mods = "SHIFT",
		action = wezterm.action.SendString("\x1b\r"),
	},
}

config.enable_wayland = false  -- restores old X11 behavior, Mutter draws the frame again

return config
