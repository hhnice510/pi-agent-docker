#!/usr/bin/env bash
set -e

# Ensure persistence, workspace and supervisor config directories exist
mkdir -p /root/.pi /workspace /etc/supervisor/conf.d

#
# Persist git global config (.gitconfig) and credentials token (.git-credentials)
# The persistent volume pi_data mounts at /root/.pi, while git reads these files
# from /root (HOME). Sync them so config survives container recreation.
# Strategy: newest-wins bidirectional sync on startup.
#
sync_git_config() {
    local src="/root/$1"
    local dst="/root/.pi/$1"
    if [ -f "$src" ] && [ -f "$dst" ]; then
        # both exist -> newest wins
        if [ "$src" -nt "$dst" ]; then
            cp -f "$src" "$dst"
        else
            cp -f "$dst" "$src"
        fi
    elif [ -f "$src" ]; then
        cp -f "$src" "$dst"
    elif [ -f "$dst" ]; then
        cp -f "$dst" "$src"
    fi
    chmod 600 "$dst" 2>/dev/null || true
}

sync_git_config .gitconfig
sync_git_config .git-credentials

# Optionally auto-update pi agent and pi-web packages on startup
if [ "${AUTO_UPDATE:-false}" = "true" ]; then
    echo "AUTO_UPDATE is enabled. Updating @earendil-works/pi-coding-agent and @agegr/pi-web to latest versions..."
    npm update -g @earendil-works/pi-coding-agent @agegr/pi-web || true
fi

#
# Code-server (VS Code Web)
# Settings / extensions are persisted inside the pi_data volume (/root/.pi/code-server)
# so they survive container recreation, just like the rest of the Pi agent config.
#
CODE_SERVER_ENABLED="${CODE_SERVER_ENABLED:-true}"
CODE_SERVER_PORT="${CODE_SERVER_PORT:-8443}"
CODE_SERVER_DATA_DIR="/root/.pi/code-server"

install_code_server_extensions() {
    mkdir -p "$CODE_SERVER_DATA_DIR"
    local ext
    IFS=',' read -r -a exts <<< "${CODE_SERVER_EXTENSIONS}"
    echo "code-server: installing configured extensions: ${CODE_SERVER_EXTENSIONS}"
    for ext in "${exts[@]}"; do
        ext="$(echo "$ext" | xargs)"   # trim surrounding whitespace
        [ -z "$ext" ] && continue
        if code-server --list-extensions --user-data-dir "$CODE_SERVER_DATA_DIR" --extensions-dir "$CODE_SERVER_DATA_DIR/extensions" 2>/dev/null | grep -qxF "$ext"; then
            echo "code-server: extension already installed: ${ext}"
        elif code-server --install-extension "$ext" --user-data-dir "$CODE_SERVER_DATA_DIR" --extensions-dir "$CODE_SERVER_DATA_DIR/extensions" >/dev/null 2>&1; then
            echo "code-server: extension installed: ${ext}"
        else
            echo "code-server: WARNING - failed to install extension: ${ext}"
        fi
    done
}

# If a concrete command is passed (e.g. docker run ... pi or bash), run it
# directly and skip the supervisor / web services entirely.
if [ $# -gt 0 ] && [ "${1:0:1}" != '-' ]; then
    exec "$@"
fi

# Install configured extensions BEFORE starting the server (a running server
# locks its data dir). Only relevant when code-server is enabled.
if [ "$CODE_SERVER_ENABLED" = "true" ] && [ -n "${CODE_SERVER_EXTENSIONS:-}" ]; then
    install_code_server_extensions
fi

# Generate a random password when code-server is enabled and none was provided.
# It is printed to the logs and exported as PASSWORD for the code-server program.
if [ "$CODE_SERVER_ENABLED" = "true" ]; then
    if [ -z "${CODE_SERVER_PASSWORD:-}" ]; then
        CODE_SERVER_PASSWORD="$(node -e 'process.stdout.write(require("crypto").randomBytes(12).toString("base64"))')"
        echo ""
        echo "=================================================================="
        echo " code-server: no CODE_SERVER_PASSWORD configured."
        echo " Generated random password for this session: ${CODE_SERVER_PASSWORD}"
        echo " (It changes on every container restart. Set CODE_SERVER_PASSWORD"
        echo "  in .env to use a fixed password.)"
        echo "=================================================================="
        echo ""
    fi
    export PASSWORD="$CODE_SERVER_PASSWORD"

    # Write the code-server supervisor program (conditionally enabled).
    cat > /etc/supervisor/conf.d/code-server.conf <<EOF
[program:code-server]
command=code-server --bind-addr 0.0.0.0:%(ENV_CODE_SERVER_PORT)s --auth password --user-data-dir ${CODE_SERVER_DATA_DIR} --extensions-dir ${CODE_SERVER_DATA_DIR}/extensions --disable-telemetry --disable-update-check /workspace
environment=PASSWORD=%(ENV_PASSWORD)s
autostart=true
autorestart=true
startsecs=3
stopsignal=SIGTERM
stopwaitsecs=10
stopasgroup=true
killasgroup=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
redirect_stderr=true
EOF
else
    echo "code-server is disabled (CODE_SERVER_ENABLED != true). Skipping."
    rm -f /etc/supervisor/conf.d/code-server.conf
fi

# Forward any command-line flags (e.g. docker run ... --some-flag) to pi-web as
# extra arguments. PI_WEB_ARGS is always exported (empty when none are given) so the
# supervisord config's %(ENV_PI_WEB_ARGS)s reference is never undefined at startup.
export PI_WEB_ARGS="$*"

# Hand off to supervisord (PID 1) which supervises pi-web and, when enabled,
# code-server. Each program is independently restarted and gracefully stopped
# on container shutdown (supervisord forwards SIGTERM to its children).
exec supervisord -c /etc/supervisor/supervisord.conf
