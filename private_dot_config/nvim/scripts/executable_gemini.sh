#!/bin/bash

HOST_TMP_DIR="$HOME/.gemini/tmp"
mkdir -p "$HOST_TMP_DIR"

PERSISTENT_SESSION_BASE_DIR="$HOME/.gemini/nvim-tmp"
mkdir -p "$PERSISTENT_SESSION_BASE_DIR"

SESSION_TMP_DIR=$(mktemp -d -p "$PERSISTENT_SESSION_BASE_DIR" XXXXXX)

WORKDIR=$(pwd)
if [ -d "$1" ]; then
	WORKDIR="$1"
	shift
fi

podman run --rm --interactive \
	--user root \
	--network host \
	--volume "$HOME/.gemini:/root/.gemini:ro" \
	--volume "$SESSION_TMP_DIR:/root/.gemini/tmp" \
	--volume "$WORKDIR:$WORKDIR" \
	--workdir "$WORKDIR" \
	us-docker.pkg.dev/gemini-code-dev/gemini-cli/sandbox:0.24.5 \
	gemini \
	--experimental-acp "$@"


