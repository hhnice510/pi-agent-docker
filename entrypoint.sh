#!/usr/bin/env bash
set -e

# 1. Ensure required directories exist
mkdir -p /root/.pi/agent/extensions /root/.pi/code-server/extensions /workspace

# 2. Sync built-in Pi Agent extensions
if [ -d "/opt/pi/extensions" ]; then
  cp -rf /opt/pi/extensions/* /root/.pi/agent/extensions/ 2>/dev/null || true
fi

# 3. Sync git global config & credentials with persistent volume
for file in .gitconfig .git-credentials; do
  if [ -f "/root/.pi/$file" ]; then
    cp -f "/root/.pi/$file" "/root/$file"
  elif [ -f "/root/$file" ]; then
    cp -f "/root/$file" "/root/.pi/$file"
  fi
  chmod 600 "/root/$file" "/root/.pi/$file" 2>/dev/null || true
done

# 3. Optional auto-update for pi agent packages
if [ "${AUTO_UPDATE:-false}" = "true" ]; then
  echo "AUTO_UPDATE is enabled. Updating pi packages to latest..."
  npm update -g @earendil-works/pi-coding-agent @agegr/pi-web || true
fi

# 4. Direct CLI execution (e.g. docker run ... pi or bash)
if [ $# -gt 0 ]; then
  exec "$@"
fi

# 5. Handle code-server disabled toggle
if [ "${CODE_SERVER_ENABLED:-true}" = "false" ]; then
  echo "code-server is disabled (CODE_SERVER_ENABLED=false)."
  sed -i '/\[program:code-server\]/,/redirect_stderr=true/d' /etc/supervisor/supervisord.conf
else
  # Install requested VS Code extensions
  if [ -n "${CODE_SERVER_EXTENSIONS:-}" ]; then
    IFS=',' read -r -a exts <<< "${CODE_SERVER_EXTENSIONS}"
    echo "code-server: installing configured extensions: ${CODE_SERVER_EXTENSIONS}"
    for ext in "${exts[@]}"; do
      ext="$(echo "$ext" | xargs)"
      [ -z "$ext" ] && continue
      code-server --install-extension "$ext" --user-data-dir /root/.pi/code-server --extensions-dir /root/.pi/code-server/extensions >/dev/null 2>&1 || echo "code-server: WARNING - failed to install ${ext}"
    done
  fi

  # Configure code-server password
  if [ -z "${CODE_SERVER_PASSWORD:-}" ]; then
    PASSWORD="$(node -e 'process.stdout.write(require("crypto").randomBytes(12).toString("base64"))')"
    echo ""
    echo "=================================================================="
    echo " code-server: no CODE_SERVER_PASSWORD configured."
    echo " Generated random session password: ${PASSWORD}"
    echo " (Set CODE_SERVER_PASSWORD in .env to use a fixed password)"
    echo "=================================================================="
    echo ""
  else
    PASSWORD="$CODE_SERVER_PASSWORD"
  fi
  export PASSWORD
fi

# 6. Launch supervisord process manager (PID 1)
exec supervisord -c /etc/supervisor/supervisord.conf
