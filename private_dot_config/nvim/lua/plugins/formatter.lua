return {
	"stevearc/conform.nvim",
	dependencies = {
		"williamboman/mason.nvim",
		"zapling/mason-conform.nvim",
	},
	config = function()
		require("conform").setup({
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
		})
		require("mason-conform").setup()
	end,
	keys = {
		{
			"<leader>rf",
			function()
				require("conform").format()
			end,
			mode = "n",
			desc = "Reformat all",
		},
		{
			"<leader>rf",
			function()
				require("conform").format()
			end,
			mode = "v",
			desc = "Reformat selection",
		},
	},
}
