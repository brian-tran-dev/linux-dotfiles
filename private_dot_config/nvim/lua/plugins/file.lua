return {
	{
		"stevearc/oil.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			{ "echasnovski/mini.icons", opts = {} },
		},
		opts = {
			columns = { "size", "icon" },
			view_options = {
				show_hidden = true,

				-- This function defines what is considered a "hidden" file
				is_hidden_file = function(name)
					local m = name:match("^(%.)")
					return m ~= nil
				end,

				is_always_hidden = function(name)
					return name == ".."
				end,
			},
			float = {
				padding = 2,
				border = "rounded",
				-- max_width = 30,
				max_height = 10,
				preview_split = "right",
				override = function(conf)
					return vim.tbl_deep_extend("force", conf, {
						relative = "editor",
						anchor = "SW",
						row = 0,
						col = 0,
					})
				end,
			},
			preview_win = {
				update_on_cursor_moved = true,
				-- How to open the preview window "load"|"scratch"|"fast_scratch"
				preview_method = "fast_scratch",
				-- A function that returns true to disable preview on a file e.g. to avoid lag
				disable_preview = function()
					return false
				end,
			},
			use_default_keymaps = false,
			keymaps = {
				["g?"] = { "actions.show_help", mode = "n" },
				["<C-l>"] = "actions.select",
				["<leader>gv"] = { "actions.select", opts = { vertical = true } },
				["<leader>gh"] = { "actions.select", opts = { horizontal = true } },
				["<C-c>"] = { "actions.close", mode = { "n", "i", "v" } },
				["<ESC>"] = { "actions.close", mode = "n" },
				["q"] = { "actions.close", mode = "n" },
				["<C-s>"] = { "actions.close", mode = { "n", "i", "v" } },
				["<leader>r"] = "actions.refresh",
				["<C-h>"] = { "actions.parent", mode = "n" },
				["<leader>cs"] = { "actions.change_sort", mode = "n" },
				["<leader>t."] = { "actions.toggle_hidden", mode = "n" },
				["<leader>tt"] = { "actions.toggle_trash", mode = "n" },
				["<leader>sp"] = { "actions.preview", opts = { split = "belowright", vertical = true } },
			},
		},
		keys = {
			{
				"<leader>se",
				function()
					require("oil").open_float(nil, { preview = { vertical = true, split = "aboveleft" } })
				end,
				noremap = true,
				desc = "File Explorer",
			},
			{
				"<C-s>",
				function()
					require("oil").open_float(nil, { preview = { vertical = true, split = "aboveleft" } })
				end,
				mode = { "n", "v", "i" },
				noremap = true,
				desc = "File Explorer",
			},
		},
	},

	{
		"JezerM/oil-lsp-diagnostics.nvim",
		dependencies = { "stevearc/oil.nvim" },
		opts = {},
	},
}
