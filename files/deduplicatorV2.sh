#!/bin/bash

# Verzeichnis, in dem nach Duplikaten gesucht werden soll
directory="."

# Gesamtanzahl der Dateien im Verzeichnis
total_files=$(find "$directory" -type f | wc -l)
processed_files=0
duplicate_count=0

# Finde Duplikate basierend auf Dateigröße und MD5-Hash
find "$directory" -type f -exec md5sum {} + | sort | uniq -w32 -dD > duplicates.txt

# Überprüfen, ob Duplikate gefunden wurden
if [ ! -s duplicates.txt ]; then
    echo "Keine Duplikate gefunden."
    exit 0
fi

# Duplikate anzeigen
echo "Gefundene Duplikate:"
cat duplicates.txt

# Abfrage zur Löschung aller Duplikate
read -p "Möchten Sie alle gefundenen Duplikate löschen? (j/n): " answer
if [ "$answer" == "j" ]; then
    while IFS= read -r line; do
        file=$(echo "$line" | awk '{print $2}')
        rm "$file"
        echo "$file wurde gelöscht."
        duplicate_count=$((duplicate_count + 1))
        processed_files=$((processed_files + 1))
        echo "Fortschritt: $processed_files/$total_files Dateien verarbeitet, $duplicate_count Duplikate gelöscht."
    done < duplicates.txt
else
    echo "Keine Duplikate wurden gelöscht."
fi

# Temporäre Datei löschen
rm duplicates.txt
