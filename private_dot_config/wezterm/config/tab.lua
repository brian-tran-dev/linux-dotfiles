local wezterm = require("wezterm")
local on_event = wezterm.on
local tab = require("core.tab")

return {
	config = function(config)
		config.enable_tab_bar = true
		config.show_close_tab_button_in_tabs = false
		config.show_new_tab_button_in_tab_bar = false
		config.use_fancy_tab_bar = false
		config.tab_max_width = 200

		on_event("window-config-reloaded", function(gui_window, _)
			local active_tab = gui_window:active_tab()
			local tab_id = active_tab:tab_id()
			if tab.not_marked(tab_id) then
				active_tab:set_title(" ")
				tab.mark(tab_id)
			end
		end)
	end,
}
