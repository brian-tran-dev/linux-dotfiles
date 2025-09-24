-- Neovim Python 3 provider via uv + stdpath
local data = vim.fn.stdpath("data")
local venv = vim.fs.joinpath(data, "python_venv")

-- OS-aware python path inside the venv
local is_win = (vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1)

-- Canonicalize python path (prefer realpath; fallback to resolve)
local function canonicalize(p)
	if vim.fn.exists("*realpath") == 1 then
		local rp = vim.fn.realpath(p)
		if rp ~= "" then
			return rp
		end
	end
	return vim.fn.resolve(p)
end

local python = ""
if is_win then
	python = canonicalize(vim.fs.joinpath(venv, "Scripts", "python.exe" ))
else
	python = canonicalize(vim.fs.joinpath(venv, "bin", "python" ))
end

-- Helper: safely shell-escape a path
local function shesc(p)
	return vim.fn.shellescape(p)
end

-- Ensure uv exists
local function have_uv()
	return vim.fn.executable("uv") == 1
end

-- Create venv + install pynvim if missing
local function ensure_env()
	if vim.fn.executable(python) == 1 then
		return
	end
	if not have_uv() then
		vim.notify("uv not found: install uv first (https://docs.astral.sh/uv/).", vim.log.levels.ERROR)
		return
	end
	vim.notify("Bootstrapping Neovim Python provider with uv…", vim.log.levels.INFO)
	os.execute("uv venv " .. shesc(venv))
	-- Install pip (upgrade) + pynvim in one go
	os.execute(shesc(python) .. " -m pip install --upgrade pip pynvim")
end

-- Main
ensure_env()
vim.g.python3_host_prog = python
