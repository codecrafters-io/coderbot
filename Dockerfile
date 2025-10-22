FROM ubuntu:22.04

RUN apt-get update -qq
RUN apt-get install -y -qq curl unzip git

RUN curl https://raw.githubusercontent.com/sst/opencode/refs/tags/v0.15.13/install | VERSION=0.15.13 bash
ENV PATH="/root/.opencode/bin:$PATH"

RUN opencode --version

RUN git config --global user.name "codecrafters-bot"
RUN git config --global user.email "hello@codecrafters.io"

# Download and install the appropriate logstream binary based on system architecture
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        LOGSTREAM_URL="https://github.com/codecrafters-io/logstream/releases/download/v29/v29_linux_amd64"; \
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        LOGSTREAM_URL="https://github.com/codecrafters-io/logstream/releases/download/v29/v29_linux_arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    curl --fail -L "$LOGSTREAM_URL" -o /usr/local/bin/logstream && \
    chmod +x /usr/local/bin/logstream

# Ensure logstream is installed and working
RUN logstream help