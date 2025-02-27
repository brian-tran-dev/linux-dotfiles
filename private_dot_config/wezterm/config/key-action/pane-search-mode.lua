local wezterm = require("wezterm")
local act = wezterm.action
local keybinding = require("core.keybinding")

return {
	enter = function(gui_window, mux_pane)
		gui_window:perform_action(act.Search({ Regex = "" }), mux_pane)
		keybinding.set_pane_search(mux_pane)
	end,

	exit = function(gui_window, mux_pane)
		gui_window:perform_action(
			act.Multiple({
				act.CopyMode("ClearPattern"),
				act.CopyMode("AcceptPattern"),
				act.CopyMode("ClearSelectionMode"),
			}),
			mux_pane
		)
		keybinding.set_pane_scroll(mux_pane)
	end,

	accept_pattern = function(gui_window, mux_pane)
		gui_window:perform_action(
			act.Multiple({
				act.CopyMode("AcceptPattern"),
				act.CopyMode("MoveToSelectionOtherEnd"),
				act.CopyMode("ClearSelectionMode"),
			}),
			mux_pane
		)
		keybinding.set_pane_scroll(mux_pane)
	end,
}
