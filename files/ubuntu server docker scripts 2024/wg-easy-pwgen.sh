
#!/bin/bash

# Passwort vom Benutzer abfragen
read -sp "Bitte geben Sie das Passwort für wg-easy ein: " PASSWORD
echo

# Docker-Befehl ausführen und Ausgabe in Datei speichern
sudo docker run -it ghcr.io/wg-easy/wg-easy wgpw "$PASSWORD" > wg-easy-hash.txt

# Datei bearbeiten: jedem $-Symbol ein zweites $-Symbol voranstellen, PASSWORD_HASH= und ' entfernen
sed -i 's/\$/\$\$/g' wg-easy-hash.txt
sed -i 's/PASSWORD_HASH=//g' wg-easy-hash.txt
sed -i "s/'//g" wg-easy-hash.txt

echo "Die Ausgabe wurde in wg-easy-hash.txt gespeichert und bearbeitet."
cat wg-easy-hash.txt