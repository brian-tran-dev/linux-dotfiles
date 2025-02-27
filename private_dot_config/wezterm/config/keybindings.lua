local wezterm = require("wezterm")
local act = wezterm.action
local act_cb = wezterm.action_callback
local on_event = wezterm.on

local keybinding = require("core.keybinding")
local scroll_mode = require("config.key-action.pane-scroll-mode")
local select_mode = require("config.key-action.pane-select-mode")
local search_mode = require("config.key-action.pane-search-mode")
local tab_mode = require("config.key-action.window-tab-mode")
-- local misc = require("config.key-action.misc")

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

local function activate_pane_mode()
	return act_cb(function(gui_window, mux_pane)
		gui_window:perform_action(act.ActivateKeyTable {
			name = "pane_mode",
			one_shot = false,
			prevent_fallback = true,
			replace_current = true,
		}, mux_pane)
		keybinding.set_window_mode_name("PANE")
	end)
end

local function activate_tab_mode()
	return act_cb(function(gui_window, mux_pane)
		gui_window:perform_action(act.ActivateKeyTable {
			name = "tab_mode",
			one_shot = false,
			prevent_fallback = true,
			replace_current = true,
		}, mux_pane)
		keybinding.set_window_mode_name("TAB")
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

local function make_default_keybindings()
	keybinding.default_bind("NONE", "F11", act.ToggleFullScreen)
	keybinding.default_bind("CTRL", "q", act.QuitApplication)
	keybinding.default_bind("CTRL", "w", act.CloseCurrentTab({ confirm = false }))

	keybinding.default_bind("LEADER", "p", activate_pane_mode())
	keybinding.default_bind("LEADER", "t", activate_tab_mode())

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
	keybinding.default_bind("CTRL|SHIFT", "p", act.ActivateCommandPalette)
	keybinding.default_bind(
		"LEADER", "d",
		act_cb(function(w, p)
			w:perform_action(act.ShowDebugOverlay, p)
		end)
	)
	-- keybinding.default_bind("LEADER|CTRL", "w", act_cb(misc.send_out_width(0)))
	-- keybinding.default_bind(
	-- 	"LEADER", "w",
	-- 	act.PromptInputLine({
	-- 		description = "offset?",
	-- 		action = act_cb(function(gui_window, mux_pane, offset_str)
	-- 			misc.send_out_width(tonumber(offset_str))(gui_window, mux_pane)
	-- 		end),
	-- 	})
	-- )
end

local function create_pane_key_config()
	---- Pane Operator ------------------
	return {
		{ mods = "NONE", key = "Escape", action = activate_default_mode() },
		{ mods = "NONE", key = "q", action = activate_default_mode() },

		{ mods = "NONE", key = "x", action = act.CloseCurrentPane({ confirm = false }) },

		{ mods = "CTRL", key = "j", action = act.SplitPane({ direction = "Down", size = { Percent = 50 } }) },
		{ mods = "CTRL", key = "k", action = act.SplitPane({ direction = "Up", size = { Percent = 50 } }) },
		{ mods = "CTRL", key = "h", action = act.SplitPane({ direction = "Left", size = { Percent = 50 } }) },
		{ mods = "CTRL", key = "l", action = act.SplitPane({ direction = "Right", size = { Percent = 50 } }) },

		{ mods = "SHIFT", key = "j", action = act.AdjustPaneSize({ "Down", 2 }) },
		{ mods = "SHIFT", key = "k", action = act.AdjustPaneSize({ "Up", 2 }) },
		{ mods = "SHIFT", key = "h", action = act.AdjustPaneSize({ "Left", 5 }) },
		{ mods = "SHIFT", key = "l", action = act.AdjustPaneSize({ "Right", 5 }) },

		{ mods = "NONE", key = "j", action = act.ActivatePaneDirection("Down") },
		{ mods = "NONE", key = "k", action = act.ActivatePaneDirection("Up") },
		{ mods = "NONE", key = "h", action = act.ActivatePaneDirection("Left") },
		{ mods = "NONE", key = "l", action = act.ActivatePaneDirection("Right") },
	}
end

local function create_tab_key_config()
	return {
		{ mods = "NONE", key = "Escape", action = activate_default_mode() },
		{ mods = "NONE", key = "q", action = activate_default_mode() },

		{ mods = "NONE", key = "x", action = act.CloseCurrentTab({ confirm = false }) },
		{ mods = "NONE", key = "n", action = act_cb(tab_mode.new) },
		{ mods = "NONE", key = "/", action = act.ShowTabNavigator },
		{ mods = "NONE", key = "h", action = act.ActivateTabRelative(-1) },
		{ mods = "NONE", key = "l", action = act.ActivateTabRelative(1) },
		{ mods = "SHIFT", key = "h", action = act.MoveTabRelative(-1) },
		{ mods = "SHIFT", key = "l", action = act.MoveTabRelative(1) },
		{
			mods = "NONE", key = "u", action = act.Multiple {
				act.PromptInputLine {
					description = "current tab name?",
					action = act_cb(tab_mode.set_name),
				},
				activate_tab_input_mode(),
			},
		},
		{ mods = "NONE", key = "1", action = act.ActivateTab(0) },
		{ mods = "NONE", key = "2", action = act.ActivateTab(1) },
		{ mods = "NONE", key = "3", action = act.ActivateTab(2) },
		{ mods = "NONE", key = "4", action = act.ActivateTab(3) },
		{ mods = "NONE", key = "5", action = act.ActivateTab(4) },
		{ mods = "NONE", key = "6", action = act.ActivateTab(5) },
		{ mods = "NONE", key = "7", action = act.ActivateTab(6) },
		{ mods = "NONE", key = "8", action = act.ActivateTab(7) },
		{ mods = "NONE", key = "9", action = act.ActivateTab(8) },
	}
end

local function create_tab_input_key_config()
	return {
		{ mods = "NONE", key = "Escape", action = act.Multiple {
			act.SendKey { mods = "CTRL", key = "c" },
			activate_tab_mode()
		}},
		{ mods = "CTRL", key = "d", action = act.Multiple {
			act.SendKey { mods = "CTRL", key = "d" },
			activate_tab_mode()
		}},
		{ mods = "CTRL", key = "c", action = act.Multiple {
			act.SendKey { mods = "CTRL", key = "c" },
			activate_tab_mode()
		}},
		{ mods = "NONE", key = "Enter", action = act.Multiple {
			act.SendKey { mods = "NONE", key = "Enter" },
			activate_tab_mode()
		}}
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
			copy_mode = {}, search_mode = {},
			default_mode = keybinding.generate_key_config(),
			pane_mode = create_pane_key_config(),
			tab_mode = create_tab_key_config(),
			tab_input = create_tab_input_key_config(),
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
