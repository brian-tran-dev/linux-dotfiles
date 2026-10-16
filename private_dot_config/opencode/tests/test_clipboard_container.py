"""Live text-only clipboard smoke test; restores the previous text in memory."""

import os
import re
import subprocess
import sys
import time


def main():
    home = os.environ["HOME"]
    runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    base = ["xclip", "-selection", "clipboard"]

    def read(target=None):
        args = base + ["-out"] + (["-target", target] if target else [])
        return subprocess.run(args, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                              stderr=subprocess.DEVNULL, check=True, timeout=3).stdout

    def write(data):
        subprocess.run(base + ["-in"], input=data, stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL, check=True, timeout=3)

    targets = read("TARGETS").decode("ascii", errors="replace").splitlines()
    if any(target.startswith(("image/", "application/")) or target in ("text/html", "text/uri-list")
           for target in targets):
        print("SKIP: preserving rich clipboard formats; run after copying plain text.")
        return
    original = read()
    incoming = "Host clipboard → container 🐱"
    outgoing = "Container yank → host tiếng Việt"
    setup = r"""
local path = vim.fn.expand('~/.config/nvim/init.lua')
assert(loadfile(path))
local lines = {}
for _, line in ipairs(vim.fn.readfile(path)) do
  if line:match('^require') then break end
  table.insert(lines, line)
end
assert(loadstring(table.concat(lines, '\n')))()
vim.o.clipboard = 'unnamedplus'
assert(vim.fn['provider#clipboard#Executable']() == 'Host clipboard bridge', 'Wrong provider')
assert(type(vim.g.clipboard.copy['+']) == 'table', 'Copy must use the helper')
assert(type(vim.g.clipboard.paste['+']) == 'table', 'Paste must use the helper')
assert(vim.fn.getreg('+') == 'Host clipboard → container 🐱', 'Host read mismatch')
vim.api.nvim_buf_set_lines(0, 0, -1, false, {''})
vim.cmd('normal! p')
assert(vim.api.nvim_buf_get_lines(0, 0, -1, false)[1] == 'Host clipboard → container 🐱', 'Normal p mismatch')
vim.api.nvim_buf_set_lines(0, 0, -1, false, {'Container yank → host tiếng Việt'})
vim.api.nvim_win_set_cursor(0, {1, 0})
vim.cmd('normal! yy')
"""
    # Clipboard writes are deferred until the Lua/Ex command completes.
    linewise = r"""
assert(vim.fn.getregtype('+') == 'V', 'Linewise type lost')
assert(vim.fn.getreg('+') == 'Container yank → host tiếng Việt\n', 'Linewise text mismatch')
vim.cmd('normal! 0y$')
"""
    charwise = r"""
assert(vim.fn.getregtype('+') == 'v', 'Characterwise type lost')
assert(vim.fn.getreg('+') == 'Container yank → host tiếng Việt', 'Characterwise text mismatch')
local started = vim.uv.hrtime()
vim.env.OPENCODE_CLIPBOARD_SOCKET = vim.env.OPENCODE_CLIPBOARD_SOCKET .. '.missing'
vim.fn.system({'python3', vim.fn.expand('~/.config/opencode/helpers/clipboard.py'), 'paste'})
assert(vim.v.shell_error ~= 0, 'Missing bridge unexpectedly succeeded')
assert((vim.uv.hrtime() - started) / 1e9 < 1, 'Missing bridge did not fail quickly')
print('PASS: normal p, yy, characterwise yank, Unicode, register types, and fast failure')
"""
    command = [
        "podman", "run", "--rm", "--network", "none",
        "--env", f"HOME={home}",
        "--env", f"OPENCODE_CLIPBOARD_SOCKET={runtime}/opencode-clipboard/clipboard.sock",
        "--mount", f"type=bind,src={home}/.config/nvim,dst={home}/.config/nvim,ro",
        "--mount", f"type=bind,src={home}/.config/opencode/helpers,dst={home}/.config/opencode/helpers,ro",
        "--mount", f"type=bind,src={runtime}/opencode-clipboard,dst={runtime}/opencode-clipboard,ro",
        "--entrypoint", "nvim", "localhost/opencode-dev:brian-personal-editor",
        "--headless", "-u", "NONE", "-i", "NONE",
        "+lua " + setup, "+lua " + linewise, "+lua " + charwise, "+qa!",
    ]
    try:
        write(incoming.encode())
        started = time.monotonic()
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=20)
        osc52_any = re.compile(rb"\x1b\]52;[^\x07\x1b]*(?:\x07|\x1b\\)")
        if result.returncode or b"PASS:" not in result.stderr:
            sys.stderr.write(osc52_any.sub(b"", result.stderr).decode(errors="replace"))
            raise RuntimeError("Container Neovim clipboard test failed")
        output = result.stdout + result.stderr
        assert b"\x1b]52;" not in output, "Unexpected OSC 52 clipboard request"
        assert read() == outgoing.encode(), "Host clipboard write mismatch"
        print(osc52_any.sub(b"", result.stderr).decode().strip())
        print(f"PASS: real X11 round-trip in {time.monotonic() - started:.2f}s without container display/network access")
    finally:
        if read() in (incoming.encode(), outgoing.encode(), (outgoing + "\n").encode()):
            write(original)
            print("Original clipboard text restored; never logged or written to disk.")
        else:
            print("Clipboard changed independently; leaving its current contents untouched.")


if __name__ == "__main__":
    main()
