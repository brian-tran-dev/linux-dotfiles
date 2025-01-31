return {
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			{ "hrsh7th/cmp-buffer" },
			{ "hrsh7th/cmp-path" },
			{ "hrsh7th/cmp-cmdline" },
			{ "rafamadriz/friendly-snippets" },
			{ "L3MON4D3/LuaSnip" },
			{ "saadparwaiz1/cmp_luasnip" },
		},
		config = function()
			local cmp = require("cmp")
			local cmp_select = { behavior = cmp.SelectBehavior.Select }

			local mappings = {
				["<C-n>"] = cmp.mapping(function()
					if cmp.visible() then
						cmp.select_next_item(cmp_select)
					else
						cmp.complete()
					end
				end, { "i", "c" }),
				["<C-A-n>"] = cmp.mapping(function()
					if cmp.visible() then
						cmp.select_prev_item(cmp_select)
					end
				end, { "i", "c" }),
				["<Tab>"] = cmp.mapping(cmp.mapping.confirm({ select = true }), { "i", "c" }),
				["<C-[>"] = cmp.mapping(cmp.mapping.abort(), { "i", "c" }),
			}

			require("luasnip.loaders.from_vscode").lazy_load()
			cmp.setup({
				mapping = mappings,
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" }, -- For luasnip users.
				}, {
					{ name = "path" },
					{ name = "buffer" },
				}),
			})

			cmp.setup.cmdline({ "/", "?" }, {
				mappings = mappings,
				sources = {
					{ name = "buffer" },
				},
			})

			cmp.setup.cmdline(":", {
				sources = cmp.config.sources({
					{ name = "cmdline" },
					{ name = "path" },
				}),

				matching = { disallow_symbol_nonprefix_matching = false },
			})
		end,
	},

	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "williamboman/mason.nvim" },
			{ "williamboman/mason-lspconfig.nvim" },
			{"hrsh7th/nvim-cmp" },
			{ "hrsh7th/cmp-nvim-lsp" },
		},
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local lsp = require("lspconfig")
			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls",
					"html",
					"ts_ls",
					"cssls",
					"emmet_ls",
				},
				handlers = {
					function(server_name)
						lsp[server_name].setup({
							capabilities = capabilities,
						})
					end,
				},
			})
		end,
	},

	{
		"catgoose/nvim-colorizer.lua",
		event = "BufReadPre",
		opts = { -- set to setup table
		},
	},
}
