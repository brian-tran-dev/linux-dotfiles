return {
	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = {
			{ "tpope/vim-dadbod", lazy = true },
			{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
		},
		cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },

		keys = {
			{ "<leader>dd", "<cmd>DBUIToggle<CR>", desc = "DBUI Toggle" },
			{ "<leader>dw", "<Plug>(DBUI_SaveQuery)", desc = "DBUI Save Query" },
		},
		init = function()
			vim.g.db_ui_use_nerd_fonts = 1
			vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/dadbod_ui"
		end,
	},
}
