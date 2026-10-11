-- Run with nvim --clean --headless -l this-file.lua.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local options
package.preload["kitty-scrollback"] = function()
	return { setup = function(value) options = value[1] end }
end
local captured
vim.system = function(command, opts, callback)
	captured = { command = command, text = opts.stdin }
	callback({ code = 0 })
end
local plugin = dofile(root .. "/lua/plugins/kitty.lua")
plugin.config()
assert(options.paste_window.yank_register_enabled == false)
local buffer = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(buffer)
vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "abcdef", "second line" })
options.callbacks.after_ready()
local function mapping(mode, key)
	for _, map in ipairs(vim.api.nvim_buf_get_keymap(buffer, mode)) do
		if map.lhs == key then return map end
	end
	error("Missing map " .. key)
end
assert(mapping("n", "q").rhs == "<Cmd>qa!<CR>")
mapping("n", "yy").callback()
assert(captured.text == "abcdef")
assert(captured.command[#captured.command] == "--wait-for-completion")
vim.cmd.normal({ "gg0v2l", bang = true })
mapping("x", "y").callback()
assert(captured.text == "abc", "Visual copy did not preserve the selection")
vim.api.nvim_set_current_buf(vim.api.nvim_create_buf(false, true))
assert(vim.fn.maparg("q", "n") == "", "q leaked into an ordinary buffer")
assert(vim.fn.maparg("y", "x") == "", "y leaked into an ordinary buffer")
print("Kitty scrollback clipboard and buffer-local maps: OK")
vim.cmd.qa({ bang = true })
