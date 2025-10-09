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
opt.cmdheight = 1

api.nvim_set_hl(0, "NormalFloat", { bg = "#403b42" })
api.nvim_set_hl(0, "FloatBorder", { bg = "#403b42", fg = "#6b6d80" })
api.nvim_set_hl(0, "FloatTitle", { bg = "#403b42", fg = "#a7f3d0" })
api.nvim_set_hl(0, "LineNr", { fg = "#9390a6" })
api.nvim_set_hl(0, "CursorLineNr", { fg = "white" })

vim.filetype.add({
	extension = {
		ejs = "html",
	},
})

------------------------------------------------------
----------------- KEY MAPS ----------------------------
-------------------------------------------------------

--------- Miscalaneous ------------------------------
vim.keymap.set("i", "jj", "<ESC>", { noremap = true, desc = "<Escape>" })
vim.keymap.set("n", "<BS>", ":noh<Enter>", { noremap = true, desc = "Remove Highlighting" })
vim.keymap.set("c", "<Esc>", "<c-c>", { noremap = true, desc = "Cancel command line" })
vim.keymap.set("n", "<leader>ww", "<Cmd>w<CR>", { noremap = true, desc = "Save" })
vim.keymap.set("n", "<leader>wq", "<Cmd>wq<CR>", { noremap = true, desc = "Save & Close" })
vim.keymap.set("n", "<leader>wa", "<Cmd>wqa<CR>", { noremap = true, desc = "Save & Close All" })
vim.keymap.set("n", "<leader>qq", "<Cmd>q<CR>", { noremap = true, desc = "Close" })
vim.keymap.set("n", "<leader>qa", "<Cmd>qa<CR>", { noremap = true, desc = "Close all" })
vim.keymap.set("n", "<leader>;;", ":", { noremap = true, desc = "Vim command" })
vim.keymap.set("n", "<leader>;l", ":lua ", { noremap = true, desc = "Lua command" })
vim.keymap.set("n", "<leader>;h", ":help ", { noremap = true, desc = "Help command" })
vim.keymap.set("n", "<leader>sm", "<cmd>messages<cr>", { noremap = true, desc = "Show messages" })

vim.keymap.set("n", "<leader>gl", function()
	vim.cmd([[ edit vim.fn.expand('%:p:h') ]])
end, { noremap = true, desc = "Goto  Link/File" })

local bufs_with_exit_shortcuts = {}
api.nvim_create_autocmd("BufEnter", {
	pattern = "*",
	callback = function(args)
		local buf = args.buf
		if not vim.bo[buf].modifiable and bufs_with_exit_shortcuts[buf] == nil then
			bufs_with_exit_shortcuts[buf] = true
			vim.keymap.set({ "n", "v" }, "q", function()
				api.nvim_buf_delete(buf, { force = true })
			end, { buffer = buf, noremap = true, desc = "Exit" })
			vim.keymap.set({ "n", "v", "c", "i" }, "<C-c>", function()
				api.nvim_buf_delete(buf, { force = true })
			end, { buffer = buf, noremap = true, desc = "Exit" })
		end
	end,
})
api.nvim_create_autocmd({ "BufDelete", "BufUnload", "BufHidden" }, {
	pattern = "*",
	callback = function(args)
		if bufs_with_exit_shortcuts[args.buf] then
			bufs_with_exit_shortcuts[args.buf] = nil
		end
	end,
})
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

require("init_python_loader")
require("neovide")
