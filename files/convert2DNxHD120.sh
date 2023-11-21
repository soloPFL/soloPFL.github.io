#!/bin/bash

# Eingabeordner (aktuelles Verzeichnis)
input_folder="."

# Ausgabeordner (relativer Pfad)
output_folder="output"

# Erweiterungen der Videodateien
video_extensions=("mov" "mp4" "m4v" "mkv")

# Überprüfe, ob der Ausgabeordner existiert, andernfalls erstelle ihn
if [ ! -d "$output_folder" ]; then
  mkdir "$output_folder"
fi

# Schleife durch alle Videodateien im Eingabeordner mit den angegebenen Erweiterungen
for ext in "${video_extensions[@]}"; do
  for input_file in "$input_folder"/*."$ext"; do
    # Extrahiere Dateiname ohne Erweiterung und Pfad
    filename=$(basename -- "$input_file")
    filename_noext="${filename%.*}"

    # Definiere den Ausgabepfad für die DNxHD 90-Datei
    output_file="$output_folder/$filename_noext-dnxhd90.mov"

    # Verwende ffmpeg zur Umwandlung in DNxHD 120
    ffmpeg -i "$input_file" -c:v dnxhd -b:v 120M -c:a pcm_s16le "$output_file"

    echo "Konvertiere $filename zu $output_file"
  done
done

echo "Konvertierung abgeschlossen."
