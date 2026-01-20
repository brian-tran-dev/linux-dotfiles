#!/bin/bash
STATE_FILE="$HOME/.gemini/nvim_session_state"

# If the state file exists, it means a script was running.
if [ -f "$STATE_FILE" ]; then
    # Source the variables (SESSION_PID, SESSION_TMP_DIR) from the state file.
    . "$STATE_FILE"

    # If the process ID exists and is a running process...
    if [ -n "$SESSION_PID" ] && ps -p "$SESSION_PID" > /dev/null; then
        # ...terminate it. This will trigger the script's own cleanup trap.
        kill "$SESSION_PID"
    fi

    # As a fallback, in case the script's trap fails, clean up the temp dir.
    if [ -n "$SESSION_TMP_DIR" ] && [ -d "$SESSION_TMP_DIR" ]; then
        rm -rf "$SESSION_TMP_DIR"
		cp -a --update=none $SESSION_TMP_DIR $HOST_TEMP_DIR
    fi

    # Remove the state file to signify that cleanup is complete.
    rm -f "$STATE_FILE"
fi
