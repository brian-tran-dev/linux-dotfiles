return {
	{
		"sainnhe/sonokai",
		lazy = false,
		priority = 1000,

		config = function()
			vim.g.sonokai_style = "shusia"
			vim.cmd.colorscheme("sonokai")
		end,
	},

	{
		"lukas-reineke/indent-blankline.nvim",
		config = function()
			require("ibl").setup()
		end,
	},

	{
		"stevearc/dressing.nvim",
		opts = {},
	},

	{
		"folke/noice.nvim",
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
		opts = {
			messages = { view = "mini", view_warn = "mini" },
			lsp = {
				-- override markdown rendering so that **cmp** and other plugins use **Treesitter**
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
				},
				signature = { enabled = false },
				hover = { view = "lsp_hover" },
			},
			cmdline = {
				view = "cmdline",
			},
			-- you can enable a preset for easier configuration
			presets = {
				bottom_search = true, -- use a classic bottom cmdline for search
				command_palette = true, -- position the cmdline and popupmenu together
				long_message_to_split = true, -- long messages will be sent to a split
				inc_rename = false, -- enables an input dialog for inc-rename.nvim
				lsp_doc_border = false, -- add a border to hover docs and signature help
			},
			---@type NoiceConfigViews
			views = {
				mini = {
					timeout = 3000,
					border = {
						style = "rounded"
					},
					win_options = {
						winblend = 10,
					},
				},
				lsp_hover = {
					view = "popup",
					relative = "cursor",
					zindex = 45,
					enter = true,
					anchor = "auto",
					size = {
						width = "auto",
						height = "auto",
						max_height = 10,
						max_width = 120,
					},
					border = {
						style = "rounded",
						padding = { 0, 1 },
					},
					position = { row = 1, col = 0 },
					win_options = {
						wrap = true,
						linebreak = true,
					},
				},
			}
		},
	},

	{
		'stevearc/aerial.nvim',
		opts = {},
		-- Optional dependencies
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
			"onsails/lspkind.nvim",
		},
	},

	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"folke/noice.nvim",
			'stevearc/aerial.nvim',
		},
		opts = {
			theme = "dracular",
			sections = {
				lualine_a = {{ "mode", fmt = function(str) return str:sub(1,1) end }},
				lualine_b = { "branch", "diagnostics" },
				lualine_c = {
					{
						"filename",
						file_status = true,
						path = 1,
						shorting_target = 40,
					},
					"aerial",
				},

				lualine_x = {},
				lualine_y = {
					{
						require("noice").api.statusline.mode.get,
						cond = require("noice").api.statusline.mode.has,
						color = { fg = "#ff9e64" },
					},
					"encoding",
					"filetype",
				},
				lualine_z = { "location", "selectioncount" },
			},
		},
	},

	{
		"folke/twilight.nvim",
		config = function ()
			vim.keymap.set(
				"n", "<leader>tf",
				function()
					vim.cmd[[ Twilight ]]
				end,
				{ desc = "Toggle focus mode"}
			)
		end
	},

	{
		"petertriho/nvim-scrollbar",
		opts = {
			handle = {
				blend = 0,
				color = "#575159",
			}
		},
	},

}
