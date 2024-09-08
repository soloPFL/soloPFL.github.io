#!/bin/bash

# Funktion, die den Befehl ausführt und überprüft, ob er erfolgreich war
execute_command() {
    echo "Führe Befehl aus: $1"
    eval "$1"
    if [ $? -eq 0 ]; then
        echo "Befehl '$1' erfolgreich ausgeführt."
    else
        echo "Fehler beim Ausführen von '$1'."
        exit 1  # Skript abbrechen, wenn ein Befehl fehlschlägt
    fi
}

# Funktion, um den Benutzer zu fragen, ob er den nächsten Befehl ausführen möchte
ask_to_proceed() {
    read -p "Möchtest du den nächsten Befehl ausführen? = Nextcloud AIO starten? (y/n): " choice
    case "$choice" in
        y|Y ) echo "Fahre fort...";;
        n|N ) echo "Befehl übersprungen."; exit 0;;
        * ) echo "Ungültige Eingabe. Befehl wird übersprungen."; exit 0;;
    esac
}

# Erster Befehl: Update der Paketliste
execute_command "sudo apt update"

# Zweiter Befehl: Entfernen von Docker-bezogenen Paketen
execute_command 'for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove -y $pkg; done'

# Dritter Block: Füge alle Docker-relevanten Befehle zusammen
execute_docker_setup() {
    echo "Führe Docker-Setup-Befehle aus..."

    sudo apt-get update && \
    sudo apt-get install -y ca-certificates curl && \
    sudo install -m 0755 -d /etc/apt/keyrings && \
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    sudo chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    sudo apt-get update

    if [ $? -eq 0 ]; then
        echo "Docker-Setup erfolgreich abgeschlossen."
    else
        echo "Fehler beim Docker-Setup."
        exit 1  # Skript abbrechen, wenn der Block fehlschlägt
    fi
}

# Führe Docker-Setup aus
execute_docker_setup

# Vierter Block: Docker und relevante Pakete installieren
execute_command "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"

# Benutzer fragen, ob der nächste Befehl ausgeführt werden soll
ask_to_proceed

# Fünfter Block: Ordner erstellen und Datei herunterladen
execute_command "mkdir -p nc-aio && cd nc-aio && curl -O https://raw.githubusercontent.com/soloPFL/soloPFL.github.io/main/files/ubuntu%20server%20docker%20scripts%202024/nextcloud-aio-docker/docker-compose.yml"

# Sechster Block: Docker Compose Befehl ausführen
execute_command "sudo docker compose up -d"
