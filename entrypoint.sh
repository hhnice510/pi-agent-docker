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

# Optionally auto-update pi agent and pichamber packages on startup
if [ "${AUTO_UPDATE:-false}" = "true" ]; then
    echo "AUTO_UPDATE is enabled. Updating @earendil-works/pi-coding-agent and @amagicpear/pichamber to latest versions..."
    npm update -g @earendil-works/pi-coding-agent @amagicpear/pichamber || true
fi

# If no arguments or flags are passed, start pichamber serve
if [ $# -eq 0 ] || [ "${1:0:1}" = '-' ]; then
    PORT_VAL="${PORT:-3000}"
    echo "Starting Pichamber Web UI server on 0.0.0.0:${PORT_VAL}..."
    exec pichamber serve --host 0.0.0.0 --port "${PORT_VAL}" "$@"
fi

# Execute passed command (e.g. docker run ... pi or bash)
exec "$@"
