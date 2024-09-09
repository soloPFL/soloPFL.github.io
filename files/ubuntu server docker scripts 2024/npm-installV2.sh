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

# Datei und Pfad definieren
config_file="npmconfig.txt"

# Konfigurationen in die Datei schreiben
echo "client_body_buffer_size 512k;" > $config_file
echo "proxy_read_timeout 86400s;" >> $config_file
echo "client_max_body_size 0;" >> $config_file

echo "Konfigurationen wurden in $config_file geschrieben. Bitte manuell in der GUI einfügen."
echo ""
cat $config_file