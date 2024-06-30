#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Verwendung: $0 <Port> <tcp|udp>"
    exit 1
fi

PORT="$1"
PROTOCOL="$2"

# Überprüfen, ob das Protokoll gültig ist
if [ "$PROTOCOL" != "tcp" ] && [ "$PROTOCOL" != "udp" ]; then
    echo "Ungültiges Protokoll. Verwende 'tcp' oder 'udp'."
    exit 1
fi

# Regel hinzufügen
sudo iptables -I INPUT 5 -i ens3 -p "$PROTOCOL" --dport "$PORT" -m state --state NEW,ESTABLISHED -j ACCEPT

sudo iptables-save > /etc/iptables/rules.v4

echo "Regel hinzugefügt: $PROTOCOL Port $PORT"
