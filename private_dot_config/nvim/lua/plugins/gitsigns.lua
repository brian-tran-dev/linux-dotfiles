return {
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup()
		end,
	},
	{
		"esmuellert/codediff.nvim",
		cmd = "CodeDiff",
		opts = {
			-- Diff view behavior
			diff = {
				layout = "inline", -- Diff layout: "side-by-side" (two panes) or "inline" (single pane with virtual lines)
			},

			-- Explorer panel configuration
			explorer = {
				view_mode = "tree", -- "list" or "tree"
				flatten_dirs = true, -- Flatten single-child directory chains in tree view
				file_filter = {
					ignore = { ".git/**", ".jj/**" }, -- Glob patterns to hide (e.g., {"*.lock", "dist/*"})
				},
			},

			-- Keymaps in diff view
			keymaps = {
				view = {
					quit = "q", -- Close diff tab
					toggle_explorer = "<leader>b", -- Toggle explorer visibility (explorer mode only)
					focus_explorer = "<leader>e", -- Focus explorer panel (explorer mode only)
					next_hunk = "<C-l>", -- Jump to next change
					prev_hunk = "<C-h>", -- Jump to previous change
					next_file = "<leader>of", -- Next file in explorer/history mode
					prev_file = "<leader>if", -- Previous file in explorer/history mode
					toggle_stage = "-", -- Stage/unstage current file (works in explorer and diff buffers)
					show_help = "g?", -- Show floating window with available keymaps
					align_move = "gm", -- Temporarily align moved code blocks across panes
					toggle_layout = "t", -- Toggle between side-by-side and inline layout
					open_in_prev_tab = "<leader>gf",
				},
				explorer = {
					select = "<CR>", -- Open diff for selected file
					hover = "K", -- Show file diff preview
					refresh = "R", -- Refresh git status
					toggle_view_mode = "i", -- Toggle between 'list' and 'tree' views
					stage_all = "S", -- Stage all files
					unstage_all = "U", -- Unstage all files
					restore = "X", -- Discard changes (restore file)
					toggle_changes = "gu", -- Toggle Changes (unstaged) group visibility
					toggle_staged = "gs", -- Toggle Staged Changes group visibility
					-- Fold keymaps (Vim-style)
					fold_open = "zo", -- Open fold (expand current node)
					fold_open_recursive = "zO", -- Open fold recursively (expand all descendants)
					fold_close = "zc", -- Close fold (collapse current node)
					fold_close_recursive = "zC", -- Close fold recursively (collapse all descendants)
					fold_toggle = "za", -- Toggle fold (expand/collapse current node)
					fold_toggle_recursive = "zA", -- Toggle fold recursively
					fold_open_all = "zR", -- Open all folds in tree
					fold_close_all = "zM", -- Close all folds in tree
				},
				history = {
					select = "<CR>", -- Select commit/file or toggle expand
					toggle_view_mode = "i", -- Toggle between 'list' and 'tree' views
					refresh = "R", -- Refresh history (re-fetch commits)
					-- Fold keymaps (Vim-style, apply to directory nodes only)
					fold_open = "zo", -- Open fold (expand current node)
					fold_open_recursive = "zO", -- Open fold recursively (expand all descendants)
					fold_close = "zc", -- Close fold (collapse current node)
					fold_close_recursive = "zC", -- Close fold recursively (collapse all descendants)
					fold_toggle = "za", -- Toggle fold (expand/collapse current node)
					fold_toggle_recursive = "zA", -- Toggle fold recursively
					fold_open_all = "zR", -- Open all folds in tree
					fold_close_all = "zM", -- Close all folds in tree
				},
				conflict = {
					accept_incoming = "<leader>ct", -- Accept incoming (theirs/left) change
					accept_current = "<leader>co", -- Accept current (ours/right) change
					accept_both = "<leader>cb", -- Accept both changes (incoming first)
					discard = "<leader>cx", -- Discard both, keep base
					-- Accept all (whole file) - uppercase versions
					accept_all_incoming = "<leader>cT", -- Accept ALL incoming changes
					accept_all_current = "<leader>cO", -- Accept ALL current changes
					accept_all_both = "<leader>cB", -- Accept ALL both changes
					discard_all = "<leader>cX", -- Discard ALL, reset to base
					next_conflict = "<leader>ox", -- Jump to next conflict
					prev_conflict = "<leader>ix", -- Jump to previous conflict
					diffget_incoming = "2do", -- Get hunk from incoming (left/theirs) buffer
					diffget_current = "3do", -- Get hunk from current (right/ours) buffer
				},
			},
		},
	},
}
