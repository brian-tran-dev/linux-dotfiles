return {
	{
		"stevearc/conform.nvim",

		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				javascript = { "eslint_d", "biome-format", "prettier" },
				javascriptreact = { "eslint_d", "biome-format", "prettier" },
				typescript = { "eslint_d", "biome-format", "prettier" },
				typescriptreact = { "eslint_d", "biome-format", "prettier" },
				tsx = { "eslint_d", "biome-format", "prettier" },
				jsx = { "eslint_d", "biome-format", "prettier" },
				html = { "prettier" },
				css = { "biome-format" },
				scss = { "prettier" },
				json = { "prettier" },
				jsonc = { "biome-format" },
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

		config = function (_, opts)
			local conform = require('conform')
			local util = require('conform.util')

			conform.setup(opts)

			conform.formatters["biome-format"] = {
				command = util.from_node_modules("biome"),
				stdin = true,
				args = {
					"check",
					"--write",
					"--formatter-enabled=true",
					"--linter-enabled=false",
					"--assist-enabled=true",
					"--stdin-file-path",
					"$FILENAME",
				},
				cwd = util.root_file({
					"biome.json",
					"biome.jsonc",
				}),
			}
		end
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
