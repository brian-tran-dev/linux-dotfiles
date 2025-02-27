local wezterm = require("wezterm")
local act = wezterm.action
local act_cb = wezterm.action_callback

local misc = require("core.misc")


local DEFAULT <const> = 1
local SCROLL <const> = 2
local SELECT <const> = 3
local SEARCH <const> = 4

local pane_modes = {}
local mode_names <const> = {
	"DEFAULT",
	"SCROLL",
	"SELECT",
	"SEARCH",
}

local my_keys = {
	{}, -- DEFAULT
	{}, -- SCROLL
	{}, -- SELECT
	{}, -- SEARCH
}


local key_ids = {}

local function set_pane_id_mode(pane_id, new_mode)
	pane_modes[pane_id] = new_mode
end

local function get_pane_id_mode(pane_id)
	return pane_modes[pane_id]
end

local function create_bind_fn_for_mode(mode)
	return function(mods, key, key_action)
		local key_id = mods .. "|" .. key
		my_keys[mode][key_id] = key_action
		if key_ids[key_id] == nil then
			key_ids[key_id] = { mods = mods, key = key }
		end
	end
end

local function my_key_action(key_id, key_info)
	return act_cb(function(gui_window, mux_pane)
		local default_action = my_keys[DEFAULT][key_id]
		local pane_mode = get_pane_id_mode(mux_pane:pane_id())
		local pane_action = pane_mode ~= nil and my_keys[pane_mode][key_id] or nil

		if default_action ~= nil then -- no action triggered
			gui_window:perform_action(default_action, mux_pane)
		elseif pane_action ~= nil then -- trigger scroll action and pane IS IN scroll mode
			gui_window:perform_action(pane_action, mux_pane)
		else
			gui_window:perform_action(act.SendKey(key_info), mux_pane)
		end
	end)
end

local window_mode_name = nil

return {
	default_bind = create_bind_fn_for_mode(DEFAULT),
	scroll_bind = create_bind_fn_for_mode(SCROLL),
	select_bind = create_bind_fn_for_mode(SELECT),
	search_bind = create_bind_fn_for_mode(SEARCH),

	generate_key_config = function()
		local key_config = {}
		local key_index = 0
		for key_id, key_info in pairs(key_ids) do key_index = key_index + 1
			key_config[key_index] = {
				mods = key_info.mods,
				key = key_info.key,
				action = my_key_action(key_id, misc.tcopy(key_info)),
			}
		end
		return key_config
	end,

	set_pane_default = function(pane)
		set_pane_id_mode(pane:pane_id(), DEFAULT)
	end,

	set_pane_scroll = function(pane)
		set_pane_id_mode(pane:pane_id(), SCROLL)
	end,

	set_pane_select = function(pane)
		set_pane_id_mode(pane:pane_id(), SELECT)
	end,

	set_pane_search = function(pane)
		set_pane_id_mode(pane:pane_id(), SEARCH)
	end,

	mode_name_for_pane_id = function(pane_id)
		return mode_names[get_pane_id_mode(pane_id) or DEFAULT]
	end,

	is_pane_scroll = function(pane_id)
		return get_pane_id_mode(pane_id) == SCROLL
	end,

	is_pane_select = function(pane_id)
		return get_pane_id_mode(pane_id) == SELECT
	end,

	is_pane_search = function(pane_id)
		return get_pane_id_mode(pane_id) == SEARCH
	end,

	mode_name_for_window = function()
		return window_mode_name
	end,

	set_window_mode_name = function(mode_name)
		window_mode_name = mode_name
	end,
}
