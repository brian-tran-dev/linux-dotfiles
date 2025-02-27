local wezterm = require("wezterm")
local act = wezterm.action
local keybinding = require("core.keybinding")

return {
	enter = function(gui_window, mux_pane)
		gui_window:perform_action(act.ActivateCopyMode, mux_pane)
		keybinding.set_pane_scroll(mux_pane)
	end,

	exit = function(gui_window, mux_pane)
		gui_window:perform_action(
			act.Multiple({
				act.CopyMode("ClearPattern"),
				act.CopyMode("AcceptPattern"),
				act.CopyMode("ClearSelectionMode"),
				act.CopyMode("Close"),
				act.ScrollToBottom,
			}),
			mux_pane
		)
		keybinding.set_pane_default(mux_pane)
	end,
}
