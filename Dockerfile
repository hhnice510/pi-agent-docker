FROM node:22-bookworm

# Install required system dependencies for Pi Agent tools (git, ripgrep, curl, build essentials, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    vim \
    ripgrep \
    build-essential \
    procps \
    ca-certificates \
    openssh-client \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install code-server (VS Code Web). Pin the version via ARG (override with --build-arg CODE_SERVER_VERSION=...)
ARG CODE_SERVER_VERSION=4.133.0
RUN set -eux; \
    ARCH="$(uname -m)"; \
    case "$ARCH" in \
      x86_64)  DEB="code-server_${CODE_SERVER_VERSION}_amd64.deb" ;; \
      aarch64) DEB="code-server_${CODE_SERVER_VERSION}_arm64.deb" ;; \
      *) echo "Unsupported architecture: ${ARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fSL -o "/tmp/${DEB}" "https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/${DEB}"; \
    if ! dpkg -i "/tmp/${DEB}"; then \
        apt-get install -f -y --no-install-recommends; \
        apt-get clean; \
    fi; \
    code-server --version; \
    rm -f "/tmp/${DEB}"

# Global installation of Pi Agent CLI and Pi-Web UI
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent @agegr/pi-web

# Set environment variables
ENV NODE_ENV=production
ENV PORT=30141
ENV CODE_SERVER_PORT=8443

# Create persistence and workspace directories
RUN mkdir -p /root/.pi /workspace

# Set default working directory to /workspace
WORKDIR /workspace

# Copy entrypoint and supervisord configuration (process manager for pi-web + code-server)
COPY entrypoint.sh /entrypoint.sh
COPY supervisord.conf /etc/supervisor/supervisord.conf
RUN chmod +x /entrypoint.sh
RUN mkdir -p /etc/supervisor/conf.d

# Expose Web UI and code-server ports
EXPOSE 30141 8443

ENTRYPOINT ["/entrypoint.sh"]
