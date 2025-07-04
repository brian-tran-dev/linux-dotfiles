return {
	{
		"stevearc/conform.nvim",

		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				javascript = { "biome", "prettier" },
				javascriptreact = { "biome", "prettier" },
				typescript = { "biome", "prettier" },
				typescriptreact = { "biome", "prettier" },
				jsx = { "biome", "prettier" },
				html = { "prettier" },
				css = { "biome", "prettier" },
				scss = { "prettier" },
				json = { "prettier" },
				jsonc = { "biome", "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
			},
			format_on_save = function() end,
		},

		keys = {
			{
				"<leader>rf",
				function()
					require("conform").format({ stop_after_first = true })
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
