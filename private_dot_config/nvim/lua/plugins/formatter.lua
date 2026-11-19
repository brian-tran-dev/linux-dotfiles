local oxfmt_configs = { ".oxfmtrc.json", ".oxfmtrc.jsonc" }
local eslint_configs = {
	"eslint.config.js",
	"eslint.config.mjs",
	"eslint.config.cjs",
	"eslint.config.ts",
	"eslint.config.mts",
	"eslint.config.cts",
	".eslintrc",
	".eslintrc.js",
	".eslintrc.cjs",
	".eslintrc.json",
	".eslintrc.yml",
	".eslintrc.yaml",
}

-- Mason auto-install needs a table of formatter names, not a function.
local js_formatters = { "oxfmt", "eslint_d", "prettier", stop_after_first = true }

return {
	{
		"stevearc/conform.nvim",

		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				javascript = js_formatters,
				javascriptreact = js_formatters,
				typescript = js_formatters,
				typescriptreact = js_formatters,
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

			conform.formatters.oxfmt = {
				condition = function(_, ctx)
					return vim.fs.root(ctx.dirname, oxfmt_configs) ~= nil
				end,
			}

			conform.formatters.eslint_d = {
				condition = function(_, ctx)
					return vim.fs.root(ctx.dirname, eslint_configs) ~= nil
				end,
			}

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
