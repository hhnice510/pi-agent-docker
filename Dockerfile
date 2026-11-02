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

# Global installation of Pi Agent CLI and Pi-Web UI
# 版本通过 build-arg 传入：上游版本变化时这一层缓存会自动失效，
# 否则 cache-from: type=gha 会一直复用旧层，装了旧版本却显示“构建成功”。
ARG PI_VERSION=latest
ARG PI_WEB_VERSION=latest
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent@${PI_VERSION} @agegr/pi-web@${PI_WEB_VERSION}

# Set environment variables
ENV NODE_ENV=production
ENV PORT=30141

# Create persistence and workspace directories
RUN mkdir -p /root/.pi /workspace

# Set default working directory to /workspace
WORKDIR /workspace

# Copy entrypoint script and supervisord configuration
COPY entrypoint.sh /entrypoint.sh
COPY supervisord.conf /etc/supervisor/supervisord.conf
RUN chmod +x /entrypoint.sh

# Expose Web UI port
EXPOSE 30141

ENTRYPOINT ["/entrypoint.sh"]
