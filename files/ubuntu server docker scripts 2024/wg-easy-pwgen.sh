#!/bin/bash

# Passwort vom Benutzer abfragen
read -sp "Bitte geben Sie das Passwort ein: " PASSWORD
echo

# Docker-Befehl ausführen und Ausgabe in Datei speichern
sudo docker run -it ghcr.io/wg-easy/wg-easy wgpw "$PASSWORD" > wg-easy-hash.txt

# Datei bearbeiten: jedem $-Symbol ein zweites $-Symbol voranstellen, PASSWORD_HASH= und ' entfernen
sed -i 's/\$/\$\$/g' wg-easy-hash.txt
sed -i 's/PASSWORD_HASH=//g' wg-easy-hash.txt
sed -i "s/'//g" wg-easy-hash.txt

# Inhalt der bearbeiteten Datei lesen
HASH=$(cat wg-easy-hash.txt)

# docker-compose.yml bearbeiten
DOCKER_COMPOSE_FILE="$HOME/wg-easy/docker-compose.yml"
sed -i "/- PASSWORD_HASH/s/# //g" "$DOCKER_COMPOSE_FILE"
sed -i "/- PASSWORD_HASH/s/=.*/=$HASH/g" "$DOCKER_COMPOSE_FILE"

# Benutzer fragen, ob wg-easy gestartet werden soll
read -p "Möchten Sie wg-easy jetzt starten? (ja/nein): " START

if [[ "$START" == "ja" ]]; then
  cd "$HOME/wg-easy"
  docker compose up -d
  echo "wg-easy wurde gestartet."
else
  echo "wg-easy wurde nicht gestartet."
fi

echo "Die Ausgabe wurde in wg-easy-hash.txt gespeichert und bearbeitet."
echo "Die Datei $HOME/wg-easy/docker-compose.yml wurde ebenfalls bearbeitet."
