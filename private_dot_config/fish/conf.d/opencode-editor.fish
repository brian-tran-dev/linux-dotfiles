# Export only editor settings; keep Neovim as the normal terminal editor.
# Fish's existing universal EDITOR variable was not exported to child processes.
set -gx EDITOR nvim
set -gx VISUAL nvim
