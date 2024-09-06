#!/bin/bash

# Verzeichnis erstellen
mkdir -p ~/jellyfin/config ~/jellyfin/cache ~/jellyfin/media

# Berechtigungen anpassen
sudo chown -R 1000:1000 ~/jellyfin

# docker-compose.yml Datei erstellen
cat <<EOF > ~/jellyfin/docker-compose.yml
version: '3.8'

services:
  jellyfin:
    image: jellyfin/jellyfin
    user: 1000:1000
    container_name: jellyfin
    network_mode: "host"
    devices:
      - /dev/dri:/dev/dri
    volumes:
      - ./config:/config
      - ./cache:/cache
      - ./media:/media
    environment:
      - JELLYFIN_PublishedServerUrl=http://localhost:8096
    restart: unless-stopped
    extra_hosts:
      - 'host.docker.internal:host-gateway'
EOF

echo "docker-compose.yml Datei wurde in ~/jellyfin erstellt."

# Docker Compose ausführen
sudo docker compose -f ~/jellyfin/docker-compose.yml up --detach --pull always
