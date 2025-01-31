return {
	{
		"windwp/nvim-ts-autotag",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			require("nvim-ts-autotag").setup({
				opts = {
					enable_close = true, -- Auto close tags
					enable_rename = false, -- Auto rename pairs of tags
					enable_close_on_slash = false, -- Auto close on trailing </
				},
				per_filetype = {
					["html"] = {
						enable_close_on_slash = true,
						enable_rename = true,
					},
				},
			})
		end,
	},
	{
		"m4xshen/autoclose.nvim",
		config = function()
			require("autoclose").setup()
		end,
	},
}
