return {
	'sainnhe/sonokai',
	lazy = false,
	priority = 1000,

	config = function()
		vim.g.sonokai_style = "shusia"
		vim.cmd [[
			silent! colorscheme sonokai
			hi Normal guibg=#262527
			hi CursorLine guibg=#383739
		]]
	end
}
