#!/bin/bash

# install unbound
sudo apt-get update
sudo apt-get install unbound

# backup original configuration
sudo cp /etc/unbound/unbound.conf /etc/unbound/unbound.conf.bak

# configure unbound to use root servers and allow access from the LAN
sudo bash -c 'cat > /etc/unbound/unbound.conf << EOL
# Unbound configuration file for using root servers and allowing LAN access
server:
  # Use root servers
  root-hints: "/var/cache/unbound/root.hints"
  # Enable DNSSEC validation
  auto-trust-anchor-file: "/var/lib/unbound/root.key"
  val-clean-additional: yes
  # Respond to queries from localhost and the LAN
  interface: 0.0.0.0
  access-control: 0.0.0.0/0 allow
EOL'

# create necessary directories if they don't exist
if [ ! -d "/var/cache/unbound" ]; then
  sudo mkdir -p "/var/cache/unbound"
fi

if [ ! -d "/var/lib/unbound" ]; then
  sudo mkdir -p "/var/lib/unbound"
fi

# download root hints
sudo unbound-anchor -a "/var/lib/unbound/root.key"
sudo wget -O "/var/cache/unbound/root.hints" "https://www.internic.net/domain/named.cache"

# restart unbound
sudo systemctl restart unbound

# Indicate that the script has run successfully
echo "Unbound has been successfully installed and configured!"
