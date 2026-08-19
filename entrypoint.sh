#!/usr/bin/env bash
set -e

# Ensure persistence and workspace directories exist
mkdir -p /root/.pi /workspace

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

# If no arguments or flags are passed, start pi-web
if [ $# -eq 0 ] || [ "${1:0:1}" = '-' ]; then
    echo "Starting Pi-Web UI server on 0.0.0.0:${PORT:-30141}..."
    exec pi-web -H 0.0.0.0 -p "${PORT:-30141}" --no-open "$@"
fi

# Execute passed command (e.g. docker run ... pi or bash)
exec "$@"
