FROM node:22-bookworm

# Install required system dependencies for Pi Agent tools and Bun
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    vim \
    ripgrep \
    build-essential \
    procps \
    ca-certificates \
    openssh-client \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Bun (required by Pichamber runtime)
ENV BUN_INSTALL="/root/.bun"
ENV PATH="${BUN_INSTALL}/bin:${PATH}"
RUN curl -fsSL https://bun.sh/install | bash && \
    ln -s /root/.bun/bin/bun /usr/local/bin/bun && \
    bun --version

# Global installation of Pi Agent CLI and Pichamber Web UI
ARG PI_VERSION=latest
ARG PICHAMBER_VERSION=latest
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent@${PI_VERSION} @amagicpear/pichamber@${PICHAMBER_VERSION}

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV PICHAMBER_HOST=0.0.0.0
ENV PICHAMBER_PORT=3000

# Create persistence and workspace directories
RUN mkdir -p /root/.pi /workspace

# Set default working directory to /workspace
WORKDIR /workspace

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose Pichamber Web UI port
EXPOSE 3000

ENTRYPOINT ["/entrypoint.sh"]
