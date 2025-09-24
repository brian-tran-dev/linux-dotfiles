return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	branch = "main",
	build = ":TSUpdate",
	config = function()
		local ts = require("nvim-treesitter")

		-- Required baseline parsers
		local required = {
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
			-- "python",
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

		--------------------------------------------------------------------
		-- Compare required vs installed, install only missing ones
		--------------------------------------------------------------------
		local installed_set = {}
		local function update_installed_set()
			for _, l in ipairs(ts.get_installed() or {}) do
				installed_set[l] = true
			end
		end
		update_installed_set()

		local missing = {}
		for _, lang in ipairs(required) do
			if not installed_set[lang] then
				table.insert(missing, lang)
			end
		end

		if #missing > 0 then
			vim.notify("Installing missing Treesitter parsers: " .. table.concat(missing, ", "))
			ts.install(missing):wait(300000) -- wait up to 5 minutes
			update_installed_set()
		end

		local available_set = {}
		for _, l in ipairs(ts.get_available(1) or {}) do
			available_set[l] = true
		end
		for _, l in ipairs(ts.get_available(2) or {}) do
			available_set[l] = true
		end
		for _, l in ipairs(ts.get_available(3) or {}) do
			available_set[l] = true
		end

		--------------------------------------------------------------------
		-- Helper: install parser for current buffer’s filetype if missing
		--------------------------------------------------------------------
		local function install_current_parser(bufnr)
			bufnr = bufnr or 0
			local ft = vim.bo[bufnr].filetype
			if not ft or ft == "" then
				return
			end

			local lang = vim.treesitter.language.get_lang(ft)
			if not lang then
				return
			end

			if installed_set[lang] then
				vim.treesitter.start(bufnr, lang)
				return
			end

			if available_set[lang] then
				vim.notify(("Installing Treesitter parser for %s..."):format(lang))
				ts.install({ lang }):wait(300000)
				update_installed_set()
				vim.treesitter.start(bufnr, lang)
			end
		end

		vim.api.nvim_create_user_command("TSInstallCurrent", function()
			install_current_parser(0)
		end, { desc = "Install parser for current buffer" })

		vim.keymap.set(
			'n', '<leader>001',
			function() install_current_parser(0) end,
			{ noremap = true, desc = 'Install treesitter parser for current buffer' }
		)

		--------------------------------------------------------------------
		-- Autocmd: start highlighting if parser is installed
		--------------------------------------------------------------------
		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("TSHighlightStart", { clear = true }),
			callback = function(args)
				install_current_parser(args.buf)
			end,
		})
	end,
}
