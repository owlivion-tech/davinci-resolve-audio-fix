FROM ubuntu:24.04

LABEL org.opencontainers.image.source="https://github.com/owlivion-tech/davinci-resolve-audio-fix"
LABEL org.opencontainers.image.description="Fix AAC audio in DaVinci Resolve on Linux"
LABEL org.opencontainers.image.licenses="MIT"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ffmpeg \
        inotify-tools \
    && rm -rf /var/lib/apt/lists/*

COPY src/dr-convert.sh /usr/local/bin/davinci-audio-fix
COPY src/dr-watch.sh   /usr/local/bin/davinci-audio-watchd

RUN chmod +x /usr/local/bin/davinci-audio-fix /usr/local/bin/davinci-audio-watchd

WORKDIR /videos

ENTRYPOINT ["davinci-audio-fix"]
