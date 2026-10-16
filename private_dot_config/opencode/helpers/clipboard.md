# Container Neovim clipboard

The host `opencode-clipboard.service` exposes only text clipboard copy/paste over
`$XDG_RUNTIME_DIR/opencode-clipboard/clipboard.sock`. It runs `xclip` on the host;
the container does not receive `DISPLAY`, Xauthority, or an X11 socket.

After restoring these files with chezmoi, reload the user service manager:

```sh
systemctl --user daemon-reload
```

`chat` imports the host's `DISPLAY` and `XAUTHORITY` into the user service manager,
starts the service, and mounts only its private socket directory read-only. Start
a new `chat` container after installing this bridge; an existing container cannot
pick up the new mount or environment variable. No image rebuild is needed.

Inside Podman, Neovim uses this provider for `+` and `*`, both mapped to the host
system clipboard. With `unnamedplus`, ordinary yank and `p` use that clipboard
through the Python helper and host service. No OSC 52 clipboard requests are
sent. Host Neovim's clipboard remains unchanged. The client is Python's standard
library only.

The directory is mode 0700, the socket mode 0600, and only the host user's peer
UID is accepted. Rootless Podman's default root mapping uses that same host UID.
Custom user-namespace mappings may need a different permission design. Clipboard
contents are not logged or written to temporary files. Text is limited to 1 MiB;
backend operations time out after two seconds and client requests after three.
Images, rich MIME formats, and X11 primary selection are not supported.

Every process with access to the mounted socket can read or overwrite the host
clipboard, including sensitive text copied elsewhere. The read-only mount does
not make socket operations read-only; it protects the directory entries.

For diagnostics:

```sh
systemctl --user status opencode-clipboard.service
PYTHONDONTWRITEBYTECODE=1 python3 ~/.config/opencode/tests/test_clipboard.py
```

The optional live smoke test below uses a short-lived container with networking
disabled. It verifies helper-based copy and paste, skips rich clipboard formats,
and temporarily replaces plain text, restoring the previous text in memory
afterward (unless you copy something else during the test):

```sh
PYTHONDONTWRITEBYTECODE=1 python3 ~/.config/opencode/tests/test_clipboard_container.py
```

If your display environment changes while the service is running, import the new
variables into the user manager and restart the service. Its runtime directory
is preserved, so live container mounts see the replacement socket.
