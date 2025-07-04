local wezterm = require("wezterm")
local act = wezterm.action
local act_cb = wezterm.action_callback
local on_event = wezterm.on

local keybinding = require("core.keybinding")
local scroll_mode = require("config.key-action.pane-scroll-mode")
local select_mode = require("config.key-action.pane-select-mode")
local search_mode = require("config.key-action.pane-search-mode")
local tab_mode = require("config.key-action.window-tab-mode")

local function activate_default_mode()
	return act_cb(function(gui_window, mux_pane)
		gui_window:perform_action(act.ActivateKeyTable {
			name = "default_mode",
			one_shot = false,
			prevent_fallback = false,
			replace_current = true,
		}, mux_pane)
		keybinding.set_window_mode_name(nil)
	end)
end

local function activate_tab_input_mode()
	return act_cb(function(gui_window, mux_pane)
		gui_window:perform_action(act.ActivateKeyTable {
			name = "tab_input",
			one_shot = false,
			prevent_fallback = false,
			replace_current = true,
		}, mux_pane)
		keybinding.set_window_mode_name("TAB RENAME")
	end)
end

local function activate_control_mode()
	return act_cb(function(gui_window, mux_pane)
		gui_window:perform_action(act.ActivateKeyTable {
			name = "control_mode",
			one_shot = false,
			prevent_fallback = true,
			replace_current = true,
		}, mux_pane)
		keybinding.set_window_mode_name("CONTROL")
	end)
end

-- local function activate_confirm_mode()
-- 	return act_cb(function(gui_window, mux_pane)
-- 		gui_window:perform_action(act.ActivateKeyTable {
-- 			name = "confirm_mode",
-- 			one_shot = true,
-- 			prevent_fallback = true,
-- 			replace_current = false,
-- 		}, mux_pane)
-- 		keybinding.set_window_mode_name("CONFIRM")
-- 	end)
-- end

local function set_tab_name(gui_window, mux_pane, input_str)
	tab_mode.set_name(gui_window, input_str);
	wezterm.log_info("test");
	gui_window:perform_action(activate_control_mode(), mux_pane);
end

local function close_all(gui_window, mux_pane)
	gui_window:perform_action(act.QuitApplication, mux_pane);
end

local function make_default_keybindings()
	keybinding.default_bind("NONE", "F11", act.ToggleFullScreen)

	keybinding.default_bind("CTRL", "s", activate_control_mode())

	------- Sroll Select Search Mode -----------------------------
	keybinding.default_bind("LEADER", "[", act_cb(scroll_mode.enter))
	keybinding.scroll_bind("NONE", "Escape", act_cb(scroll_mode.exit))
	keybinding.scroll_bind("NONE", "q", act_cb(scroll_mode.exit))

	keybinding.scroll_bind("NONE", "v", act_cb(select_mode.enter('Cell')))
	keybinding.scroll_bind("NONE", "V", act_cb(select_mode.enter('Line')))
	keybinding.scroll_bind("CTRL", "v", act_cb(select_mode.enter('Block')))
	keybinding.select_bind("NONE", "Escape", act_cb(select_mode.exit))
	keybinding.select_bind("NONE", "q", act_cb(select_mode.exit))

	keybinding.scroll_bind("NONE", "w", act.CopyMode 'MoveForwardWord')
	keybinding.scroll_bind("NONE", "e", act.CopyMode 'MoveForwardWordEnd')
	keybinding.scroll_bind("NONE", "b", act.CopyMode 'MoveBackwardWord')
	keybinding.scroll_bind("SHIFT", "$", act.CopyMode 'MoveToEndOfLineContent')
	keybinding.scroll_bind("NONE", "0", act.CopyMode 'MoveToStartOfLine')
	keybinding.scroll_bind("NONE", "j", act.CopyMode 'MoveDown')
	keybinding.scroll_bind("NONE", "k", act.CopyMode 'MoveUp')
	keybinding.scroll_bind("NONE", "h", act.CopyMode 'MoveLeft')
	keybinding.scroll_bind("NONE", "l", act.CopyMode 'MoveRight')
	keybinding.scroll_bind("SHIFT", "%", act.CopyMode 'MoveToSelectionOtherEnd')
	keybinding.scroll_bind("SHIFT", "{", act.CopyMode 'MoveToScrollbackTop')
	keybinding.scroll_bind("SHIFT", "}", act.CopyMode 'MoveToScrollbackBottom')

	keybinding.select_bind("NONE", "w", act.CopyMode 'MoveForwardWord')
	keybinding.select_bind("NONE", "e", act.CopyMode 'MoveForwardWordEnd')
	keybinding.select_bind("NONE", "b", act.CopyMode 'MoveBackwardWord')
	keybinding.select_bind("SHIFT", "$", act.CopyMode 'MoveToEndOfLineContent')
	keybinding.select_bind("NONE", "0", act.CopyMode 'MoveToStartOfLine')
	keybinding.select_bind("NONE", "j", act.CopyMode 'MoveDown')
	keybinding.select_bind("NONE", "k", act.CopyMode 'MoveUp')
	keybinding.select_bind("NONE", "h", act.CopyMode 'MoveLeft')
	keybinding.select_bind("NONE", "l", act.CopyMode 'MoveRight')
	keybinding.select_bind("SHIFT", "%", act.CopyMode 'MoveToSelectionOtherEnd')
	keybinding.select_bind("SHIFT", "{", act.CopyMode 'MoveToScrollbackTop')
	keybinding.select_bind("SHIFT", "}", act.CopyMode 'MoveToScrollbackBottom')

	keybinding.select_bind("NONE", "v", act_cb(select_mode.enter('Cell')))
	keybinding.select_bind("NONE", "V", act_cb(select_mode.enter('Line')))
	keybinding.select_bind("CTRL", "v", act_cb(select_mode.enter('Block')))
	keybinding.select_bind("NONE", "y", act_cb(select_mode.copy_selection))


	keybinding.scroll_bind("NONE", "/", act_cb(search_mode.enter))
	keybinding.select_bind("NONE", "/", act_cb(search_mode.enter))
	keybinding.search_bind("NONE", "Escape", act_cb(search_mode.exit))
	keybinding.search_bind("NONE", "Enter", act_cb(search_mode.accept_pattern))
	keybinding.search_bind("CTRL", "raw:22", act.CopyMode 'ClearPattern')
	keybinding.scroll_bind("CTRL", "raw:22", act.CopyMode 'ClearPattern')
	keybinding.scroll_bind("NONE", "n", act.Multiple {
		act.CopyMode 'NextMatch',
		act.CopyMode 'MoveToSelectionOtherEnd',
		act.CopyMode 'ClearSelectionMode'
	})
	keybinding.scroll_bind("CTRL", "n", act.Multiple {
		act.CopyMode 'PriorMatch',
		act.CopyMode 'MoveToSelectionOtherEnd',
		act.CopyMode 'ClearSelectionMode',
	})
	------------------------------------------
	keybinding.default_bind("LEADER", "p", act.ActivateCommandPalette)
	keybinding.default_bind(
		"LEADER", "d",
		act_cb(function(w, p)
			w:perform_action(act.ShowDebugOverlay, p)
		end)
	)
end

local function create_control_key_config()
	return {
		{ mods = "CTRL", key = "q", action = act.QuitApplication },
		{ mods = "NONE", key = "Escape", action = activate_default_mode() },
		{ mods = "NONE", key = "q", action = activate_default_mode() },
		{ mods = "CTRL", key = "s", action = activate_default_mode() },

		{ mods = "CTRL", key = "d", action = act.CloseCurrentPane({ confirm = true }) },

		{ mods = "CTRL|SHIFT", key = "j", action = act.SplitPane({ direction = "Down", size = { Percent = 50 } }) },
		{ mods = "CTRL|SHIFT", key = "k", action = act.SplitPane({ direction = "Up", size = { Percent = 50 } }) },
		{ mods = "CTRL|SHIFT", key = "h", action = act.SplitPane({ direction = "Left", size = { Percent = 50 } }) },
		{ mods = "CTRL|SHIFT", key = "l", action = act.SplitPane({ direction = "Right", size = { Percent = 50 } }) },

		{ mods = "SHIFT", key = "j", action = act.AdjustPaneSize({ "Down", 2 }) },
		{ mods = "SHIFT", key = "k", action = act.AdjustPaneSize({ "Up", 2 }) },
		{ mods = "SHIFT", key = "h", action = act.AdjustPaneSize({ "Left", 5 }) },
		{ mods = "SHIFT", key = "l", action = act.AdjustPaneSize({ "Right", 5 }) },

		{ mods = "CTRL", key = "j", action = act.ActivatePaneDirection("Down") },
		{ mods = "CTRL", key = "k", action = act.ActivatePaneDirection("Up") },
		{ mods = "CTRL", key = "h", action = act.ActivatePaneDirection("Left") },
		{ mods = "CTRL", key = "l", action = act.ActivatePaneDirection("Right") },

		{ mods = "CTRL", key = "w", action = act.CloseCurrentTab({ confirm = true }) },
		{ mods = "CTRL", key = "i", action = act.ActivateTabRelative(-1) },
		{ mods = "CTRL", key = "o", action = act.ActivateTabRelative(1) },
		{ mods = "CTRL|ALT", key = "i", action = act.MoveTabRelative(-1) },
		{ mods = "CTRL|ALT", key = "o", action = act.MoveTabRelative(1) },
		-- { mods = "CTRL", key = "/", action = act.ShowTabNavigator },
		{ mods = "CTRL", key = "n", action = act_cb(tab_mode.new) },
		{
			mods = "CTRL", key = "u", action = act.Multiple {
				act.PromptInputLine {
					description = "current tab name?",
					action = act_cb(set_tab_name),
				},
				activate_tab_input_mode(),
			},
		},
		{ mods = "CTRL", key = "1", action = act.ActivateTab(0) },
		{ mods = "CTRL", key = "2", action = act.ActivateTab(1) },
		{ mods = "CTRL", key = "3", action = act.ActivateTab(2) },
		{ mods = "CTRL", key = "4", action = act.ActivateTab(3) },
		{ mods = "CTRL", key = "5", action = act.ActivateTab(4) },
		{ mods = "CTRL", key = "6", action = act.ActivateTab(5) },
		{ mods = "CTRL", key = "7", action = act.ActivateTab(6) },
		{ mods = "CTRL", key = "8", action = act.ActivateTab(7) },
		{ mods = "CTRL", key = "9", action = act.ActivateTab(8) },
	}
end

local function create_key_config()
	return {
		{ mods = "CTRL|SHIFT",  key = "v", action = act.PasteFrom("Clipboard") },
		{ mods = "CTRL", key = "d", action = act.SendKey { mods = "CTRL", key = "c" } },
	}
end

return {
	config = function(config)
		config.debug_key_events = false
		config.disable_default_key_bindings = true
		config.leader = { key = "b", mods = "CTRL", timeout_milliseconds = 5000 }
		config.key_map_preference = "Mapped"

		make_default_keybindings()

		config.keys = create_key_config()
		config.key_tables = {
			default_mode = keybinding.generate_key_config(),
			control_mode = create_control_key_config(),
			tab_input = {}, copy_mode = {}, search_mode = {},
		}

		local need_init = true;

		on_event(
			"window-config-reloaded",
			function(gui_window, mux_pane)
				if need_init then
					gui_window:perform_action(activate_default_mode(), mux_pane)
					need_init = false;
				end
			end
		)
	end,
}
