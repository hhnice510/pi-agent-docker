#!/usr/bin/env bash
set -e

# Ensure persistence and workspace directories exist
mkdir -p /root/.pi /workspace

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
