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

# Funktion, um den Hostnamen vom Benutzer zu erfragen
ask_for_hostname() {
    read -p "Bitte gib den Hostnamen für WG_HOST an: " hostname
    echo "$hostname"
}


# Funktion, um WG_HOST in der docker-compose.yml anzupassen
update_wg_host_in_yml() {
    local hostname=$1
    local yml_file="$HOME/wg-easy/docker-compose.yml"
    
    if grep -q "WG_HOST=" "$yml_file"; then
        # Ersetze den vorhandenen WG_HOST-Wert
        sed -i "s|WG_HOST=.*|WG_HOST=$hostname|" "$yml_file"
    else
        # Füge WG_HOST hinzu, falls er nicht vorhanden ist
        echo "    - WG_HOST=$hostname" >> "$yml_file"
    fi
    echo "WG_HOST wurde auf '$hostname' in der docker-compose.yml gesetzt."
}



# Erster Befehl: Ordner "wg-easy" im Home-Verzeichnis erstellen
execute_command "mkdir -p ~/wg-easy"

# Zweiter Befehl: docker-compose.yml in den Ordner wg-easy herunterladen mit wget
execute_command "wget -O ~/wg-easy/docker-compose.yml https://raw.githubusercontent.com/wg-easy/wg-easy/master/docker-compose.yml"

# Dritter Schritt: Benutzer nach dem Hostnamen fragen und in der docker-compose.yml anpassen
hostname=$(ask_for_hostname)
update_wg_host_in_yml "$hostname"

# Go to https://github.com/wg-easy/wg-easy/blob/master/How_to_generate_an_bcrypt_hash.md and set a pw
echo "Konfiguriere ein Passwort für die Weboberfläche nach dieser Anleitung:"
echo "https://github.com/wg-easy/wg-easy/blob/master/How_to_generate_an_bcrypt_hash.md"

