#!/bin/bash

# Überprüfen, ob der Parameter -y gesetzt ist
AUTO_YES=false
while getopts "y" opt; do
  case $opt in
    y)
      AUTO_YES=true
      ;;
    \?)
      echo "Ungültige Option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Funktion zur Installation von Paketen
install_package() {
    local package="$1"
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y "$package"
    elif command -v yum &> /dev/null; then
        sudo yum install -y "$package"
    elif command -v brew &> /dev/null; then
        brew install "$package"
    else
        echo "Paketmanager nicht gefunden. Bitte installiere $package manuell."
        exit 1
    fi
}

# Überprüfen, ob dcraw und convert installiert sind
if ! command -v dcraw &> /dev/null; then
    if [ "$AUTO_YES" = true ]; then
        install_package dcraw
    else
        echo "dcraw ist nicht installiert. Möchtest du es installieren? (y/n)"
        read -r response
        if [[ "$response" == "y" ]]; then
            install_package dcraw
        else
            echo "dcraw wird benötigt. Beende das Skript."
            exit 1
        fi
    fi
fi

if ! command -v convert &> /dev/null; then
    if [ "$AUTO_YES" = true ]; then
        install_package imagemagick
    else
        echo "convert ist nicht installiert. Möchtest du es installieren? (y/n)"
        read -r response
        if [[ "$response" == "y" ]]; then
            install_package imagemagick
        else
            echo "convert wird benötigt. Beende das Skript."
            exit 1
        fi
    fi
fi

# Funktion zur Umwandlung von RAW zu JPG
convert_raw_to_jpg() {
    local raw_file="$1"
    local jpg_file="${raw_file%.*}.jpg"
    dcraw -c "$raw_file" | convert - "$jpg_file"
}

# Rekursive Suche nach RAW-Dateien und Umwandlung
find . -type f \( -iname "*.raw" -o -iname "*.nef" -o -iname "*.cr2" -o -iname "*.cr3" -o -iname "*.dng" \) | while read -r raw_file
do
    echo "Konvertiere: $raw_file"
    convert_raw_to_jpg "$raw_file"
done

echo "Alle Dateien wurden konvertiert."
