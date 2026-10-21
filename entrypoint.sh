#!/usr/bin/env bash
set -e

# Ensure persistence and workspace directories exist
mkdir -p /root/.pi /root/.pi/agent/extensions /workspace

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

# Direct CLI execution (e.g. docker run ... pi or bash) bypasses the Web UI.
if [ $# -gt 0 ] && [ "${1:0:1}" != '-' ]; then
    exec "$@"
fi

# Forward any remaining flags to pi-web itself (e.g. -p 30241)
PI_WEB_EXTRA_ARGS="$*"
export PI_WEB_EXTRA_ARGS

# Launch supervisord as PID 1:
#   - pi-web runs as a supervised child process and is restarted automatically on crash
#   - the Web UI can be restarted safely without stopping the container:
#       docker exec pi-agent supervisorctl restart pi-web
echo "Starting Pi-Web UI server on 0.0.0.0:${PORT:-30141} (managed by supervisord)..."
exec supervisord -c /etc/supervisor/supervisord.conf
