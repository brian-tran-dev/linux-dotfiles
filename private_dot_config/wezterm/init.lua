local wezterm = require("wezterm")

local config = wezterm.config_builder()
local act = wezterm.action
local act_cb = wezterm.action_callback
local format = wezterm.format
local strftime = wezterm.strftime
local on_event = wezterm.on
local log = wezterm.log_info
local icon = wezterm.nerdfonts

------------------ UTILS ------------------
local function tcopy(t)
	local t2 = {}
	for k,v in pairs(t) do
		if type(v) == 'table' then
			t2[k] = tcopy(v)
		else
			t2[k] = v
		end
	end
	return t2
end

-- local gpus = wezterm.gui.enumerate_gpus()
-- config.webgpu_preferred_adapter = gpus[1]
-- config.front_end = 'WebGpu'
config.enable_wayland = false

config.font = wezterm.font("JetbrainsMonoNL Nerd Font", { weight = 'Medium' })

config.use_ime = true
config.font_size = 12
config.line_height = 1.5
config.cell_width = 1.05
config.automatically_reload_config = false
config.default_gui_startup_args = {"start", "--always-new-process"}
config.animation_fps = 1
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
config.default_cursor_style = "BlinkingBlock"

config.enable_tab_bar = true
config.show_close_tab_button_in_tabs = false
config.show_new_tab_button_in_tab_bar = false
config.use_fancy_tab_bar = false
config.tab_max_width = 200
config.window_decorations = "NONE"

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

config.window_padding = {
  left = '10px',
  right = '10px',
  top = 0,
  bottom = 0,
}

------------- WINDOW FRAME -----------------------------------------------
local border_color = '#a7f3d0'
local shrunk_window_frame = {
	border_left_width = '1px', border_right_width = '1px',
	border_bottom_height = '1px',
	border_top_height = '1px',
	border_left_color = border_color,
	border_right_color = border_color,
	border_bottom_color = border_color,
	border_top_color = border_color,
}

local fullscreen_window_frame = {
	border_left_width = 0,
	border_right_width = 0,
	border_bottom_height = 0,
	border_top_height = 0,
}

config.window_frame = tcopy(shrunk_window_frame)

local function adjust_window_border(is_full_screen, gui_window)
	local local_config = gui_window:get_config_overrides() or {}
	if is_full_screen then
		local_config.window_frame = tcopy(fullscreen_window_frame)
	else
		local_config.window_frame = tcopy(shrunk_window_frame)
	end
	local_config.keys = gui_window:effective_config().keys
	gui_window:set_config_overrides(local_config)
end
--------------------------------------------------------------------------------

--------------- KEY BINDINGS ----------------------------------------------------

local tab_names = {}

local pane_modes = {}
local DEFAULT <const> = 'default'
local SCROLL <const> = 'scroll'
local SELECT <const> = 'select'
local SEARCH <const> = 'search'

local my_keys = {
	[DEFAULT] = {},
	[SCROLL] = {},
	[SELECT] = {},
	[SEARCH] = {},
}
local key_ids = {}

local function cbind(mode, mods, key, key_action)
	if mode ~= DEFAULT and
		mode ~= SCROLL and
		mode ~= SELECT and
		mode ~= SEARCH
	then
		return
	end

	local key_id = mods..'|'..key
	my_keys[mode][key_id] = key_action
	if key_ids[key_id] == nil then
		key_ids[key_id] = { mods = mods, key = key }
	end
end

local function fn_pane_mode(paneOrId, new_mode)
	local pane_id = paneOrId
	if type(paneOrId) == "userdata" then
		pane_id = paneOrId:pane_id()
	end

	if new_mode then
		pane_modes[pane_id] = new_mode
	end

	return pane_modes[pane_id] or DEFAULT
end

local function my_key_action(key_id, key_info)
	return act_cb(function (gui_window, mux_pane)
		-- log("key_id =", key_id)

		local default_action = my_keys[DEFAULT][key_id]
		local pane_mode = fn_pane_mode(mux_pane)
		local pane_action = my_keys[pane_mode][key_id]
		local in_pane_specific_mode = pane_mode ~= DEFAULT

		-- log({
		-- 	pane_id = mux_pane:pane_id(),
		-- 	default_act = default_action,
		-- 	pane_act = pane_action or 'nil',
		-- 	pane_modes = pane_modes,
		-- 	pane_mode = pane_mode,
		-- })

		if default_action == nil and pane_action == nil then          -- no action triggered
			gui_window:perform_action(act.SendKey(key_info), mux_pane)
		elseif default_action ~= nil then                               -- trigger default action
			gui_window:perform_action(default_action, mux_pane)
		elseif in_pane_specific_mode then                                      -- trigger scroll action and pane IS IN scroll mode
			gui_window:perform_action(pane_action, mux_pane)
		else                                                            -- trigger scroll action but pane IS NOT IN scroll mode
			gui_window:perform_action(act.SendKey(key_info), mux_pane)
		end
	end)
end

local function generate_key_config()
	local key_config = {}
	local key_index = 0
	for key_id, key_info in pairs(key_ids) do
		key_index = key_index + 1
		key_config[key_index] = {
			mods = key_info.mods,
			key = key_info.key,
			action = my_key_action(key_id, tcopy(key_info))
		}
	end
	return key_config
end

local function toggle_fullscreen(gui_window, _)
	local is_fullscreen = gui_window:get_dimensions().is_full_screen
	adjust_window_border(not is_fullscreen, gui_window)
	gui_window:toggle_fullscreen()
	-- if is_fullscreen then
	-- 	gui_window:toggle_fullscreen()
	-- 	adjust_window_border(false, gui_window)
	-- else
	-- 	adjust_window_border(true, gui_window)
	-- 	gui_window:toggle_fullscreen()
	-- end
end

local function enter_scroll_mode(gui_window, mux_pane)
	gui_window:perform_action(act.ActivateCopyMode, mux_pane)
	-- log("Activated")
	fn_pane_mode(mux_pane, SCROLL)
end

local function exit_scroll_mode(gui_window, mux_pane)
	gui_window:perform_action(act.Multiple {
		act.CopyMode "ClearPattern",
		act.CopyMode "AcceptPattern",
		act.CopyMode "ClearSelectionMode",
		act.CopyMode "Close",
		act.ScrollToBottom,
	}, mux_pane)
	fn_pane_mode(mux_pane, DEFAULT)
end

local function enter_select_mode(select_mode)
	return function(gui_window, mux_pane)
		gui_window:perform_action(
			act.CopyMode { SetSelectionMode =  select_mode },
			mux_pane
		)
		fn_pane_mode(mux_pane, SELECT)
	end
end

local function exit_select_mode(gui_window, mux_pane)
	gui_window:perform_action(act.CopyMode 'ClearSelectionMode', mux_pane)
	fn_pane_mode(mux_pane, SCROLL)
end

local function copy_selection(gui_window, mux_pane)
	gui_window:perform_action(act.Multiple {
		act.CopyTo "Clipboard",
		act.CopyMode "ClearSelectionMode",
	}, mux_pane)
	fn_pane_mode(mux_pane, SCROLL)
end

local function enter_search_mode(gui_window, mux_pane)
	gui_window:perform_action(
		act.Search { Regex = '' },
		mux_pane
	)
	fn_pane_mode(mux_pane, SEARCH)
end

local function exit_search_mode(gui_window, mux_pane)
	gui_window:perform_action(act.Multiple {
		act.CopyMode 'ClearPattern',
		act.CopyMode 'AcceptPattern',
		act.CopyMode 'ClearSelectionMode',
	}, mux_pane)
	fn_pane_mode(mux_pane, SCROLL)
end

local function accept_pattern(gui_window, mux_pane)
	gui_window:perform_action(act.Multiple {
		act.CopyMode 'AcceptPattern',
		act.CopyMode 'MoveToSelectionOtherEnd',
		act.CopyMode 'ClearSelectionMode',
	}, mux_pane)
	fn_pane_mode(mux_pane, SCROLL)
end

local tab_name_changes = {}
local function update_tab_name(gui_window, _, input_name)
	local tab_id = gui_window:active_tab():tab_id()
	local prev_name = tab_names[tab_id]
	local new_name = nil
	if string.len(input_name) > 0 then
		new_name = input_name
	else
		new_name = nil
	end
	tab_names[tab_id] = new_name
	if prev_name ~= new_name then
		tab_name_changes[tab_id] = true
	end
end

local function send_out_width(offset)
	return function(gui_window, mux_pane)
		local width = tostring(mux_pane:get_dimensions().cols - offset)
		-- log("Pane Width: ", width)
		gui_window:perform_action(act.SendString(width), mux_pane)
	end
end

cbind(DEFAULT, "NONE", "F11", act_cb(toggle_fullscreen))
cbind(DEFAULT, "CTRL", "q", act.QuitApplication)
---- Split Pane ------------------
cbind(DEFAULT, "LEADER|CTRL", "j", act.SplitPane { direction = 'Down', size = { Percent = 50 } } )
cbind(DEFAULT, "LEADER|CTRL", "k", act.SplitPane { direction = 'Up', size = { Percent = 50 } } )
cbind(DEFAULT, "LEADER|CTRL", "h", act.SplitPane { direction = 'Left', size = { Percent = 50 } } )
cbind(DEFAULT, "LEADER|CTRL", "l", act.SplitPane { direction = 'Right', size = { Percent = 50 } } )
---- Resize Pane ----------------
cbind(DEFAULT, "LEADER|SHIFT", "j", act.AdjustPaneSize { 'Down', 2 })
cbind(DEFAULT, "LEADER|SHIFT", "k", act.AdjustPaneSize { 'Up', 2 })
cbind(DEFAULT, "LEADER|SHIFT", "h", act.AdjustPaneSize { 'Left', 5 })
cbind(DEFAULT, "LEADER|SHIFT", "l", act.AdjustPaneSize { 'Right', 5 })
---- Navigate Pane ----------------
cbind(DEFAULT, "CTRL", "j", act.ActivatePaneDirection("Down"))
cbind(DEFAULT, "CTRL", "k", act.ActivatePaneDirection("Up"))
cbind(DEFAULT, "CTRL", "h", act.ActivatePaneDirection("Left"))
cbind(DEFAULT, "CTRL", "l", act.ActivatePaneDirection("Right"))
----- Close Pane -------------------
cbind(DEFAULT, "CTRL", "d", act.CloseCurrentPane { confirm = false })
------ Tab Operator ----------------
cbind(DEFAULT, "CTRL", "w", act.CloseCurrentTab { confirm = false })
cbind(DEFAULT, "ALT", "n", act.SpawnTab 'CurrentPaneDomain')
cbind(DEFAULT, "ALT", "h", act.ActivateTabRelative(-1))
cbind(DEFAULT, "ALT", "l", act.ActivateTabRelative(1))
cbind(DEFAULT, "LEADER|ALT", "h", act.MoveTabRelative(-1))
cbind(DEFAULT, "LEADER|ALT", "l", act.MoveTabRelative(1))
cbind(DEFAULT, "ALT", "/", act.ShowTabNavigator)
cbind(DEFAULT, "ALT", "u", act.PromptInputLine {
	description = "current tab name?",
	action = act_cb(update_tab_name),
})
cbind(DEFAULT, "ALT", "1", act.ActivateTab(0))
cbind(DEFAULT, "ALT", "2", act.ActivateTab(1))
cbind(DEFAULT, "ALT", "3", act.ActivateTab(2))
cbind(DEFAULT, "ALT", "4", act.ActivateTab(3))
cbind(DEFAULT, "ALT", "5", act.ActivateTab(4))
cbind(DEFAULT, "ALT", "6", act.ActivateTab(5))
cbind(DEFAULT, "ALT", "7", act.ActivateTab(6))
cbind(DEFAULT, "ALT", "8", act.ActivateTab(7))
cbind(DEFAULT, "ALT", "9", act.ActivateTab(8))
------- Pane Specific Mode -----------------------------
cbind(DEFAULT, "LEADER", "[", act_cb(enter_scroll_mode))
cbind(SCROLL, "NONE", "Escape", act_cb(exit_scroll_mode))
cbind(SCROLL, "NONE", "q", act_cb(exit_scroll_mode))

cbind(SCROLL, "NONE", "v", act_cb(enter_select_mode('Cell')))
cbind(SCROLL, "NONE", "V", act_cb(enter_select_mode('Line')))
cbind(SCROLL, "CTRL", "v", act_cb(enter_select_mode('Block')))
cbind(SELECT, "NONE", "Escape", act_cb(exit_select_mode))
cbind(SELECT, "NONE", "q", act_cb(exit_select_mode))

cbind(SCROLL, "NONE", "w", act.CopyMode 'MoveForwardWord')
cbind(SCROLL, "NONE", "e", act.CopyMode 'MoveForwardWordEnd')
cbind(SCROLL, "NONE", "b", act.CopyMode 'MoveBackwardWord')
cbind(SCROLL, "SHIFT", "$", act.CopyMode 'MoveToEndOfLineContent')
cbind(SCROLL, "NONE", "0", act.CopyMode 'MoveToStartOfLine')
cbind(SCROLL, "NONE", "j", act.CopyMode 'MoveDown')
cbind(SCROLL, "NONE", "k", act.CopyMode 'MoveUp')
cbind(SCROLL, "NONE", "h", act.CopyMode 'MoveLeft')
cbind(SCROLL, "NONE", "l", act.CopyMode 'MoveRight')
cbind(SCROLL, "SHIFT", "%", act.CopyMode 'MoveToSelectionOtherEnd')
cbind(SCROLL, "SHIFT", "{", act.CopyMode 'MoveToScrollbackTop')
cbind(SCROLL, "SHIFT", "}", act.CopyMode 'MoveToScrollbackBottom')

cbind(SELECT, "NONE", "w", act.CopyMode 'MoveForwardWord')
cbind(SELECT, "NONE", "e", act.CopyMode 'MoveForwardWordEnd')
cbind(SELECT, "NONE", "b", act.CopyMode 'MoveBackwardWord')
cbind(SELECT, "SHIFT", "$", act.CopyMode 'MoveToEndOfLineContent')
cbind(SELECT, "NONE", "0", act.CopyMode 'MoveToStartOfLine')
cbind(SELECT, "NONE", "j", act.CopyMode 'MoveDown')
cbind(SELECT, "NONE", "k", act.CopyMode 'MoveUp')
cbind(SELECT, "NONE", "h", act.CopyMode 'MoveLeft')
cbind(SELECT, "NONE", "l", act.CopyMode 'MoveRight')
cbind(SELECT, "SHIFT", "%", act.CopyMode 'MoveToSelectionOtherEnd')
cbind(SELECT, "SHIFT", "{", act.CopyMode 'MoveToScrollbackTop')
cbind(SELECT, "SHIFT", "}", act.CopyMode 'MoveToScrollbackBottom')

cbind(SELECT, "NONE", "v", act_cb(enter_select_mode('Cell')))
cbind(SELECT, "NONE", "V", act_cb(enter_select_mode('Line')))
cbind(SELECT, "CTRL", "v", act_cb(enter_select_mode('Block')))
cbind(SELECT, "NONE", "y", act_cb(copy_selection))


cbind(SCROLL, "NONE", "/", act_cb(enter_search_mode))
cbind(SELECT, "NONE", "/", act_cb(enter_search_mode))
cbind(SEARCH, "NONE", "Escape", act_cb(exit_search_mode))
cbind(SEARCH, "NONE", "Enter", act_cb(accept_pattern))
cbind(SEARCH, "CTRL", "raw:22", act.CopyMode 'ClearPattern')
cbind(SCROLL, "CTRL", "raw:22", act.CopyMode 'ClearPattern')
cbind(SCROLL, "NONE", "n", act.Multiple {
	act.CopyMode 'NextMatch',
	act.CopyMode 'MoveToSelectionOtherEnd',
	act.CopyMode 'ClearSelectionMode'
})
cbind(SCROLL, "CTRL", "n", act.Multiple {
	act.CopyMode 'PriorMatch',
	act.CopyMode 'MoveToSelectionOtherEnd',
	act.CopyMode 'ClearSelectionMode',
})
------------------------------------------
cbind(DEFAULT, "CTRL|SHIFT", "p", act.ActivateCommandPalette)
cbind(DEFAULT, "LEADER", "d", act_cb(function(w, p)
	-- log("Config ", w:effective_config())
	w:perform_action(act.ShowDebugOverlay, p)
end))
cbind(DEFAULT, "CTRL|SHIFT", "v", act.PasteFrom 'Clipboard')
cbind(DEFAULT, "LEADER|CTRL", "w", act_cb(send_out_width(0)))
cbind(DEFAULT, "LEADER", "w", act.PromptInputLine {
	description = "offset?",
	action = act_cb(function(gui_window, mux_pane, offset_str)
		send_out_width(tonumber(offset_str))(gui_window, mux_pane)
	end),
})

config.debug_key_events = false
config.disable_default_key_bindings = true
config.leader = { key = 'b', mods = 'CTRL', timeout_milliseconds = 5000 }
config.key_map_preference = "Mapped"
config.keys = generate_key_config()
config.key_tables = { copy_mode = {}, search_mode = {} }

-------------------- Event Schedule ----------------------------
config.status_update_interval = 500
on_event("update-right-status", function(gui_window)
	local date = strftime '%a,%d/%m,%H:%M:%S'
	local mode = fn_pane_mode(gui_window:active_pane())

	local solid_left = utf8.char(0xe0b2)

	local bg_colors = { "#6b6b80", "#606073", "#555566" }
	local fg_colors = { "#FFFFFF", "#FFFFFF", "#FFFFFF" }

	if mode == 'scroll' then
		bg_colors[1] = '#f1fa8c'
		fg_colors[1] = '#2a2e32'
	end

	-- Make it italic and underlined
	gui_window:set_right_status(format {
		{ Attribute = { Intensity = "Bold" } },
		{ Foreground = { Color = bg_colors[1] } },
		{ Text = solid_left },
		{ Background = { Color = bg_colors[1] } },
		{ Foreground = { Color = fg_colors[1] } },
		{ Text = ' '..mode..' ' },
		{ Foreground = { Color = bg_colors[2] } },
		{ Text = solid_left },
		{ Background = { Color = bg_colors[2] } },
		{ Foreground = { Color = fg_colors[2] } },
		{ Text = ' '..icon.cod_calendar..' '..date..' ' },
	})
end)
----------------------------------------------------------
------------ Tab Title -----------------------------
local tab_title_cache = {}
on_event('format-tab-title', function(tab, _, _, _, _, _)
	local tab_id = tab.tab_id
	local name = tab_names[tab_id] or ""
	local index = tab.tab_index

	local item = tab_title_cache[index] or {}

	-- log("tab title #", index, ': ', item)

	if item.tab_id ~= tab_id or tab_name_changes[tab_id] == true then
		item = {
			tab_id = tab_id,
			value = {{ Text = ' '..(index + 1)..': '..name..' ' }}
		}
		tab_title_cache[index] = item
		tab_name_changes[tab_id] = nil
	end

	return item.value
end)
----------------------------------------------

return config
