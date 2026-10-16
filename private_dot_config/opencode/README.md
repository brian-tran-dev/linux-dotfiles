# OpenCode, Herdr and Kitty

## Prompt editor

Use `/editor` or **Ctrl+T, E** to edit the current prompt in terminal Neovim.
`:wq` saves and returns to OpenCode; press Enter to send the updated prompt.
`:q!` discards unsaved edits. No GUI editor or file-opening integration is used.

Fish exports `EDITOR=nvim` and `VISUAL=nvim`. The `opencode` function and the
`chat` container launcher also set both explicitly.

## Container

Build the editor-enabled image without changing the original development image:

```sh
podman build --network host \
  --tag localhost/opencode-dev:brian-personal-editor \
  "$HOME/.config/opencode/container"
```

The base image `localhost/opencode-dev:brian-personal` must already exist.
Neovim 0.11.5 is downloaded from its official release and SHA-256 verified.
Rebuild this derived image after updating the base image. Run `chat [directory]
[opencode arguments]` as usual. Existing containers are not changed; the new
image is used by the next `chat` invocation.

The existing SSH mounts are preserved. `~/.ssh/config_container` is saved in
chezmoi encrypted, like the existing SSH configuration and keys; it is not
published in plaintext.

## System notifications

```sh
systemctl --user daemon-reload
systemctl --user enable --now opencode-notify.service
```

The CLI-only `desktop-notifications` plugin runs next to the terminal client,
including when OpenCode uses a shared or remote server. It notifies for both
active and background session tabs and their child sessions:

- **Ask:** permission request or question/form; Linux Mint question sound.
- **Finish:** successful execution; freedesktop completion sound.
- **Error:** failed execution; Linux Mint error sound.

Interruptions are silent. Provider error responses and prompt contents are not
included in desktop notifications. Duplicate event IDs from multiple TUIs are
suppressed by the host bridge. Generic OpenCode and Herdr automatic notifications
are disabled to avoid duplicate sounds/popups.

The private Unix sockets live in `$XDG_RUNTIME_DIR/opencode-notify`, with mode
0600. `chat` mounts only this directory read-only, not the host D-Bus or display
sockets. When launched from a Herdr pane, it creates a proxy permitting only
that pane's official OpenCode state/session reports. Commands, input, layout
control and caller-supplied resume commands are not exposed to the container.
Registrations survive a bridge restart and reconnect after a Herdr restart.

Herdr's official OpenCode integration is installed alongside the local plugin.
To update its managed files, run `herdr integration install opencode`, then
refresh the corresponding chezmoi files. Restart the OpenCode TUI after changing
plugins; no shared OpenCode server restart is needed for these CLI plugins.

`service.json` contains a server password and is deliberately not tracked.
Runtime sockets, session snapshots, caches and logs are not tracked either.

## Herdr keys

Prefix: **Ctrl+B**. Plain and Ctrl-modified aliases are provided for common
tmux-like actions:

| After prefix | Action |
| --- | --- |
| h / j / k / l (also Ctrl-modified) | Focus pane |
| n / w (also Ctrl-modified) | New / close tab |
| u | Rename pane |
| Ctrl+u | Rename tab |
| Shift+u | Rename workspace |
| x | Close workspace |
| i / o | Previous / next tab |
| 1–9 | Select tab |
| Shift+1–9 | Select workspace |
| Alt+1–9 | Focus agent |
| I / O | Move tab earlier / later |
| f | Zoom |
| [ | Copy mode |
| s / Ctrl+s | Workspace picker |
| m | Toggle sidebar |
| q | Detach, leaving agents running |
| r | Resize mode; repeat h/j/k/l or arrows, then Esc |
| H / J / K / L | One-step directional resize |
| Left / Down / Up / Right | Split in the arrow's direction |
| Ctrl+Alt+h / j / k / l | Swap panes |
| Ctrl+Alt+s | Herdr settings |

Custom tmux key tables are replaced by these shortcuts. Ctrl+B twice forwards
the prefix to the application, instead of entering tmux's custom control table.
Tab moving and single-step resizing require the prefix each time. Pane cycling
and last-pane switching are unbound, including Tab, Shift+Tab, and Ctrl+Tab after
the prefix. There is no close-pane shortcut; `prefix+x` closes the workspace.

Herdr's `prefix+Alt+j/k` agent shortcuts are currently intercepted by Kitty's
Alt+j/k scrolling; use `prefix+Alt+1–9` to focus agents in Kitty. Ghostty and
WezTerm have their own Ctrl+B leader bindings that can intercept Herdr's prefix.

Herdr's custom UI palette mirrors Monokai Pro and tmux: white text, a dark
sidebar, the tmux status-bar gray, mint focused borders and brighter inactive
borders/secondary labels. Active and selected rows have distinct dark-purple
backgrounds, and sidebar labels are not dimmed. Pane applications retain Kitty's
ANSI palette. Every pane has a complete frame, including a single-pane tab;
focused frames are mint and inactive frames are brighter gray, with shared
edges between adjacent panes. Zoomed panes have a lavender border. The top
status-right contains ZOOM, date/time with seconds, and battery status. Inactive
pane-content dimming and tmux's custom key-table status text are not native
Herdr settings.

## Container clipboard

The Fish `chat` wrapper and container Neovim use the host clipboard bridge.
Keep `helpers/clipboard.py`, its documentation/tests, and
`~/.config/systemd/user/opencode-clipboard.service` together when saving these
dotfiles. The host needs `xclip`, and the wrapper currently mounts the host's
`~/.pyenv/versions/3.13.11` directory. See [clipboard setup and security
notes](helpers/clipboard.md) for service reloads and optional live testing.

## Kitty

**Ctrl+F, L** selects visible URLs or paths. URLs open in the browser; local
files/directories copy their absolute paths (with line/column suffixes if shown).
Bare filenames, quoted paths and soft-wrapped URLs are supported. Relative paths
prefer the focused tmux/Herdr pane or Podman's explicit workdir. Localhost URLs
without a scheme use HTTP; bare public domains use HTTPS without adding `www`.

**Ctrl+F, [** opens the Neovim scrollback viewer. Select with `v`, then **y** to
copy directly through Kitty's clipboard transport. `yy` copies the current line.
Copying stays in the viewer; **q** force-quits this viewer back to the terminal.
These maps are buffer-local and do not affect ordinary Neovim/Neovide buffers.
On the normal terminal screen, Shift+drag and Ctrl+Shift+C remain available.

## Tests

```sh
PYTHONDONTWRITEBYTECODE=1 python3 ~/.config/kitty/test_local_links.py
PYTHONDONTWRITEBYTECODE=1 python3 ~/.config/herdr/test_helpers.py
PYTHONDONTWRITEBYTECODE=1 python3 ~/.config/opencode/tests/test_clipboard.py
PYTHONDONTWRITEBYTECODE=1 python3 ~/.config/opencode/tests/test_notify.py
bun test ~/.config/opencode/plugins/desktop-notifications/events.test.ts
nvim --clean --headless -i NONE -n -l ~/.config/nvim/tests/kitty_scrollback.lua
```
