local wezterm = require("wezterm")

local M = {}

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
			wezterm.log_info(gpu)
			return gpu
		end
	end
end


return M
