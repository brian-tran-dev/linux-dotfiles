return {
	"folke/which-key.nvim",
    event = "VeryLazy",
    opts_extend = { "spec" },
	opts = {
		preset = "classic",
		filter = function(mapping)
			local c = mapping.lhs:sub(1, 1)
			return c == ' ' or c == "'" or c == '"'
		end,
		spec = {{
			mode = { "n" },
			{ "<leader>d", group = "Diagnostic" },
			{ "<leader>f", group = "Find" },
			{ "<leader>g", group = "Go to" },
			{ "<leader>p", group = "Panel" },
			{ "<leader>s", group = "Switch" },
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer Local Keymaps (which-key)",
			}
		}}
	},
    config = function(_, opts)
		local wk = require("which-key")
		wk.setup(opts)
    end,
}
