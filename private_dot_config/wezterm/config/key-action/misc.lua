local wezterm = require("wezterm")
local act = wezterm.action

return {
	send_out_width = function(offset)
		return function(gui_window, mux_pane)
			local width = tostring(mux_pane:get_dimensions().cols - offset)
			gui_window:perform_action(act.SendString(width), mux_pane)
		end
	end
}
