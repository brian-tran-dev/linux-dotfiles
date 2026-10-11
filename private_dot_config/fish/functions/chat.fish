function chat
    set -l work_dir (pwd)
    set -l opencode_args $argv

    if test -n "$argv[1]"; and test -d "$argv[1]"
        set work_dir (realpath $argv[1])
        set opencode_args $argv[2..-1]
    end

    set -l work_mount
    if not contains -- "$work_dir" \
            "$HOME/.config/opencode" \
            "$HOME/.local/share/opencode" \
            "$HOME/.local/state/opencode" \
            "$HOME/.cache/opencode"
        set work_mount --mount "type=bind,src=$work_dir,dst=$work_dir"
    end

    set -l image localhost/opencode-dev:brian-personal-editor
    if not podman image exists $image
        echo "Build the prompt-editor image first:" >&2
        echo 'podman build --network host --tag localhost/opencode-dev:brian-personal-editor "$HOME/.config/opencode/container"' >&2
        return 1
    end

    set -l runtime_dir "$XDG_RUNTIME_DIR"
    if test -z "$runtime_dir"
        set runtime_dir /run/user/(id -u)
    end
    set -l notify_dir "$runtime_dir/opencode-notify"
    set -l context_args
    if command -q systemctl
        systemctl --user start opencode-notify.service
    end
    if test -S "$notify_dir/notify.sock"
        set -a context_args \
            --mount "type=bind,src=$notify_dir,dst=$notify_dir,ro" \
            --env "OPENCODE_NOTIFY_SOCKET=$notify_dir/notify.sock"
        if test "$HERDR_ENV" = 1; and test -n "$HERDR_PANE_ID"; and test -S "$HERDR_SOCKET_PATH"
            # The proxy permits only this pane's OpenCode lifecycle/session
            # reports, and reconnects to Herdr after a server restart.
            set -l proxy (python3 "$HOME/.config/opencode/helpers/notify.py" \
                --register-herdr "$HERDR_SOCKET_PATH" --pane "$HERDR_PANE_ID")
            if test $status -ne 0
                echo "Unable to create the scoped Herdr bridge." >&2
                return 1
            end
            set -a context_args --env HERDR_ENV=1 \
                --env "HERDR_SOCKET_PATH=$proxy" \
                --env "HERDR_PANE_ID=$HERDR_PANE_ID"
            for variable in HERDR_WORKSPACE_ID HERDR_TAB_ID
                if set -q $variable
                    set -a context_args --env "$variable=$$variable"
                end
            end
        end
    else
        echo "Warning: desktop notification bridge is unavailable." >&2
    end

    podman run \
        --rm --interactive --tty \
        --env TERM=xterm-256color \
        --env "HOME=$HOME" \
        --env EDITOR=nvim \
        --env VISUAL=nvim \
        --network host \
        --mount type=bind,src="$HOME/.config/opencode",dst="$HOME/.config/opencode" \
        --mount type=bind,src="$HOME/.local/share/opencode",dst="$HOME/.local/share/opencode" \
        --mount type=bind,src="$HOME/.local/state/opencode",dst="$HOME/.local/state/opencode" \
        --mount type=bind,src="$HOME/.cache/opencode",dst="$HOME/.cache/opencode" \
        --mount type=bind,src="$HOME/.ssh/config_container",dst="$HOME/.ssh/config",ro \
        --mount type=bind,src="$HOME/.ssh/github_ed25519",dst="$HOME/.ssh/github_ed25519",ro \
        --mount type=bind,src="$HOME/.ssh/aws_codecommit_rsa",dst="$HOME/.ssh/aws_codecommit_rsa",ro \
        --mount type=bind,src="$HOME/.ssh/known_hosts",dst="$HOME/.ssh/known_hosts",ro \
        $work_mount \
        $context_args \
        --workdir "$work_dir" \
        --cpus=2 \
        $image $opencode_args
end
