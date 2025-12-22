#!/bin/bash

tt="$(printf '\t')"
tmux list-panes -a -F "#{session_name}${tt}#{?session_attached,attached,detached}${tt}#{window_index}${tt}#{pane_id}${tt}#{pane_current_command}" |
while IFS=$"${tt}" read -r s s_status w p cmd; do
	echo "s=$s w=$w p=$p cmd=$cmd"
	if [ "$s_status" = "attached" ]; then
		if [ "${1-}" = "kill-server" ]; then
			tmux send-keys -t "$p" C-c
		fi
	elif [ "$cmd" = "nvim" ]; then
		tmux send-keys -t "$p" q C-c C-c C-c Escape
		tmux send-keys -t "$p" : w a Enter
		tmux send-keys -t "$p" : q a Enter
	else 
		tmux send-keys -t "$p" C-c
	fi
done

if [ "${1-}" = "kill-server" ]; then
	tmux run-shell ~/.config/tmux/plugins/tmux-resurrect/scripts/save.sh
	tmux kill-server
fi
