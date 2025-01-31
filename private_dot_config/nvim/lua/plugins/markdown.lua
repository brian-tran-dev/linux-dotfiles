return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
	opts = {
		render_modes = true,
		checkbox = {
			enabled = true,
			position = "inline",
			unchecked = {
				icon = "󰄱 ",
				rendered = "󰄱 ",
				highlight = "RenderMarkdownUnchecked",
				scope_highlight = nil,
			},
			checked = {
				icon = "󰱒 ",
				rendered = "󰱒 ",
				highlight = "RenderMarkdownChecked",
				scope_highlight = nil,
			},
			custom = {
				my_due1 = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo", scope_highlight = nil },
				my_checked1 = { raw = "[x]", rendered = "󰱒 ", highlight = "RenderMarkdownChecked", scope_highlight = nil },
				my_checked2 = { raw = "[o]", rendered = "󰱒 ", highlight = "RenderMarkdownChecked", scope_highlight = nil },
				my_unchecked1 = { raw = "[ ]", rendered = "󰄱 ", highlight = "RenderMarkdownUnchecked", scope_highlight = nil },
				my_unchecked2 = { raw = "[.]", rendered = "󰄱 ", highlight = "RenderMarkdownUnchecked", scope_highlight = nil },
			},
		},
	},
}
