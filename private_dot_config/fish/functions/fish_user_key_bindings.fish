function fish_user_key_bindings
	bind -M insert -m default jj backward-char force-repaint
	bind -M visual -m default y 'fish_clipboard_copy; commandline -f end-selection repaint-mode'
	bind -M default yy fish_clipboard_copy
	bind -M default p fish_clipboard_paste
end
