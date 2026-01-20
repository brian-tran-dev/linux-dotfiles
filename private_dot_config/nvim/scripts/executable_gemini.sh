#!/bin/bash

HOST_TMP_DIR="$HOME/.gemini/tmp"
mkdir -p "$HOST_TMP_DIR"

SESSION_TMP_DIR=$(mktemp -d -t gemini-nvim-tmp.XXXXXX)

trap 'rm -rf "$SESSION_TMP_DIR"' EXIT

podman run --rm --interactive \
	--user root \
	--network host \
	--volume "$HOME/.gemini:/root/.gemini:ro" \
	--volume "$SESSION_TMP_DIR:/root/.gemini/tmp" \
	--volume "$(pwd):$(pwd)" \
	--workdir "$(pwd)" \
	us-docker.pkg.dev/gemini-code-dev/gemini-cli/sandbox:0.24.4 \
	gemini \
	--experimental-acp "$@"

if [ -d "$SESSION_TMP_DIR" ]; then
    cp -a --update=none "$SESSION_TMP_DIR/." "$HOST_TMP_DIR/"
fi
