FROM alpine:3.22.2

RUN apk update && apk add --no-cache curl unzip git libc6-compat gcompat

RUN curl https://raw.githubusercontent.com/sst/opencode/refs/tags/v0.15.13/install | VERSION=0.15.13 SHELL=ash ash
ENV PATH="/root/.opencode/bin:$PATH"

RUN opencode --version

RUN git config --global user.name "codecrafters-bot"
RUN git config --global user.email "hello@codecrafters.io"

ARG LOGSTREAM_VERSION=v29
ARG CLI_VERSION=v3

# Download and install the appropriate logstream binary based on system architecture
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        LOGSTREAM_URL="https://github.com/codecrafters-io/logstream/releases/download/${LOGSTREAM_VERSION}/${LOGSTREAM_VERSION}_linux_amd64"; \
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        LOGSTREAM_URL="https://github.com/codecrafters-io/logstream/releases/download/${LOGSTREAM_VERSION}/${LOGSTREAM_VERSION}_linux_arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    curl --fail -L "$LOGSTREAM_URL" -o /usr/local/bin/logstream && \
    chmod +x /usr/local/bin/logstream

# Ensure logstream is installed and working
RUN logstream help

# Download and install the appropriate cli binary based on system architecture
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        CLI_URL="https://github.com/codecrafters-io/coderbot-cli/releases/download/${CLI_VERSION}/${CLI_VERSION}_linux_amd64.tar.gz"; \
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        CLI_URL="https://github.com/codecrafters-io/coderbot-cli/releases/download/${CLI_VERSION}/${CLI_VERSION}_linux_arm64.tar.gz"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    curl --fail -L "$CLI_URL" -o /tmp/codecrafters.tar.gz && \
    mkdir -p /tmp/codecrafters && \
    tar -xzf /tmp/codecrafters.tar.gz -C /tmp/codecrafters && \
    mv /tmp/codecrafters/codecrafters /usr/local/bin/codecrafters && \
    chmod +x /usr/local/bin/codecrafters && \
    rm -rf /tmp/codecrafters /tmp/codecrafters.tar.gz

# Ensure codecrafters is installed and working
RUN codecrafters --version