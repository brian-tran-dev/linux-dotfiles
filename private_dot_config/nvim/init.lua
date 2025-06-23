local opt = vim.o
local api = vim.api

opt.termguicolors = true
-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("config.diagnostic")
opt.clipboard = "unnamedplus"
opt.number = true
opt.relativenumber = false
opt.cursorline = true
opt.autoindent = true
opt.expandtab = false
opt.tabstop = 4
opt.shiftwidth = 4
opt.wrap = false
opt.showtabline = 0
opt.scrolloff = 0
opt.smoothscroll = true
opt.display = "lastline"
opt.guicursor = "a:block,n-i-r-cr-i-ci:blinkwait500-blinkon500-blinkoff500,r-cr:hor30,i-ci-ve:ver50"

------------------------------------------------------
----------------- KEY MAPS ----------------------------
-------------------------------------------------------

--------- Miscalaneous ------------------------------
vim.keymap.set("i", "jj", "<ESC>", { noremap = true, desc = "<Escape>" })
vim.keymap.set("n", "<BS>", ":noh<Enter>", { noremap = true, desc = "Remove Highlighting" })
vim.keymap.set("c", "<Esc>", "<c-c>", { noremap = true, desc = "Cancel command line" })

vim.keymap.set("n", "<leader>gl", function()
	vim.cmd([[ edit vim.fn.expand('%:p:h') ]])
end, { noremap = true, desc = "Goto  Link/File" })

vim.keymap.set({ "n", "i" }, "<c-g>", function()
	local float_win = nil
	local wins = api.nvim_tabpage_list_wins(api.nvim_get_current_tabpage())

	for _, win in ipairs(wins) do
		local c = vim.api.nvim_win_get_config(win)
		if c.relative ~= "" and c.zindex > 0 and c.focusable then
			float_win = win
			vim.print({ "float win", win, c })
			break
		end
	end

	if float_win == nil then
		return
	end

	local height = api.nvim_win_get_height(float_win)
	local width = api.nvim_win_get_width(float_win)

	local close_win = function()
		api.nvim_win_close(float_win, true)
	end

	local move = function(d_row, d_col)
		return function()
			local pos = api.nvim_win_get_cursor(float_win)
			local row = pos[1] + d_row
			local col = pos[2] + d_col
			if row < 1 or col < 0 or row > height or col >= width then
				return
			end
			api.nvim_win_set_cursor(float_win, { pos[1] + d_row, pos[2] + d_col })
		end
	end

	local buf = api.nvim_win_get_buf(float_win)
	vim.keymap.set("i", "h", move(0, -1), { noremap = true, buffer = buf })
	vim.keymap.set("i", "j", move(1, 0), { noremap = true, buffer = buf })
	vim.keymap.set("i", "k", move(-1, 0), { noremap = true, buffer = buf })
	vim.keymap.set("i", "l", move(0, 1), { noremap = true, buffer = buf })
	vim.keymap.set({ "n", "i", "v" }, "q", close_win, { noremap = true, buffer = buf })
	vim.keymap.set({ "n", "i", "v" }, "<c-c>", close_win, { noremap = true, buffer = buf })
	vim.keymap.set("n", "<Esc>", close_win, { noremap = true, buffer = buf })

	api.nvim_set_current_win(float_win)
end, { noremap = true, desc = "Focus float window" })
--------------------------------------------------

--------- Switch Buffer ------------------------------
vim.keymap.set("n", "<leader>bh", function()
	vim.cmd([[ bprevious ]])
end, { noremap = true, desc = "Previous Buffer" })

vim.keymap.set("n", "<leader>bl", function()
	vim.cmd([[ bnext ]])
end, { noremap = true, desc = "Next Buffer" })
--------------------------------------------------

--------- Jumps ------------------------------
vim.keymap.set({ "n", "i" }, "<c-h>", "<c-o>", { noremap = true, desc = "Previous Jump" })
vim.keymap.set({ "n", "i" }, "<c-l>", "<c-i>", { noremap = true, desc = "Next Jump" })
--------------------------------------------------
