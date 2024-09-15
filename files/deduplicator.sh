#!/bin/bash

# Verzeichnis, in dem nach Duplikaten gesucht werden soll
directory="."

# Finde Duplikate basierend auf Dateigröße und MD5-Hash
find "$directory" -type f -exec md5sum {} + | sort | uniq -w32 -dD > duplicates.txt

# Überprüfen, ob Duplikate gefunden wurden
if [ ! -s duplicates.txt ]; then
    echo "Keine Duplikate gefunden."
    exit 0
fi

# Duplikate anzeigen und fragen, ob sie gelöscht werden sollen
while IFS= read -r line; do
    hash=$(echo "$line" | awk '{print $1}')
    file=$(echo "$line" | awk '{print $2}')
    echo "Duplikat gefunden: $file"
    read -p "Möchten Sie dieses Duplikat löschen? (j/n): " answer
    if [ "$answer" == "j" ]; then
        rm "$file"
        echo "$file wurde gelöscht."
    else
        echo "$file wurde nicht gelöscht."
    fi
done < duplicates.txt

# Temporäre Datei löschen
rm duplicates.txt
