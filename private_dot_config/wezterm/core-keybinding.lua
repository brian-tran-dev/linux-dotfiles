local wezterm = require("wezterm")
local act = wezterm.action
local act_cb = wezterm.action_callback
-- local log = wezterm.log_info

local utils = require("utils")

local M = {}

local pane_modes = {}
local DEFAULT <const> = 'default'
M.DEFAULT = DEFAULT
local SCROLL <const> = 'scroll'
M.SCROLL = SCROLL
local SELECT <const> = 'select'
M.SELECT = SELECT
local SEARCH <const> = 'search'
M.SEARCH = SEARCH

local my_keys = {
	[DEFAULT] = {},
	[SCROLL] = {},
	[SELECT] = {},
	[SEARCH] = {},
}
local key_ids = {}

function M.cbind(mode, mods, key, key_action)
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

function M.fn_pane_mode(paneOrId, new_mode)
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
		local pane_mode = M.fn_pane_mode(mux_pane)
		local pane_action = my_keys[pane_mode][key_id]
		local in_pane_specific_mode = pane_mode ~= DEFAULT

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

function M.generate_key_config()
	local key_config = {}
	local key_index = 0
	for key_id, key_info in pairs(key_ids) do
		key_index = key_index + 1
		key_config[key_index] = {
			mods = key_info.mods,
			key = key_info.key,
			action = my_key_action(key_id, utils.tcopy(key_info))
		}
	end
	return key_config
end

return M
