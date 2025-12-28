function ls
	set -lx EZA_ICON_SPACING 1
	eza --icons="always" -A -g --sort=type $argv
end
