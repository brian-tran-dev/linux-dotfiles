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
				bottom_search = false, -- use a classic bottom cmdline for search
				command_palette = false, -- position the cmdline and popupmenu together
				long_message_to_split = true, -- long messages will be sent to a split
				inc_rename = false, -- enables an input dialog for inc-rename.nvim
				lsp_doc_border = true, -- add a border to hover docs and signature help
			},
			---@type NoiceConfigViews
			views = {
				mini = {
					timeout = 3000,
					border = {
						style = "rounded",
					},
					win_options = {
						winblend = 10,
					},
					position = {
						row = -2,
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
					scrollbar = true,
				},
			},
		},
	},

	{
		"stevearc/aerial.nvim",
		opts = {
			layout = {
				max_width = { 40, 0.2 },
			},
		},
		-- Optional dependencies
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
			"onsails/lspkind.nvim",
		},
	},
	--
	{
		"brian-tran-dev/nvim-recorder",
		dependencies = { "rcarriga/nvim-notify" }, -- optional
		--- @type configObj
		---@diagnostic disable-next-line: missing-fields
		opts = {
			logLevel = vim.log.levels.WARN,
			slots = { "a", "b", "c" },
			lessNotifications = true,
		},
	},

	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"folke/noice.nvim",
			"stevearc/aerial.nvim",
		},
		opts = {
			options = {
				refresh = {
					statusline = 50,
				},
			},
			sections = {
				lualine_a = { {
					"mode",
					fmt = function(str)
						return str:sub(1, 1)
					end,
				} },
				lualine_b = { "diagnostics" },
				lualine_c = {
					{
						"filename",
						file_status = true,
						path = 1,
						shorting_target = 40,
					},
					{
						function()
							local aerial = require("aerial")
							local symbols = aerial.get_location(true)

							-- 3. Return empty if no symbols found
							local num_symbols = #symbols
							if num_symbols == 0 then
								return ""
							end

							-- 4. Define your separator
							local sep = " › "

							-- 5. Helper function to format a single symbol (icon + name)
							local function format_item(s)
								local kind = s.kind or ""
								local icon = s.icon or ""
								local name = s.name or ""

								-- Construct the highlight group name (e.g., AerialFunctionIcon)
								local hl_icon = "Aerial" .. kind .. "Icon"
								-- Optional: Highlight the text too (e.g., AerialFunction)
								local hl_text = "Aerial" .. kind

								-- FORMATTING:
								-- Icon gets specific color, text gets specific color (or remove hl_text to keep text white)
								return string.format("%%#%s#%s%%* %%#%s#%s%%*", hl_icon, icon, hl_text, name)
							end

							-- 6. Apply your logic: First symbol + ... + Last 2
							if num_symbols > 2 then
								local first = format_item(symbols[1])
								local last = format_item(symbols[num_symbols])

								return first .. sep .. "…" .. sep .. last
							else
								-- If 3 or fewer, just show all of them joined by the separator
								local parts = {}
								for _, s in ipairs(symbols) do
									table.insert(parts, format_item(s))
								end
								return table.concat(parts, sep)
							end
						end,
					},
				},

				lualine_x = {},
				lualine_y = {
					{
						function()
							return require("recorder").recordingStatus()
						end,
						color = { fg = "#ff9e64" },
					},
					{
						function()
							return require("recorder").displaySlots()
						end,
						color = { fg = "#e3e1e4" },
					},
					"encoding",
					"filetype",
				},
				lualine_z = {
					{
						"location",
						fmt = function(str)
							return vim.trim(str)
						end,
					},
					"selectioncount",
				},
			},
		},
	},

	{
		"folke/twilight.nvim",
		config = function()
			vim.keymap.set("n", "<leader>tf", function()
				vim.cmd([[ Twilight ]])
			end, { desc = "Toggle focus mode" })
		end,
	},

	{
		"karb94/neoscroll.nvim",
		opts = { mappings = {} },
		config = function(_, opts)
			local neoscroll = require("neoscroll")
			neoscroll.setup(opts)
			vim.keymap.set({ "n", "i" }, "<C-j>", function()
				neoscroll.scroll(1, { duration = 1 })
			end, { desc = "scroll down" })
			vim.keymap.set({ "n", "i" }, "<C-k>", function()
				neoscroll.scroll(-1, { duration = 1 })
			end, { desc = "scroll up" })
		end,
	},
}
