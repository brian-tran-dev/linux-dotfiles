local wezterm = require("wezterm")
local strftime = wezterm.strftime
local format = wezterm.format
local icon = wezterm.nerdfonts
local on_event = wezterm.on
local time = wezterm.time
local log = wezterm.log_info

local keybinding = require("core.keybinding")


local SOLID_LEFT <const> = utf8.char(0xe0b2)
local ICON_BATTERY <const> = {
	icon.fa_battery_0,
	icon.fa_battery_1,
	icon.fa_battery_2,
	icon.fa_battery_3,
	icon.fa_battery_4,
	icon.fa_battery_4,
}

local function get_battery_display()
	local battery = wezterm.battery_info()[1]
	local level = battery["state_of_charge"]
	local level_index = math.floor(level * 5 + 1)
	return ICON_BATTERY[level_index], math.floor(level * 100)
end

return {
	config = function(config)
		config.status_update_interval = 200
		local BATTERY_UPDATE_INTERVAL_IN_SEC <const> = 15

		local battery_icon, battery_level = get_battery_display()

		local function update_battery_display_info()
			battery_icon, battery_level = get_battery_display()
			time.call_after(BATTERY_UPDATE_INTERVAL_IN_SEC, update_battery_display_info)
		end

		time.call_after(BATTERY_UPDATE_INTERVAL_IN_SEC, update_battery_display_info)

		on_event("update-right-status", function(gui_window)
			local pane_id = gui_window:active_pane():pane_id()
			local pane_mode = keybinding.mode_name_for_pane_id(pane_id)
			local window_mode = keybinding.mode_name_for_window()
			local general_info = " " .. strftime("%H:%M:%S") .. " "  .. battery_icon .. " " .. battery_level .. "% "

			local bg_colors = { "#6b6b80", "#606073", "#555566" }
			local fg_colors = { "#FFFFFF", "#FFFFFF", "#FFFFFF" }

			if keybinding.is_pane_scroll(pane_id) then
				bg_colors[2] = "#bd93f9"
				fg_colors[2] = "#2a2e32"
			elseif keybinding.is_pane_select(pane_id) then
				bg_colors[2] = "#f1fa8c"
				fg_colors[2] = "#2a2e32"
			elseif keybinding.is_pane_search(pane_id) then
				bg_colors[2] = "#ffb86c"
				fg_colors[2] = "#2a2e32"
			end

			if window_mode ~= nil then
				bg_colors[1] = "#a7f3d0"
				fg_colors[1] = "#2a2e32"
			end

			-- Make it italic and underlined
			if window_mode == nil then
				gui_window:set_right_status(format({
					{ Attribute = { Intensity = "Bold" } },
					{ Foreground = { Color = bg_colors[2] } },
					{ Text = SOLID_LEFT },
					{ Background = { Color = bg_colors[2] } },
					{ Foreground = { Color = fg_colors[2] } },
					{ Text = " " .. pane_mode .. " " },
					{ Foreground = { Color = bg_colors[3] } },
					{ Text = SOLID_LEFT },
					{ Background = { Color = bg_colors[3] } },
					{ Foreground = { Color = fg_colors[3] } },
					{ Text = general_info },
				}))
			else
				gui_window:set_right_status(format({
					{ Attribute = { Intensity = "Bold" } },
					{ Foreground = { Color = bg_colors[1] } },
					{ Text = SOLID_LEFT },
					{ Background = { Color = bg_colors[1] } },
					{ Foreground = { Color = fg_colors[1] } },
					{ Text = " " .. window_mode .. " " },
					{ Foreground = { Color = bg_colors[2] } },
					{ Text = SOLID_LEFT },
					{ Background = { Color = bg_colors[2] } },
					{ Foreground = { Color = fg_colors[2] } },
					{ Text = " " .. pane_mode .. " " },
					{ Foreground = { Color = bg_colors[3] } },
					{ Text = SOLID_LEFT },
					{ Background = { Color = bg_colors[3] } },
					{ Foreground = { Color = fg_colors[3] } },
					{ Text = general_info },
				}))
			end
		end)
	end,
}
