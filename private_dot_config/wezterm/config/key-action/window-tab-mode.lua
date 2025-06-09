local wezterm = require("wezterm")
local act = wezterm.action
local tab = require("core.tab")

return {
	set_name = function(gui_window, input_name)
		if input_name == nil then return end

		local active_tab = gui_window:active_tab()
		local tab_id = active_tab:tab_id()
		local new_name = nil
		if string.len(input_name) > 0 then
			new_name = input_name
		else
			new_name = nil
		end
		active_tab:set_title(new_name)
		tab.mark(tab_id)
	end,

	new = function(gui_window, mux_pane)
		gui_window:perform_action(act.SpawnTab("CurrentPaneDomain"), mux_pane)
		local active_tab = gui_window:active_tab()
		active_tab:set_title(" ")
		tab.mark(active_tab:tab_id())
	end
}
