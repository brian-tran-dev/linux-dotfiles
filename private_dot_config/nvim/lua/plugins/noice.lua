return {
	"folke/noice.nvim",
	dependencies = {
		"MunifTanjim/nui.nvim",
		"rcarriga/nvim-notify",
	},

	config = function()
		local noice = require("noice")

		---@type NoiceConfig
		noice.setup({
			notify = { enabled = true },
			cmdline = { enabled = true, view = "cmdline" },
			messages = { enabled = true },
			popupmenu = { enabled = false },
			lsp = {
				progress = { enabled = true },
				hover = { enabled = false },
				signature = { enabled = false },
				message = { enabled = false },
				documentation = { enabled = false },
			},
			smart_move = { enabled = false },

			presets = {
				bottom_search = false,
				command_palette = false,
				long_message_to_split = false,
				inc_rename = false,
				lsp_doc_border = false,
			},

			routes = {
				-- Debug events
				{
					filter = {
						cond = function(message)
							local data = {
								event = message.event,
								kind = message.kind,
								content = message:content(),

							}
							local a = vim.g.testMy or {}
							table.insert(a, data)
							vim.g.testMy = a
							return false
						end,
					},
				},
				{
					filter = {
						any = {
							{ event = "msg_show", kind = "bufwrite" },
							{ event = "msg_show", find = "B written" },
							{ event = "msg_show", kind = "list_cmd" },
							{ event = "msg_show", kind = "emsg" },
							{ event = "msg_show", find = "yanked" },
							{ event = "notify", find = "Config Change Detected" },
						},
					},
					view = "mini",
					opts = { level = vim.log.levels.INFO },
				},
				{
					filter = {
						event = "notify",
						any = {
							{ error = true },
							{ warning = true },
						},
					},
					view = "notify",
				},
				{
					filter = { event = "notify" },
					view = "mini",
				},
			},

			views = {
				mini = {
					size = {
						max_width = math.floor(vim.o.columns * 0.5),
						width = "auto",
						height = "auto",
					},
					position = {
						row = -2,
					},
					border = {
						style = "rounded",
					},
					win_options = {
						winblend = 100,
						wrap = true,
						breakindent = true, -- nicer indent for wrapped lines
					},
				},
			},
		})

		---@diagnostic disable-next-line: undefined-field
		require("notify").setup({
			max_width = function()
				return math.floor(vim.o.columns * 0.5)
			end,
			render = "wrapped-default",
		})
	end,
}
