function unzip_fonts
	unzip $argv[1] -d "$HOME/.local/share/fonts"
	fc-cache -f -v
end
