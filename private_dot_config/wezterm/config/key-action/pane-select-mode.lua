local wezterm = require("wezterm")
local act = wezterm.action
local keybinding = require("core.keybinding")

return {
	enter = function(select_mode)
		return function(gui_window, mux_pane)
			gui_window:perform_action(act.CopyMode({ SetSelectionMode = select_mode }), mux_pane)
			keybinding.set_pane_select(mux_pane)
		end
	end,

	exit = function(gui_window, mux_pane)
		gui_window:perform_action(act.CopyMode("ClearSelectionMode"), mux_pane)
		keybinding.set_pane_scroll(mux_pane)
	end,

	copy_selection = function(gui_window, mux_pane)
		gui_window:perform_action(
			act.Multiple({
				act.CopyTo("Clipboard"),
				act.CopyMode("ClearSelectionMode"),
			}),
			mux_pane
		)
		keybinding.set_pane_scroll(mux_pane)
	end,
}
