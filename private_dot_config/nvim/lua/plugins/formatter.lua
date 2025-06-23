return {
	{
		"stevearc/conform.nvim",

		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				javascript = { "prettier" },
				jsx = { "prettier" },
				typescript = { "prettier" },
				html = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
			},
			format_on_save = function() end,
		},

		keys = {
			{
				"<leader>rf",
				function()
					require("conform").format()
				end,
				mode = { "n", "v" },
				desc = "Reformat",
			},
		},

	},


	{
		"zapling/mason-conform.nvim",
		dependencies = {
			"mason-org/mason.nvim",
			"stevearc/conform.nvim",
		},
		opts = {},
	}
}
