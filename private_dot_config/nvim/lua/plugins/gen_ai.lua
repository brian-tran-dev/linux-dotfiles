return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	opts = {
		adapters = {
			acp = {
				gemini_cli = function()
					return require("codecompanion.adapters").extend("gemini_cli", {
						commands = {
							default = {
								vim.fn.stdpath("config") .. "/scripts/gemini.sh",
							},
						},
						defaults = {
							auth_method = "oauth-personal",
						},
					})
				end,
			},
		},
		interactions = {
			chat = { adapter = "gemini_cli" },
			inline = { adapter = "gemini_cli" },
		},
	},
}
