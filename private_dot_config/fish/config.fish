if not test -e "/home/linuxbrew/.linuxbrew/bin/brew"
	echo "Installing brew..."
	bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
	brew install neovim
	brew install eza
	brew install fzf
	brew install starship
	brew install zoxide
	brew install bat
	brew install ripgrep
	brew install fd
	brew install yazi
else
	eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

# Install NodeJS
if test -z (fisher list nvm)
	fisher install jorgebucaran/nvm.fish
	nvm install lts
	set --universal nvm_default_version lts
end

if test -z (nvm list)
	nvm install lts
	set --universal nvm_default_version lts
end

if status is-interactive
	set fish_greeting
	bind -M insert \e\[9\;5u accept-autosuggestion
	bind -M default \e\[9\;5u accept-autosuggestion
	bind -M paste \e\[9\;5u accept-autosuggestion
	bind -M visual \e\[9\;5u accept-autosuggestion
	bind -M replace \e\[9\;5u accept-autosuggestion
	bind -M replace_one \e\[9\;5u accept-autosuggestion
	bind -M insert \cU undo

	set fish_vi_force_cursor 1
	# Emulates vim's cursor shape behavior
	# Set the normal and visual mode cursors to a block
	set fish_cursor_default block blink
	# Set the insert mode cursor to a line
	set fish_cursor_insert line blink
	# Set the replace mode cursors to an underscore
	set fish_cursor_replace_one underscore
	set fish_cursor_replace underscore
	# Set the external cursor to a line. The external cursor appears when a command is started.
	# The cursor shape takes the value of fish_cursor_default when fish_cursor_external is not specified.
	set fish_cursor_external line
	# The following variable can be used to configure cursor shape in
	# visual mode, but due to fish_cursor_default, is redundant here
	set fish_cursor_visual block

	bind -M insert \ei backward-char forward-char
	bind -M default -m insert \ei end-of-line repaint-mode
	bind -M replace_one -m default \ei cancel repaint-mode
	bind -M replace -m default \ei cancel repaint-mode
	bind -M visual -m default \ei end-selection repaint-mode
	bind -M insert \e\b kill-whole-line

	set fzf_fd_opts --unrestricted

	starship init fish | source
	fzf --fish | source
	zoxide init fish | source

	source (pyenv virtualenv-init -|psub)
	pyenv init - fish | source
end

source "$HOME/.cargo/env.fish"

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# pnpm
set -gx PNPM_HOME "/home/brian/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

# texlive
set -gxp MANPATH /home/brian/.local/texlive/2025/texmf-dist/doc/man
set -gxp INFOPATH /home/brian/.local/texlive/2025/texmf-dist/doc/info
set -gxp PATH /home/brian/.local/texlive/2025/bin/x86_64-linux
# texlive end

# pyenv
set -gx PYENV_ROOT $HOME/.pyenv
test -d $PYENV_ROOT/bin; and set -gxp PATH "$PYENV_ROOT/bin"
# pyenv
