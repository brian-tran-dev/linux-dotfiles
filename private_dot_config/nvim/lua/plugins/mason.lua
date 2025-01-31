return {
	"williamboman/mason.nvim",
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
	config = function()
		require("mason").setup({})
	end,
}
