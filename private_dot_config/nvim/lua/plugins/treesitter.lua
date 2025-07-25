return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	lazy = false,
	--- @type TSConfig
	--- @diagnostic disable-next-line: missing-fields
	opts = {
		sync_install = false,
		auto_install = true,
		highlight = { enable = true },
		indent = { enable = true },
		ensure_installed = {
			"markdown",
			"markdown_inline",
			"bash",
			"c",
			"cmake",
			"cpp",
			"lua",
			"luadoc",
			"vim",
			"vimdoc",
			"query",
			"javascript",
			"html",
			"css",
			"typescript",
			"tsx",
			"csv",
			"tsv",
			"dot",
			"diff",
			"git_config",
			"git_rebase",
			"gitattributes",
			"gitcommit",
			"gitignore",
			"http",
			"java",
			"json",
			"jsonc",
			"jsdoc",
			"python",
			"regex",
			"scss",
			"sql",
			-- "svelte",
			"toml",
			"yaml",
			"php",
			-- "phpdoc",
			-- "pioasm",
			"tmux",
		}
	},
	config = function(_, opts)
		require("nvim-treesitter.configs").setup(opts)
	end,
}
