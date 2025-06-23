return {
	{
		"stevearc/oil.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
		config = function()
			local oil = require("oil")
			vim.keymap.set("n", "<leader>e", oil.open_float, {
				desc = "Open File Explorer",
			})
			oil.setup({
				view_options = {
					show_hidden = true,
				},
				float = {
					padding = 0,
					-- max_width = 30,
					max_height = 10,
					override = function(conf)
						return vim.tbl_deep_extend("force", conf, {
							relative = 'editor',
							anchor = "SW",
							row = 0,
							col = 0,
							border = "rounded",
						})
					end,
				},
				preview_win = {
					disable_preview = function(_)
						return true
					end,
				},
				keymaps = {
					["<leader>o?"] = { "actions.show_help", mode = "n" },
					["<CR>"] = "actions.select",
					["<leader>ov"] = { "actions.select", opts = { vertical = true } },
					["<leader>oh"] = { "actions.select", opts = { horizontal = true } },
					-- ["<C-t>"] = { "actions.select", opts = { tab = true } },
					-- ["<leader>p"] = "actions.preview",
					["<C-c>"] = { "actions.close", mode = "n" },
					["<ESC>"] = { "actions.close", mode = "n" },
					["<leader>or"] = "actions.refresh",
					["<leader>op"] = { "actions.parent", mode = "n" },
					-- ["<leader>o_"] = { "actions.open_cwd", mode = "n" },
					-- ["<leader>o`"] = { "actions.cd", mode = "n" },
					-- ["<leader>o~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
					["<leader>os"] = { "actions.change_sort", mode = "n" },
					-- ["<leader>e"] = "actions.open_external",
					["<leader>o."] = { "actions.toggle_hidden", mode = "n" },
					["<leader>o\\"] = { "actions.toggle_trash", mode = "n" },
				},
			})
		end,
	},
}
