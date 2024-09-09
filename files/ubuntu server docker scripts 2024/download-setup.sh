#!/bin/bash

# URLs der Dateien
URL1="https://raw.githubusercontent.com/soloPFL/soloPFL.github.io/main/files/ubuntu%20server%20docker%20scripts%202024/install-docker-nc-aio-ubuntu-V2.sh"
URL2="https://raw.githubusercontent.com/soloPFL/soloPFL.github.io/main/files/ubuntu%20server%20docker%20scripts%202024/npm-installV2.sh"
URL3="https://raw.githubusercontent.com/soloPFL/soloPFL.github.io/main/files/ubuntu%20server%20docker%20scripts%202024/install-jellyfinV3.sh"
URL4="https://raw.githubusercontent.com/soloPFL/soloPFL.github.io/main/files/ubuntu%20server%20docker%20scripts%202024/install-wg-easy.sh"
URL5="https://raw.githubusercontent.com/soloPFL/soloPFL.github.io/main/files/ubuntu%20server%20docker%20scripts%202024/wg-easy-pwgen.sh"

# Namen der heruntergeladenen Dateien
FILE1="install-docker-nc-aio-ubuntu-V2.sh"
FILE2="npm-installV2.sh"
FILE3="install-jellyfinV3.sh"
FILE4="install-wg-easy.sh"
FILE5="wg-easy-pwgen.sh"

# Dateien herunterladen
wget -O $FILE1 $URL1
wget -O $FILE2 $URL2
wget -O $FILE3 $URL3
wget -O $FILE4 $URL4
wget -O $FILE5 $URL5

# Dateien ausführbar machen
chmod +x $FILE1
chmod +x $FILE2
chmod +x $FILE3
chmod +x $FILE4
chmod +x $FILE5


# Bestätigung ausgeben
echo "Die Dateien $FILE1, $FILE2, $FILE3, $FILE4 und $FILE5 wurden heruntergeladen und ausführbar gemacht."
