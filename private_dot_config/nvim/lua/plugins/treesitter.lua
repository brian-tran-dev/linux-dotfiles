return {
	{
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
				"go",
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

			vim.keymap.set("n", "<leader>001", function()
				install_current_parser(0)
			end, { noremap = true, desc = "Install treesitter parser for current buffer" })

			--------------------------------------------------------------------
			-- Autocmd: start highlighting if parser is installed
			--------------------------------------------------------------------
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("TSHighlightStart", { clear = true }),
				pattern = "*",
				callback = function(args)
					install_current_parser(args.buf)
				end,
			})
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		config = function()
			require("nvim-treesitter-textobjects").setup({
				-- Automatically jump forward to textobj, similar to targets.vim
				lookahead = true,
				-- You can choose the select mode (default is charwise 'v')
				--
				-- Can also be a function which gets passed a table with the keys
				-- * query_string: eg '@function.inner'
				-- * method: eg 'v' or 'o'
				-- and should return the mode ('v', 'V', or '<c-v>') or a table
				-- mapping query_strings to modes.
				selection_modes = {
					["@parameter.outer"] = "v", -- charwise
					["@function.outer"] = "V", -- linewise
					["@class.outer"] = "<c-v>", -- blockwise
				},
				-- If you set this to `true` (default is `false`) then any textobject is
				-- extended to include preceding or succeeding whitespace. Succeeding
				-- whitespace has priority in order to act similarly to eg the built-in
				-- `ap`.
				--
				-- Can also be a function which gets passed a table with the keys
				-- * query_string: eg '@function.inner'
				-- * selection_mode: eg 'v'
				-- and should return true of false
				include_surrounding_whitespace = false,

				move = {
					set_jumps = true,
				},
			})

			------------------------- SELECT -------------------------------
			local select = require("nvim-treesitter-textobjects.select")

			-- You can use the capture groups defined in `textobjects.scm`
			vim.keymap.set({ "x", "o" }, "af", function()
				select.select_textobject("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "if", function()
				select.select_textobject("@function.inner", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ac", function()
				select.select_textobject("@class.outer", "textobjects")
			end)
			vim.keymap.set({ "x", "o" }, "ic", function()
				select.select_textobject("@class.inner", "textobjects")
			end)
			-- You can also use captures from other query groups like `locals.scm`
			vim.keymap.set({ "x", "o" }, "as", function()
				select.select_textobject("@local.scope", "locals")
			end)
			--------------------------------------------------------------

			------------------------- MOVE -------------------------------
			local move = require("nvim-treesitter-textobjects.move")
			-- You can use the capture groups defined in `textobjects.scm`
			vim.keymap.set({ "n", "x", "o" }, "]m", function()
				move.goto_next_start("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "]]", function()
				move.goto_next_start("@class.outer", "textobjects")
			end)
			-- You can also pass a list to group multiple queries.
			vim.keymap.set({ "n", "x", "o" }, "]o", function()
				move.goto_next_start({ "@loop.inner", "@loop.outer" }, "textobjects")
			end)
			-- You can also use captures from other query groups like `locals.scm` or `folds.scm`
			vim.keymap.set({ "n", "x", "o" }, "]s", function()
				move.goto_next_start("@local.scope", "locals")
			end)
			vim.keymap.set({ "n", "x", "o" }, "]z", function()
				move.goto_next_start("@fold", "folds")
			end)

			vim.keymap.set({ "n", "x", "o" }, "]M", function()
				move.goto_next_end("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "][", function()
				move.goto_next_end("@class.outer", "textobjects")
			end)

			vim.keymap.set({ "n", "x", "o" }, "[m", function()
				move.goto_previous_start("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[[", function()
				move.goto_previous_start("@class.outer", "textobjects")
			end)

			vim.keymap.set({ "n", "x", "o" }, "[M", function()
				move.goto_previous_end("@function.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[]", function()
				move.goto_previous_end("@class.outer", "textobjects")
			end)

			-- Go to either the start or the end, whichever is closer.
			-- Use if you want more granular movements
			vim.keymap.set({ "n", "x", "o" }, "]d", function()
				move.goto_next("@conditional.outer", "textobjects")
			end)
			vim.keymap.set({ "n", "x", "o" }, "[d", function()
				move.goto_previous("@conditional.outer", "textobjects")
			end)
			--------------------------------------------------------------
		end,
	},
}
