local utils = require("utils")

return {
	config_window = function(config)
		config.window_decorations = "NONE"
		config.window_frame = utils.shrunk_window_frame()
		config.window_padding = {
			left = "10px",
			right = "10px",
			top = 0,
			bottom = 0,
		}
	end,
}
