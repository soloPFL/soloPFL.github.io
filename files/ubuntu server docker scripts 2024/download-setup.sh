#!/bin/bash

# URLs der Dateien
URL1="https://raw.githubusercontent.com/soloPFL/soloPFL.github.io/main/files/ubuntu%20server%20docker%20scripts%202024/install-docker-nc-aio-ubuntu-V2.sh"
URL2="https://raw.githubusercontent.com/soloPFL/soloPFL.github.io/main/files/ubuntu%20server%20docker%20scripts%202024/npm-installV2.sh"
URL3="https://raw.githubusercontent.com/soloPFL/soloPFL.github.io/main/files/ubuntu%20server%20docker%20scripts%202024/install-jellyfinV3.sh"
URL4="https://raw.githubusercontent.com/soloPFL/soloPFL.github.io/main/files/ubuntu%20server%20docker%20scripts%202024/install-wg-easy.sh"

# Namen der heruntergeladenen Dateien
FILE1="install-docker-nc-aio-ubuntu-V2.sh"
FILE2="npm-installV2.sh"
FILE3="install-jellyfinV3.sh"
FILE4="install-wg-easy.sh"

# Dateien herunterladen
wget -O $FILE1 $URL1
wget -O $FILE2 $URL2
wget -O $FILE3 $URL3
wget -O $FILE4 $URL4

# Dateien ausführbar machen
chmod +x $FILE1
chmod +x $FILE2
chmod +x $FILE3
chmod +x $FILE4

# Bestätigung ausgeben
echo "Die Dateien $FILE1, $FILE2, $FILE3 und $FILE4 wurden heruntergeladen und ausführbar gemacht."
