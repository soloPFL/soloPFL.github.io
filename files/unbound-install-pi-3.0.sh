#!/bin/bash

# install unbound and dnsutils
sudo apt-get update
sudo apt-get install unbound dnsutils

# backup original configuration
sudo cp /etc/unbound/unbound.conf /etc/unbound/unbound.conf.bak

# prompt user to use upstream servers using DoT
echo "Do you want to forward requests to an upstream server using DoT (yes/no)?"
read use_dot

if [ "$use_dot" = "yes" ]; then
  # configure unbound to use upstream servers using DoT
  sudo bash -c 'cat >> /etc/unbound/unbound.conf << EOL
  # Use upstream servers
  forward-zone:
    name: "."
    forward-addr: dot.ffmuc.net@853
  EOL'
fi

# create necessary directories if they do not exist
if [ ! -d "/var/cache/unbound" ]; then
  sudo mkdir -p "/var/cache/unbound"
fi

if [ ! -d "/var/lib/unbound" ]; then
  sudo mkdir -p "/var/lib/unbound"
fi

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

# download root hints
sudo unbound-anchor -a "/var/lib/unbound/root.key"
sudo wget -O "/var/cache/unbound/root.hints" "https://www.internic.net/domain/named.cache"

# restart unbound
sudo systemctl restart unbound

# create a cronjob to update the root hints once a month
sudo bash -c 'cat > /etc/cron.monthly/update-root-hints.sh << EOL
#!/bin/bash
sudo wget -O "/var/cache/unbound/root.hints" "https://www.internic.net/domain/named.cache"
sudo systemctl restart unbound
EOL'
sudo chmod +x /etc/cron.monthly/update-root-hints.sh
