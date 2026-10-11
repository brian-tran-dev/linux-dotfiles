function opencode --description 'OpenCode with the terminal Neovim prompt editor'
    # Autoloading also fixes EDITOR for shells that were open before the
    # exported editor settings in conf.d/opencode-editor.fish were installed.
    command env EDITOR=nvim VISUAL=nvim opencode $argv
end
