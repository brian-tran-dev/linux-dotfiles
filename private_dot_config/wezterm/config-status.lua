local wezterm = require("wezterm")
local strftime = wezterm.strftime
local format = wezterm.format
local icon = wezterm.nerdfonts

local keybindings_core = require("core-keybinding")
local on_event = wezterm.on

return {
	config_status = function(config)
		config.status_update_interval = 200

		on_event("update-right-status", function(gui_window)
			local date = strftime("%a,%d/%m,%H:%M:%S")
			local mode = keybindings_core.fn_pane_mode(gui_window:active_pane())

			local solid_left = utf8.char(0xe0b2)

			local bg_colors = { "#6b6b80", "#606073", "#555566" }
			local fg_colors = { "#FFFFFF", "#FFFFFF", "#FFFFFF" }

			if mode == "scroll" then
				bg_colors[1] = "#f1fa8c"
				fg_colors[1] = "#2a2e32"
			end

			-- Make it italic and underlined
			gui_window:set_right_status(format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { Color = bg_colors[1] } },
				{ Text = solid_left },
				{ Background = { Color = bg_colors[1] } },
				{ Foreground = { Color = fg_colors[1] } },
				{ Text = " " .. mode .. " " },
				{ Foreground = { Color = bg_colors[2] } },
				{ Text = solid_left },
				{ Background = { Color = bg_colors[2] } },
				{ Foreground = { Color = fg_colors[2] } },
				{ Text = " " .. icon.cod_calendar .. " " .. date .. " " },
			}))
		end)
	end,
}
