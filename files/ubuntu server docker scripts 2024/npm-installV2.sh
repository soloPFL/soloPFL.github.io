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
    labels:
      - "com.centurylinklabs.watchtower.enable=true"    
    network_mode: host
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt

EOL

# Wechsel in den 'npm'-Ordner
cd ./npm

# Führe den Befehl 'sudo docker compose up -d' aus
sudo docker compose up -d

echo "Ordner 'npm' und Datei 'docker-compose.yml' wurden erfolgreich erstellt und NPM wurde gestartet!"
