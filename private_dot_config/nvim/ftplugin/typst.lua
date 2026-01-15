-- pencil mode
vim.g['pencil#wrapModeDefault'] = 'soft'
vim.keymap.set(
	"n", "<leader>.tp",
	function()
		vim.cmd[[ TogglePencil ]]
	end,
	{ desc = "Toggle Writer(Pencil) Mode"}
)
