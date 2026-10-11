#!/bin/bash

PERSISTENT_SESSION_BASE_DIR="$HOME/.gemini/nvim-tmp"
HOST_TMP_DIR="$HOME/.gemini/tmp"

# Ensure host_tmp_dir exists
mkdir -p "$HOST_TMP_DIR"

# Check if the persistent base directory exists
if [ -d "$PERSISTENT_SESSION_BASE_DIR" ]; then
    # Iterate over each subdirectory in the persistent base directory
    # The trailing slash ensures that only directories are matched by glob.
    for SESSION_TMP_DIR in "$PERSISTENT_SESSION_BASE_DIR"/*/; do
        # Check if SESSION_TMP_DIR is a valid directory
        if [ -d "$SESSION_TMP_DIR" ]; then
            echo "Copying contents of $SESSION_TMP_DIR to $HOST_TMP_DIR"
            cp -a --update=none "$SESSION_TMP_DIR/." "$HOST_TMP_DIR/"
        fi
    done
fi