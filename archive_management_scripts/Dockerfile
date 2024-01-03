FROM debian:12-slim

RUN apt-get update \
    && apt-get install -y inotify-tools rsync \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /srv/hf-radar-archive-manager

COPY hf-radar-archive-manager.sh ./

ENTRYPOINT ["/srv/hf-radar-archive-manager/hf-radar-archive-manager.sh"]
