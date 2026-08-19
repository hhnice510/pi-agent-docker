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
    && rm -rf /var/lib/apt/lists/*

# Global installation of Pi Agent CLI and Pi-Web UI
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent @agegr/pi-web

# Set environment variables
ENV NODE_ENV=production
ENV PORT=30141

# Create persistence and workspace directories
RUN mkdir -p /root/.pi /workspace

# Set default working directory to /workspace
WORKDIR /workspace

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose Web UI port
EXPOSE 30141

ENTRYPOINT ["/entrypoint.sh"]
