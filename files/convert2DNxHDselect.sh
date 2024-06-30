#!/bin/bash

# Eingabeordner (aktuelles Verzeichnis)
input_folder="."

# Ausgabeordner (relativer Pfad)
output_folder="output"

# Unterstützte Erweiterungen der Videodateien
video_extensions=("mov" "mp4" "m4v" "mkv")

# Überprüfe, ob der Ausgabeordner existiert, andernfalls erstelle ihn
if [ ! -d "$output_folder" ]; then
  mkdir "$output_folder"
fi

# Überprüfe, ob die Bitrate als Parameter übergeben wurde
if [ -z "$1" ]; then
  bitrate="90"
else
  # Überprüfe, ob die angegebene Bitrate unterstützt wird
  case "$1" in
    90|100|120|150|290|440)
      bitrate="$1"
      ;;
    *)
      echo "Ungültige Bitrate. Unterstützte Werte sind 90, 100, 120, 150, 290 und 440."
      exit 1
      ;;
  esac
fi

# Schleife durch alle Videodateien im Eingabeordner mit den angegebenen Erweiterungen
for ext in "${video_extensions[@]}"; do
  for input_file in "$input_folder"/*."$ext"; do
    # Extrahiere Dateiname ohne Erweiterung und Pfad
    filename=$(basename -- "$input_file")
    filename_noext="${filename%.*}"

    # Definiere den Ausgabepfad für die DNxHD-Datei mit variabler Bitrate
    output_file="$output_folder/$filename_noext-dnxhd${bitrate}.mov"

    # Verwende ffmpeg zur Umwandlung in DNxHD mit variabler Bitrate
    ffmpeg -i "$input_file" -c:v dnxhd -b:v "${bitrate}M" -c:a pcm_s16le "$output_file"

    echo "Konvertiere $filename zu $output_file mit Bitrate $bitrate"
  done
done

echo "Konvertierung abgeschlossen."
