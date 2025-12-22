return {
	{
		"ggandor/leap.nvim",
		dependencies = { "tpope/vim-repeat" },
		keys = {
			{
				"s",
				"<Plug>(leap)",
				mode = {'n', 'x', 'o'},
				desc = "Leap current window",
			},
			{
				"S",
				"<Plug>(leap-from-window)",
				mode = 'n',
				desc = "Leap current window",
			},
		},
	},
	{
		"kylechui/nvim-surround",
		version = "^3.0.0", -- Use for stability; omit to use `main` branch for the latest features
		event = "VeryLazy",
		opts = {},
	},
	{
		"wellle/targets.vim",
	},
}
