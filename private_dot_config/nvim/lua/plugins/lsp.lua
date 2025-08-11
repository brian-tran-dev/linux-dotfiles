return {
	{ "neovim/nvim-lspconfig" },
	{
		"mason-org/mason-lspconfig.nvim",
		dependencies = {
			"neovim/nvim-lspconfig",
			"mason-org/mason.nvim",
		},
		opts = {
			ensure_installed = {
				"lua_ls",
				"html",
				"ts_ls",
				"cssls",
				"emmet_ls",
			},
		},
	},

	{
		"brian-tran-dev/nvim-pretty_hover",
		opts = {
			max_height = 10,
			border = 'rounded',
		},
		config = function(_, opts)
			local hover = require("pretty_hover")
			hover.setup(opts)
			vim.keymap.set("n", "<leader>sd", hover.hover, { desc = "Show docs" })
		end,
	},

	{
		"saghen/blink.compat",
		version = "*",
		lazy = true,
		opts = {}
	},

	{
		"Jezda1337/nvim-html-css",
		dependencies = { "saghen/blink.cmp", "nvim-treesitter/nvim-treesitter" }, -- Use this if you're using blink.cmp
		opts = {
			enable_on = { -- Example file types
				"html",
				"htmldjango",
				"tsx",
				"jsx",
				"erb",
				"svelte",
				"vue",
				"blade",
				"php",
				"templ",
				"astro",
			},
			handlers = {
				definition = {
					bind = "<leader>gd"
				},
				hover = {
					bind = "<leader>sd",
					wrap = true,
					border = "none",
					position = "cursor",
				},
			},
			documentation = {
				auto_show = true,
			},
			style_sheets = {
				"https://cdn.jsdelivr.net/npm/bootstrap@5.3.7/dist/css/bootstrap.min.css",
			},
		},
	},

	{
		"saghen/blink.cmp",
		-- optional: provides snippets for the snippet source
		dependencies = {
			"rafamadriz/friendly-snippets",
		},

		-- use a release tag to download pre-built binaries
		-- version = '1.*',
		-- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
		build = "rustup run nightly cargo build --release",
		-- If you use nix, you can build from source using latest nightly rust with:
		-- build = 'nix run .#build-plugin',

		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			keymap = {
				preset = "none",
				["<C-n>"] = { "show", "select_next", "fallback" },
				["<C-A-n>"] = { "select_prev", "fallback" },
				["<C-A-k>"] = {
					"scroll_documentation_up",
					"fallback",
				},
				["<C-k>"] = {
					"select_prev",
					"scroll_signature_up",
					"fallback",
				},
				["<C-A-j>"] = {
					"scroll_documentation_down",
					"fallback",
				},
				["<C-j>"] = {
					"select_next",
					"scroll_signature_down",
					"fallback",
				},
				["<C-l>"] = { "show_documentation", "fallback" },
				["<C-h>"] = { "hide_documentation", "fallback" },
				["<Esc>"] = { "hide_documentation", "hide", "hide_signature", "fallback" },
				["<C-c>"] = { "cancel", "hide_signature", "fallback" },
				["<Tab>"] = { "select_and_accept", "fallback" },
				["<Cr>"] = { "accept", "fallback" },
			},

			appearance = {
				nerd_font_variant = "mono",
			},

			completion = {
				documentation = {
					auto_show = true,
					window = {
						max_height = 10,
						border = "rounded",
					},
				},
				trigger = {
					-- When true, will prefetch the completion items when entering insert mode
					prefetch_on_insert = true,
					-- When false, will not show the completion window automatically when in a snippet
					show_in_snippet = true,
					-- When true, will show completion window after backspacing
					show_on_backspace = false,
					-- When true, will show completion window after backspacing into a keyword
					show_on_backspace_in_keyword = true,
					-- When true, will show the completion window after accepting a completion and then backspacing into a keyword
					show_on_backspace_after_accept = true,
					-- When true, will show the completion window after entering insert mode and backspacing into keyword
					show_on_backspace_after_insert_enter = true,
					-- When true, will show the completion window after typing any of alphanumerics, `-` or `_`
					show_on_keyword = true,
					-- When true, will show the completion window after typing a trigger character
					show_on_trigger_character = true,
					-- When true, will show the completion window after entering insert mode
					show_on_insert = false,
					-- LSPs can indicate when to show the completion window via trigger characters
					-- however, some LSPs (i.e. tsserver) return characters that would essentially
					-- always show the window. We block these by default.
					show_on_blocked_trigger_characters = { " ", "\n", "\t" },
					-- When both this and show_on_trigger_character are true, will show the completion window
					-- when the cursor comes after a trigger character after accepting an item
					show_on_accept_on_trigger_character = true,
					-- When both this and show_on_trigger_character are true, will show the completion window
					-- when the cursor comes after a trigger character when entering insert mode
					show_on_insert_on_trigger_character = true,

					-- List of trigger characters (on top of `show_on_blocked_trigger_characters`) that won't trigger
					-- the completion window when the cursor comes after a trigger character when
					-- entering insert mode/accepting an item
					show_on_x_blocked_trigger_characters = { "'", '"', "(" },
				},
				list = {
					selection = { preselect = false, auto_insert = false },
				},
				ghost_text = {
					enabled = true,
					show_with_menu = true,
				},
			},

			signature = {
				enabled = true,
				trigger = {
					enabled = true,
					show_on_keyword = false,
					show_on_trigger_character = true,
					show_on_insert_on_trigger_character = true,
				},
				window = {
					max_height = 10,
					border = "rounded",
					show_documentation = true,
					scrollbar = true,
					treesitter_highlighting = true,
				},
			},

			-- Default list of enabled providers defined so that you can extend it
			-- elsewhere in your config, without redefining it, due to `opts_extend`
			sources = {
				default = { "lsp", "path", "snippets", "buffer", "html-css" },
				providers = {
					["html-css"] = {
						name = "html",
						module = "blink.compat.source"
					}
				}
			},

			-- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
			-- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
			-- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
			--
			-- See the fuzzy documentation for more information
			fuzzy = {
				implementation = "prefer_rust_with_warning",
				sorts = {
					"exact",
					"score",
					"sort_text",
				}
			},

			cmdline = {
				keymap = {
					preset = "inherit",
					["<C-c>"] = {
						function(cmp)
							cmp.cancel()
							return false
						end,
						"fallback",
					},
					["<Cr>"] = { "accept_and_enter", "fallback" },
				},
				completion = {
					menu = { auto_show = true },
					list = {
						selection = { preselect = false, auto_insert = false },
					},
				},
				sources = { "buffer", "cmdline", "path" },
			},
		},

		opts_extend = { "sources.default" },
		config = function(_, opts)
			local cmp = require("blink-cmp")
			cmp.setup(opts)
			vim.api.nvim_set_hl(0, "BlinkCmpGhostText", { fg = "#848089" })
		end,
	},


	{
		"catgoose/nvim-colorizer.lua",
		event = "BufReadPre",
		opts = {},
	},

	{
		"saecki/live-rename.nvim",
		---@module 'live-rename'
		---@type live_rename.UserConfig
		opts = {
			keys = {
				cancel = {
					{ "n", "<esc>" },
					{ "n", "q" },
					{ "n", "<c-c>" },
					{ "i", "<c-c>" },
					{ "v", "<c-c>" },
				},
			},
		},
		keys = {
			{
				"<leader>rn",
				function()
					require("live-rename").rename()
				end,
				mode = "n",
				desc = "Rename",
			},
		},
	},

	{
		"rachartier/tiny-code-action.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"folke/snacks.nvim",
		},
		event = "LspAttach",
		opts = {
			picker = "snacks",
		},
		keys = {
			{
				"<leader>la",
				function()
					require("tiny-code-action").code_action()
				end,
				mode = { "n", "x" },
				desc = "List code actions",
			}
		}
	},
}
