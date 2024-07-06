#!/bin/bash

# Pfad zur Eingabedatei
INPUT_FILE="/home/ubuntu/video/in.mp4"

# Pfad zur Ausgabedatei
OUTPUT_FILE="/home/ubuntu/video/out.mp4"

# ffmpeg-Befehl ausführen
ffmpeg -i "$INPUT_FILE" -c:v libx264 -b:v 4M -c:a aac -threads 1 "$OUTPUT_FILE"

rm -f "$OUTPUT_FILE"
echo "$OUTPUT_FILE wurde gelöscht."