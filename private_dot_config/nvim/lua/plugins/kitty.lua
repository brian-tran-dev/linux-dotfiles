return {
	"mikesmithgh/kitty-scrollback.nvim",
	enabled = true,
	lazy = true,
	cmd = {
		"KittyScrollbackGenerateKittens",
		"KittyScrollbackCheckHealth",
		"KittyScrollbackGenerateCommandLineEditing",
	},
	event = { "User KittyScrollbackLaunch" },
	-- version = '*', -- latest stable version, may have breaking changes if major version changed
	-- version = '^6.0.0', -- pin major version, include fixes and features that do not have breaking changes
	config = function()
		require("kitty-scrollback").setup({
			{
				paste_window = { yank_register_enabled = false },
				callbacks = {
					after_ready = function()
						local buffer = vim.api.nvim_get_current_buf()
						-- These maps exist only in the Ctrl+F, [ scrollback buffer.
						-- Use Kitty's clipboard transport so copying survives quitting
						-- Neovim and does not depend on xclip's process lifetime.
						local function copy(lines)
							local text = table.concat(lines, "\n")
							vim.fn.setreg('"', text)
							local command = { "kitten", "clipboard", "--wait-for-completion" }
							if vim.fn.executable("kitten") == 0 then
								command = { "kitty", "+kitten", "clipboard", "--wait-for-completion" }
							end
							vim.system(command, { stdin = text }, function(result)
								vim.schedule(function()
									if result.code == 0 then
										vim.notify("Copied to clipboard")
									else
										vim.notify(result.stderr, vim.log.levels.ERROR)
									end
								end)
							end)
						end
						vim.keymap.set("x", "y", function()
							-- Read the visual region without triggering the plugin's
							-- clipboard-yank autocmd, which auto-closes the viewer.
							copy(vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), {
								type = vim.fn.mode(),
								exclusive = vim.o.selection == "exclusive",
							}))
							vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
						end, { buffer = buffer, desc = "Copy selection to clipboard" })
						vim.keymap.set("n", "yy", function()
							copy({ vim.api.nvim_get_current_line() })
						end, { buffer = buffer, desc = "Copy line to clipboard" })
						vim.keymap.set({ "n", "x" }, "q", "<Cmd>qa!<CR>", {
							buffer = buffer,
							desc = "Quit scrollback and return to Kitty",
						})
					end,
				},
			},
		})
	end,
}
