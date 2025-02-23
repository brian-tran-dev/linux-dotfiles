local wezterm = require("wezterm")

local M = {}

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

function M.tcopy(t)
	local t2 = {}
	for k,v in pairs(t) do
		if type(v) == 'table' then
			t2[k] = M.tcopy(v)
		else
			t2[k] = v
		end
	end
	return t2
end

function M.get_discrete_gpu()
	for _, gpu in ipairs(wezterm.gui.enumerate_gpus()) do
		if gpu.backend == "Vulkan" and gpu.device_type == "DiscreteGpu" then
			return gpu
		end
	end
end

function M.fullscreen_window_frame()
	return M.tcopy(fullscreen_window_frame)
end

function M.shrunk_window_frame()
	return M.tcopy(shrunk_window_frame)
end

return M
