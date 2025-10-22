FROM ubuntu:22.04

RUN apt-get update -qq
RUN apt-get install -y -qq curl unzip git

RUN curl https://raw.githubusercontent.com/sst/opencode/refs/tags/v0.15.13/install | VERSION=0.15.13 bash
ENV PATH="/root/.opencode/bin:$PATH"

RUN opencode --version

RUN git config --global user.name "codecrafters-bot"
RUN git config --global user.email "hello@codecrafters.io"