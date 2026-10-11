return {
	{
		"folke/snacks.nvim",
		opts = {
			picker = {
				win = {
					-- input window
					input = {
						keys = {
							["<C-c>"] = { "close", mode = { "i", "n" } },
							["<C-l>"] = { "confirm", mode = { "n", "i" } },
							["<M-j>"] = { "preview_scroll_down", mode = { "i", "n" } },
							["<M-k>"] = { "preview_scroll_up", mode = { "i", "n" } },
						},
					},
					list = {
						keys = {
							["<C-c>"] = "close",
							["<C-l>"] = "confirm",
						},
					},
				},
			},
			explorer = {},
		},

		---@module "snacks"
		keys = {

			-- Find
			{
				"<leader>fg",
				function()
					Snacks.picker.grep()
				end,
				desc = "Find Grep",
			},
			{
				"<leader>ff",
				function()
					Snacks.picker.files({ hidden = true, ignored = true })
				end,
				desc = "Find Files",
			},

			-- List
			{
				"<leader>lb",
				function()
					Snacks.picker.buffers({
						win = {
							input = {
								keys = { ["<c-d>"] = { "bufdelete", mode = { "n", "i" } } },
							},
						},
					})
				end,
				desc = "Buffers",
			},
			{
				"<C-Tab>",
				function()
					Snacks.picker.buffers({
						current = false,
						sort_lastused = true,
						win = {
							input = {
								keys = { ["<c-d>"] = { "bufdelete", mode = { "n", "i" } } },
							},
						},
					})
				end,
				mode = { "n", "i", "v" },
				desc = "Buffers",
			},
			{
				"<leader>ld",
				function()
					Snacks.picker.diagnostics_buffer()
				end,
				desc = "Buffer Diagnostics",
			},
			{
				"<leader>lD",
				function()
					Snacks.picker.diagnostics()
				end,
				desc = "All Diagnostics",
			},
			{
				"<leader>lh",
				function()
					Snacks.picker.help()
				end,
				desc = "Help Pages",
			},
			{
				"<leader>lj",
				function()
					Snacks.picker.jumps()
				end,
				desc = "Jumps",
			},
			{
				"<leader>lk",
				function()
					Snacks.picker.keymaps()
				end,
				desc = "Keymaps",
			},
			{
				"<leader>lm",
				function()
					Snacks.picker.marks()
				end,
				desc = "Marks",
			},
			{
				"<leader>lp",
				function()
					Snacks.picker.lazy()
				end,
				desc = "Search for Plugin Spec",
			},
			{
				"<leader>lq",
				function()
					Snacks.picker.qflist()
				end,
				desc = "Quickfix List",
			},
			{
				"<leader>lC",
				function()
					Snacks.picker.colorschemes()
				end,
				desc = "Colorschemes",
			},
			{
				"<leader>ls",
				function()
					Snacks.picker.lsp_symbols()
				end,
				desc = "LSP Symbols",
			},
			{
				'<leader>l"',
				function()
					Snacks.picker.registers()
				end,
				desc = "Registers",
			},

			-- LSP
			{
				"<leader>gd",
				function()
					Snacks.picker.lsp_definitions()
				end,
				desc = "Definition",
			},
			{
				"<leader>gD",
				function()
					Snacks.picker.lsp_declarations()
				end,
				desc = "Declaration",
			},
			{
				"<leader>gr",
				function()
					Snacks.picker.lsp_references()
				end,
				nowait = true,
				desc = "References",
			},
			{
				"<leader>gi",
				function()
					Snacks.picker.lsp_implementations()
				end,
				desc = "Implementation",
			},
			{
				"<leader>gt",
				function()
					Snacks.picker.lsp_type_definitions()
				end,
				desc = "Type Definition",
			},
		},
	},
}
