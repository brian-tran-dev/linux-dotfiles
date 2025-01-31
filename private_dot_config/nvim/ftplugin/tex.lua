-- compile tex file
vim.keymap.set(
	"n", "<leader>.c",
	function()
		vim.cmd[[ w | !lualatex %:p ]]
	end,
	{ desc = "Compile current TEX file"}
)
vim.keymap.set(
	"n", "<leader>.tp",
	function()
		vim.cmd[[ TogglePencil ]]
	end,
	{ desc = "Toggle Writer(Pencil) Mode"}
)

vim.cmd[[ PencilSoft | TwilightEnable ]]
