if vim.g.neovide then
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		pattern = "/tmp/*/screen.txt", -- * matches anything except "/": exactly one level
		desc = "Start at bottom for /tmp/*/screen.txt",
		callback = function()
			vim.schedule(function()
				local last = vim.api.nvim_buf_line_count(0)
				vim.api.nvim_win_set_cursor(0, { last, 0 })
			end)
		end,
	})

	vim.keymap.set({ "n", "v" }, "<C-=>", ":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + 0.1<CR>")
	vim.keymap.set({ "n", "v" }, "<C-->", ":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor - 0.1<CR>")
	vim.keymap.set({ "n", "v" }, "<C-0>", ":lua vim.g.neovide_scale_factor = 1<CR>")

	vim.g.neovide_fullscreen = true
end
