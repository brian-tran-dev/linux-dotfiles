return {
	config = function(config)
		local BORDER_COLOR <const> = "#a7f3d0"

		config.window_decorations = "NONE"

		config.window_frame = {
			border_left_width = "1px",
			border_right_width = "1px",
			border_bottom_height = "1px",
			border_top_height = "1px",
			border_left_color = BORDER_COLOR,
			border_right_color = BORDER_COLOR,
			border_bottom_color = BORDER_COLOR,
			border_top_color = BORDER_COLOR,
		}

		config.window_padding = {
			left = "10px",
			right = "10px",
			top = 0,
			bottom = 0,
		}
	end,
}
