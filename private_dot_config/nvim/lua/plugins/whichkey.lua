return {
	"folke/which-key.nvim",

    event = "VeryLazy",

	opts = {
		preset = "classic",

		filter = function(mapping)
			local c = mapping.lhs:sub(1, 1)
			return c == ' ' or c == "'" or c == '"'
		end,

		spec = {
			{ "<leader>b", group =  "Buffer"},
			{ "<leader>d", group = "Diagnostic" },
			{ "<leader>f", group = "Find" },
			{ "<leader>g", group = "Go to" },
			{ "<leader>p", group = "Panel" },
			{ "<leader>l", group = "List" },
		},

	},
}
