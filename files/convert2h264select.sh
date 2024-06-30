#!/bin/bash

# Eingabeordner (aktuelles Verzeichnis)
input_folder="."

# Ausgabeordner (relativer Pfad)
output_folder="output_h264"

# Unterstützte Erweiterungen der Videodateien
video_extensions=("mov" "mp4" "m4v" "mkv")

# Standard-Bitrate
default_bitrate="12"

# Überprüfe, ob der Ausgabeordner existiert, andernfalls erstelle ihn
if [ ! -d "$output_folder" ]; then
  mkdir "$output_folder"
fi

# Überprüfe, ob die Bitrate als Parameter übergeben wurde
if [ -z "$1" ]; then
  bitrate="$default_bitrate"
else
  # Überprüfe, ob die angegebene Bitrate unterstützt wird
  case "$1" in
    6|12|24|50|100)
      bitrate="$1"
      ;;
    *)
      echo "Ungültige Bitrate. Unterstützte Werte sind 6, 12, 24, 50, 100 (oder keine Angabe für $default_bitrate MBit)."
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

    # Definiere den Ausgabepfad für die H.264-Datei mit variabler Bitrate
    output_file="$output_folder/$filename_noext-h264${bitrate}.mp4"

    # Verwende ffmpeg zur Umwandlung in H.264 mit variabler Bitrate
    ffmpeg -i "$input_file" -c:v libx264 -b:v "${bitrate}M" -c:a aac -strict experimental "$output_file"

    echo "Konvertiere $filename zu $output_file mit Bitrate $bitrate MBit"
  done
done

echo "Konvertierung abgeschlossen."
