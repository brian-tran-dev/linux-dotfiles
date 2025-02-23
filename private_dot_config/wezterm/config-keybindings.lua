local wezterm = require("wezterm")
local act = wezterm.action
local act_cb = wezterm.action_callback
local on_event = wezterm.on
-- local log = wezterm.log_info

local core = require("core-keybinding")
local utils = require("utils")

local M = {}

local function adjust_window_border(is_full_screen, gui_window)
	local local_config = gui_window:get_config_overrides() or {}
	if is_full_screen then
		local_config.window_frame = utils.fullscreen_window_frame()
	else
		local_config.window_frame = utils.shrunk_window_frame()
	end
	local_config.keys = gui_window:effective_config().keys
	gui_window:set_config_overrides(local_config)
end

local function toggle_fullscreen(gui_window, _)
	local is_fullscreen = gui_window:get_dimensions().is_full_screen
	adjust_window_border(not is_fullscreen, gui_window)
	gui_window:toggle_fullscreen()
end

local function enter_scroll_mode(gui_window, mux_pane)
	gui_window:perform_action(act.ActivateCopyMode, mux_pane)
	-- log("Activated")
	core.fn_pane_mode(mux_pane, core.SCROLL)
end

local function exit_scroll_mode(gui_window, mux_pane)
	gui_window:perform_action(act.Multiple {
		act.CopyMode "ClearPattern",
		act.CopyMode "AcceptPattern",
		act.CopyMode "ClearSelectionMode",
		act.CopyMode "Close",
		act.ScrollToBottom,
	}, mux_pane)
	core.fn_pane_mode(mux_pane, core.DEFAULT)
end

local function enter_select_mode(select_mode)
	return function(gui_window, mux_pane)
		gui_window:perform_action(
			act.CopyMode { SetSelectionMode =  select_mode },
			mux_pane
		)
		core.fn_pane_mode(mux_pane, core.SELECT)
	end
end

local function exit_select_mode(gui_window, mux_pane)
	gui_window:perform_action(act.CopyMode 'ClearSelectionMode', mux_pane)
	core.fn_pane_mode(mux_pane, core.SCROLL)
end

local function copy_selection(gui_window, mux_pane)
	gui_window:perform_action(act.Multiple {
		act.CopyTo "Clipboard",
		act.CopyMode "ClearSelectionMode",
	}, mux_pane)
	core.fn_pane_mode(mux_pane, core.SCROLL) end local function enter_search_mode(gui_window, mux_pane)
	gui_window:perform_action(
		act.Search { Regex = '' },
		mux_pane
	)
	core.fn_pane_mode(mux_pane, core.SEARCH)
end

local function exit_search_mode(gui_window, mux_pane)
	gui_window:perform_action(act.Multiple {
		act.CopyMode 'ClearPattern',
		act.CopyMode 'AcceptPattern',
		act.CopyMode 'ClearSelectionMode',
	}, mux_pane)
	core.fn_pane_mode(mux_pane, core.SCROLL)
end

local function accept_pattern(gui_window, mux_pane)
	gui_window:perform_action(act.Multiple {
		act.CopyMode 'AcceptPattern',
		act.CopyMode 'MoveToSelectionOtherEnd',
		act.CopyMode 'ClearSelectionMode',
	}, mux_pane)
	core.fn_pane_mode(mux_pane, core.SCROLL)
end

local tab_names = {}
local is_tab_title_set = {}
local function update_tab_name(gui_window, _, input_name)
	local active_tab = gui_window:active_tab()
	local tab_id = active_tab:tab_id()
	local prev_name = tab_names[tab_id]
	local new_name = nil
	if string.len(input_name) > 0 then
		new_name = input_name
	else
		new_name = nil
	end
	tab_names[tab_id] = new_name
	if prev_name ~= new_name then
		active_tab:set_title(new_name)
		is_tab_title_set[tab_id] = true
	end
end

local function send_out_width(offset)
	return function(gui_window, mux_pane)
		local width = tostring(mux_pane:get_dimensions().cols - offset)
		-- log("Pane Width: ", width)
		gui_window:perform_action(act.SendString(width), mux_pane)
	end
end

local function new_tab(gui_window, mux_pane)
	gui_window:perform_action(act.SpawnTab "CurrentPaneDomain", mux_pane)
	local active_tab = gui_window:active_tab()
	active_tab:set_title(" ")
	is_tab_title_set[active_tab:tab_id()] = true
end
on_event("window-config-reloaded", function (gui_window, _)
	local active_tab = gui_window:active_tab()
	local tab_id = active_tab:tab_id()
	if is_tab_title_set[tab_id] == nil then
		active_tab:set_title(" ")
		is_tab_title_set[tab_id] = true
	end
end)

core.cbind(core.DEFAULT, "NONE", "F11", act_cb(toggle_fullscreen))
core.cbind(core.DEFAULT, "CTRL", "q", act.QuitApplication)
---- Split Pane ------------------
core.cbind(core.DEFAULT, "LEADER|CTRL", "j", act.SplitPane { direction = 'Down', size = { Percent = 50 } } )
core.cbind(core.DEFAULT, "LEADER|CTRL", "k", act.SplitPane { direction = 'Up', size = { Percent = 50 } } )
core.cbind(core.DEFAULT, "LEADER|CTRL", "h", act.SplitPane { direction = 'Left', size = { Percent = 50 } } )
core.cbind(core.DEFAULT, "LEADER|CTRL", "l", act.SplitPane { direction = 'Right', size = { Percent = 50 } } )
---- Resize Pane ----------------
core.cbind(core.DEFAULT, "LEADER|SHIFT", "j", act.AdjustPaneSize { 'Down', 2 })
core.cbind(core.DEFAULT, "LEADER|SHIFT", "k", act.AdjustPaneSize { 'Up', 2 })
core.cbind(core.DEFAULT, "LEADER|SHIFT", "h", act.AdjustPaneSize { 'Left', 5 })
core.cbind(core.DEFAULT, "LEADER|SHIFT", "l", act.AdjustPaneSize { 'Right', 5 })
---- Navigate Pane ----------------
core.cbind(core.DEFAULT, "CTRL", "j", act.ActivatePaneDirection("Down"))
core.cbind(core.DEFAULT, "CTRL", "k", act.ActivatePaneDirection("Up"))
core.cbind(core.DEFAULT, "CTRL", "h", act.ActivatePaneDirection("Left"))
core.cbind(core.DEFAULT, "CTRL", "l", act.ActivatePaneDirection("Right"))
----- Close Pane -------------------
core.cbind(core.DEFAULT, "CTRL", "d", act.CloseCurrentPane { confirm = false })
------ Tab Operator ----------------
core.cbind(core.DEFAULT, "CTRL", "w", act.CloseCurrentTab { confirm = false })
core.cbind(core.DEFAULT, "ALT", "n", act_cb(new_tab))
core.cbind(core.DEFAULT, "ALT", "h", act.ActivateTabRelative(-1))
core.cbind(core.DEFAULT, "ALT", "l", act.ActivateTabRelative(1))
core.cbind(core.DEFAULT, "LEADER|ALT", "h", act.MoveTabRelative(-1))
core.cbind(core.DEFAULT, "LEADER|ALT", "l", act.MoveTabRelative(1))
core.cbind(core.DEFAULT, "ALT", "/", act.ShowTabNavigator)
core.cbind(core.DEFAULT, "ALT", "u", act.PromptInputLine {
	description = "current tab name?",
	action = act_cb(update_tab_name),
})
core.cbind(core.DEFAULT, "ALT", "1", act.ActivateTab(0))
core.cbind(core.DEFAULT, "ALT", "2", act.ActivateTab(1))
core.cbind(core.DEFAULT, "ALT", "3", act.ActivateTab(2))
core.cbind(core.DEFAULT, "ALT", "4", act.ActivateTab(3))
core.cbind(core.DEFAULT, "ALT", "5", act.ActivateTab(4))
core.cbind(core.DEFAULT, "ALT", "6", act.ActivateTab(5))
core.cbind(core.DEFAULT, "ALT", "7", act.ActivateTab(6))
core.cbind(core.DEFAULT, "ALT", "8", act.ActivateTab(7))
core.cbind(core.DEFAULT, "ALT", "9", act.ActivateTab(8))
------- Pane Specific Mode -----------------------------
core.cbind(core.DEFAULT, "LEADER", "[", act_cb(enter_scroll_mode))
core.cbind(core.SCROLL, "NONE", "Escape", act_cb(exit_scroll_mode))
core.cbind(core.SCROLL, "NONE", "q", act_cb(exit_scroll_mode))

core.cbind(core.SCROLL, "NONE", "v", act_cb(enter_select_mode('Cell')))
core.cbind(core.SCROLL, "NONE", "V", act_cb(enter_select_mode('Line')))
core.cbind(core.SCROLL, "CTRL", "v", act_cb(enter_select_mode('Block')))
core.cbind(core.SELECT, "NONE", "Escape", act_cb(exit_select_mode))
core.cbind(core.SELECT, "NONE", "q", act_cb(exit_select_mode))

core.cbind(core.SCROLL, "NONE", "w", act.CopyMode 'MoveForwardWord')
core.cbind(core.SCROLL, "NONE", "e", act.CopyMode 'MoveForwardWordEnd')
core.cbind(core.SCROLL, "NONE", "b", act.CopyMode 'MoveBackwardWord')
core.cbind(core.SCROLL, "SHIFT", "$", act.CopyMode 'MoveToEndOfLineContent')
core.cbind(core.SCROLL, "NONE", "0", act.CopyMode 'MoveToStartOfLine')
core.cbind(core.SCROLL, "NONE", "j", act.CopyMode 'MoveDown')
core.cbind(core.SCROLL, "NONE", "k", act.CopyMode 'MoveUp')
core.cbind(core.SCROLL, "NONE", "h", act.CopyMode 'MoveLeft')
core.cbind(core.SCROLL, "NONE", "l", act.CopyMode 'MoveRight')
core.cbind(core.SCROLL, "SHIFT", "%", act.CopyMode 'MoveToSelectionOtherEnd')
core.cbind(core.SCROLL, "SHIFT", "{", act.CopyMode 'MoveToScrollbackTop')
core.cbind(core.SCROLL, "SHIFT", "}", act.CopyMode 'MoveToScrollbackBottom')

core.cbind(core.SELECT, "NONE", "w", act.CopyMode 'MoveForwardWord')
core.cbind(core.SELECT, "NONE", "e", act.CopyMode 'MoveForwardWordEnd')
core.cbind(core.SELECT, "NONE", "b", act.CopyMode 'MoveBackwardWord')
core.cbind(core.SELECT, "SHIFT", "$", act.CopyMode 'MoveToEndOfLineContent')
core.cbind(core.SELECT, "NONE", "0", act.CopyMode 'MoveToStartOfLine')
core.cbind(core.SELECT, "NONE", "j", act.CopyMode 'MoveDown')
core.cbind(core.SELECT, "NONE", "k", act.CopyMode 'MoveUp')
core.cbind(core.SELECT, "NONE", "h", act.CopyMode 'MoveLeft')
core.cbind(core.SELECT, "NONE", "l", act.CopyMode 'MoveRight')
core.cbind(core.SELECT, "SHIFT", "%", act.CopyMode 'MoveToSelectionOtherEnd')
core.cbind(core.SELECT, "SHIFT", "{", act.CopyMode 'MoveToScrollbackTop')
core.cbind(core.SELECT, "SHIFT", "}", act.CopyMode 'MoveToScrollbackBottom')

core.cbind(core.SELECT, "NONE", "v", act_cb(enter_select_mode('Cell')))
core.cbind(core.SELECT, "NONE", "V", act_cb(enter_select_mode('Line')))
core.cbind(core.SELECT, "CTRL", "v", act_cb(enter_select_mode('Block')))
core.cbind(core.SELECT, "NONE", "y", act_cb(copy_selection))


core.cbind(core.SCROLL, "NONE", "/", act_cb(enter_search_mode))
core.cbind(core.SELECT, "NONE", "/", act_cb(enter_search_mode))
core.cbind(core.SEACH, "NONE", "Escape", act_cb(exit_search_mode))
core.cbind(core.SEACH, "NONE", "Enter", act_cb(accept_pattern))
core.cbind(core.SEACH, "CTRL", "raw:22", act.CopyMode 'ClearPattern')
core.cbind(core.SCROLL, "CTRL", "raw:22", act.CopyMode 'ClearPattern')
core.cbind(core.SCROLL, "NONE", "n", act.Multiple {
	act.CopyMode 'NextMatch',
	act.CopyMode 'MoveToSelectionOtherEnd',
	act.CopyMode 'ClearSelectionMode'
})
core.cbind(core.SCROLL, "CTRL", "n", act.Multiple {
	act.CopyMode 'PriorMatch',
	act.CopyMode 'MoveToSelectionOtherEnd',
	act.CopyMode 'ClearSelectionMode',
})
------------------------------------------
core.cbind(core.DEFAULT, "CTRL|SHIFT", "p", act.ActivateCommandPalette)
core.cbind(core.DEFAULT, "LEADER", "d", act_cb(function(w, p)
	w:perform_action(act.ShowDebugOverlay, p)
end))
core.cbind(core.DEFAULT, "CTRL|SHIFT", "v", act.PasteFrom 'Clipboard')
core.cbind(core.DEFAULT, "LEADER|CTRL", "w", act_cb(send_out_width(0)))
core.cbind(core.DEFAULT, "LEADER", "w", act.PromptInputLine {
	description = "offset?",
	action = act_cb(function(gui_window, mux_pane, offset_str)
		send_out_width(tonumber(offset_str))(gui_window, mux_pane)
	end),
})

function M.config_keybindings(config)
	config.debug_key_events = false
	config.disable_default_key_bindings = true
	config.leader = { key = 'b', mods = 'CTRL', timeout_milliseconds = 5000 }
	config.key_map_preference = "Mapped"
	config.keys = core.generate_key_config()
	config.key_tables = { copy_mode = {}, search_mode = {} }
end

return M
