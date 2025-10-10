-- pencil mode
vim.keymap.set(
	"n", "<leader>.tp",
	function()
		vim.cmd[[ TogglePencil ]]
	end,
	{ desc = "Toggle Writer(Pencil) Mode"}
)

vim.cmd[[ PencilSoft ]]
