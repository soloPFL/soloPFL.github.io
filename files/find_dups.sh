#!/bin/bash

# Ordner als Argument übergeben
if [ -z "$1" ]; then
  echo "Bitte einen Ordner angeben."
  exit 1
fi

DIR=$1

# Prüfsummen-Datei
CHECKSUM_FILE="checksums.txt"

# Bereinigen, falls Datei existiert
> $CHECKSUM_FILE

# Dateien zählen
TOTAL_FILES=$(find "$DIR" -type f | wc -l)
CURRENT_FILE=0

# Rekursiv durch den Ordner gehen und Prüfsummen berechnen
find "$DIR" -type f | while read FILE; do
  sha256sum "$FILE" >> $CHECKSUM_FILE
  CURRENT_FILE=$((CURRENT_FILE + 1))
  echo -ne "Verarbeite Dateien: $CURRENT_FILE von $TOTAL_FILES\r"
done
echo -ne '\n'

# Duplikate finden und auflisten
echo "Gefundene Duplikate:"
awk '{print $1}' $CHECKSUM_FILE | sort | uniq -d | while read CHECKSUM; do
  grep "$CHECKSUM" $CHECKSUM_FILE | awk '{print $2}'
done

# Bestätigung vom Benutzer einholen
echo -n "Möchten Sie die Duplikate löschen? (ja/nein): "
read CONFIRMATION

if [ "$CONFIRMATION" == "ja" ]; then
  # Duplikate löschen
  awk '{print $1}' $CHECKSUM_FILE | sort | uniq -d | while read CHECKSUM; do
    FILES=($(grep "$CHECKSUM" $CHECKSUM_FILE | awk '{print $2}'))
    # Die erste Datei behalten, den Rest löschen
    for ((i=1; i<${#FILES[@]}; i++)); do
      echo "Lösche: ${FILES[i]}"
      rm "${FILES[i]}"
    done
  done
  echo "Duplikate gelöscht."
else
  echo "Löschvorgang abgebrochen."
fi

# Temporäre Datei löschen
rm $CHECKSUM_FILE
