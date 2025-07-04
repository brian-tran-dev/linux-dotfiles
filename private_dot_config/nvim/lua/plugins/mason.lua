return {
	"mason-org/mason.nvim",
	opts = {},
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
