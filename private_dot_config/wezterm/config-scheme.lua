local wezterm = require("wezterm")

local M = {}

function M.config_scheme(config)
	local scheme_name = "Monokai Pro (Gogh)"
	local scheme = wezterm.get_builtin_color_schemes()[scheme_name]
	local tab_bar_bg = "#474649"
	scheme.background = "#262527"
	scheme.split = "#a7f3d0"
	scheme.tab_bar = {
		background = tab_bar_bg,
		active_tab = {
			bg_color = "#666468",
			fg_color = "white",
			intensity = "Bold",
			italic = false,
			underline = "None",
			strikethrough = false,
		},
		inactive_tab = {
			bg_color = tab_bar_bg,
			fg_color = "#99979b",
			intensity = "Normal",
			italic = false,
			underline = "None",
			strikethrough = false,
		},
		inactive_tab_hover = {
			bg_color = tab_bar_bg,
			fg_color = "#e6e5e6",
			intensity = "Normal",
			italic = true,
			underline = "None",
			strikethrough = false,
		},
	}

	config.color_schemes = { [scheme_name] = scheme }
	config.color_scheme = scheme_name
	config.inactive_pane_hsb = {
		saturation = 0.7,
		brightness = 0.3,
	}
end

return M
