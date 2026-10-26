alias gco="git checkout"
alias gst="git status"
alias gcm="git commit"
alias gpl="git pull"
alias gps="git push"

# Command shortcuts
alias cd="z"
alias pn="pnpm"
alias penv="poetry --no-cache"
alias v="nvim"
alias r="nvim -c 'setlocal nomodifiable'"
alias download="aria2c -x 16 -s 16 -k 1M"
alias heat="watch -cd -n 0.5 sensors"
alias tex-manager="tlmgr"
alias typst-compile="typst compile --pdf-standard a-2u --jobs 2 --format pdf"
alias typst-watch="typst watch --pdf-standard a-2u --jobs 2 --format pdf"

# Keep these environment settings local to each command.
alias b="BAT_THEME=OneHalfDark bat --paging=always"
alias ls="EZA_ICON_SPACING=1 eza --icons=always -A -g --sort=type"
alias opencode="command env EDITOR=nvim VISUAL=nvim opencode"

# Herdr and OpenCode
alias hr="herdr"
alias hr-stop="herdr stop server"
alias oc="opencode --standalone"
