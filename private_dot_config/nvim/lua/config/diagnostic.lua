local api = vim.api

vim.diagnostic.config({
	virtual_text = true,
	float = {
		scope = "cursor",
		source = true,
		border = "rounded",
		header = "",
	},
})

local d_win = nil

local function close_diagnostic()
	if d_win ~= nil and api.nvim_win_is_valid(d_win) then
		api.nvim_win_close(d_win, false)
		d_win = nil
	end
end

local function focus_diagnostic(cb)
	if d_win == nil then
		return
	end

	api.nvim_set_current_win(d_win)
	local buf = api.nvim_get_current_buf()
	vim.keymap.set({ "n", "i", "v" }, "q", close_diagnostic, { noremap = true, buffer = buf })
	vim.keymap.set({ "n", "i", "v" }, "<c-c>", close_diagnostic, { noremap = true, buffer = buf })
	vim.keymap.set("n", "<Esc>", close_diagnostic, { noremap = true, buffer = buf })
	cb(buf)
end

local function show_diagnostic(locate_diagnostic)
	return function()
		close_diagnostic()

		if locate_diagnostic ~= nil then
			local x = locate_diagnostic()
			if x == nil then
				return
			end
			api.nvim_win_set_cursor(0, { x.lnum + 1, x.col })
		end

		_, d_win = vim.diagnostic.open_float()

		focus_diagnostic(function(buf)
			vim.keymap.set( "n", "<leader>dn", show_diagnostic(vim.diagnostic.get_next), { desc = "Next diagnostic error", buffer = buf })
			vim.keymap.set( "n", "<leader>dp", show_diagnostic(vim.diagnostic.get_prev), { desc = "Next diagnostic error", buffer = buf })
			vim.keymap.set( "n", "<leader>ds", "<nop>", { desc = "", buffer = buf })
		end)
	end
end

vim.keymap.set("n", "<leader>dn", show_diagnostic(vim.diagnostic.get_next), { desc = "Next diagnostic error" })
vim.keymap.set("n", "<leader>dp", show_diagnostic(vim.diagnostic.get_prev), { desc = "Next diagnostic error" })
vim.keymap.set("n", "<leader>ds", show_diagnostic(nil), { desc = "Show diagnostic" })

