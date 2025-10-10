return {
	"mason-org/mason.nvim",
	opts = {
		log_level = vim.log.levels.DEBUG,
	},
	keys = {
		{
			"<leader>pm",
			function()
				vim.cmd([[ Mason ]])
			end,
			mode = "n",
			desc = "Mason Panel",
		},
	},
}
