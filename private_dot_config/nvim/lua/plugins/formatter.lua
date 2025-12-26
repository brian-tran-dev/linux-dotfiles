return {
	{
		"stevearc/conform.nvim",

		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				javascript = { "eslint_d", "prettier" },
				javascriptreact = { "eslint_d", "prettier" },
				typescript = { "eslint_d", "prettier" },
				typescriptreact = { "eslint_d", "prettier" },
				tsx = { "eslint_d", "prettier" },
				jsx = { "eslint_d", "prettier" },
				html = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
				json = { "prettier" },
				jsonc = { "biome-format" },
				yaml = { "prettier" },
				markdown = { "prettier" },
				toml = { "taplo" },
				typst = { "typstyle" },
			},
			format_on_save = function() end,
		},

		keys = {
			{
				"<leader>rf",
				function()
					require("conform").format({
						async = true,
						lsp_fallback = true,
					}, function(err, did_edit)
						if err then
							vim.notify("Fail to format", vim.log.levels.ERROR)
							return
						end

						if did_edit then
							vim.notify("Formatted!", vim.log.levels.INFO)
						else
							vim.notify("Formatted! no changes", vim.log.levels.INFO)
						end
					end)
				end,
				mode = { "n", "v" },
				desc = "Reformat",
			},
		},

		config = function(_, opts)
			local conform = require("conform")
			local util = require("conform.util")

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

			conform.formatters["typstyle"] = {
				prepend_args = {
					"-t",
					"4",
					"-l",
					"120",
				},
			}
		end,
	},

	{
		"zapling/mason-conform.nvim",
		dependencies = {
			"mason-org/mason.nvim",
			"stevearc/conform.nvim",
		},
		opts = {},
	},
}
