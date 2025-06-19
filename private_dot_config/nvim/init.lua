local opt = vim.o
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

vim.keymap.set("i", "jj", "<ESC>", { noremap = true, desc = "<Escape>" })
vim.keymap.set("n", "<BS>", ":noh<Enter>", { noremap = true, desc = "Remove Highlighting" })
vim.keymap.set("n", "<leader>gl", function ()
	vim.cmd[[ edit vim.fn.expand('%:p:h') ]]
end, { noremap = true, desc = "Link/File" })
vim.keymap.set("n", "<leader>bh", function ()
	vim.cmd[[ bprevious ]]
end, { noremap = true, desc = "Previous Buffer" })
vim.keymap.set("n", "<leader>bl", function ()
	vim.cmd[[ bnext ]]
end, { noremap = true, desc = "Next Buffer" })
vim.keymap.set("n", "<leader>bl", function ()
	vim.cmd[[ bnext ]]
end, { noremap = true, desc = "Next Buffer" })
vim.keymap.set(
	{"n", "i"}, "<c-h>", "<c-o>",
	{ noremap = true, desc = "Previous Jump" }
)
vim.keymap.set(
	{"n", "i"}, "<c-l>", "<c-i>",
	{ noremap = true, desc = "Next Jump" }
)
