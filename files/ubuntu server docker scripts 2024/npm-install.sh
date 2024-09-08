#!/bin/bash

# Erstelle den Ordner 'npm' relativ zum aktuellen Verzeichnis des Skripts
mkdir -p ./npm

# Erstelle die Datei 'docker-compose.yml' im 'npm'-Verzeichnis und füge den Inhalt hinzu
cat <<EOL > ./npm/docker-compose.yml
version: '3.8'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      # These ports are in format <host-port>:<container-port>
      - '80:80' # Public HTTP Port
      - '443:443' # Public HTTPS Port
      - '81:81' # Admin Web Port
      # Add any other Stream port you want to expose
      # - '21:21' # FTP

    # Uncomment the next line if you uncomment anything in the section
    # environment:
      # Uncomment this if you want to change the location of
      # the SQLite DB file within the container
      # DB_SQLITE_FILE: "/data/database.sqlite"

      # Uncomment this if IPv6 is not enabled on your host
      # DISABLE_IPV6: 'true'

    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
EOL

# Wechsel in den 'npm'-Ordner
cd ./npm

# Führe den Befehl 'sudo docker compose up -d' aus
sudo docker compose up -d

echo "Ordner 'npm' und Datei 'docker-compose.yml' wurden erfolgreich erstellt und Docker Compose wurde gestartet!"
