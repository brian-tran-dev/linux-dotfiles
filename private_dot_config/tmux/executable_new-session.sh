#!/bin/bash

s_name="n/a-$(date +%s)"
tmux new-session -d -s "$s_name"
tmux switch-client -t "$s_name"
