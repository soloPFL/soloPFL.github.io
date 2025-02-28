#!/bin/bash

# working
# Setup script for Unbound Hyperlocal DNS with debug capabilities
# This script creates all necessary files and sets appropriate permissions

# Exit on error
set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Setting up Unbound Hyperlocal DNS in $SCRIPT_DIR"

# Create necessary directories
mkdir -p config

# Create docker-compose.yml
echo "Creating docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  unbound:
    build: 
      context: .
      dockerfile: Dockerfile
    container_name: unbound
    restart: unless-stopped
    hostname: unbound
    volumes:
      - ./config:/opt/unbound/etc/unbound/
    network_mode: host
    environment:
      - TZ=UTC
EOF

# Create Dockerfile with debugging capabilities
echo "Creating Dockerfile..."
cat > Dockerfile << 'EOF'
FROM mvance/unbound:latest

# Install required packages using apt-get
RUN apt-get update && apt-get install -y curl

# Create update script
RUN mkdir -p /opt/scripts
COPY update-root-hints.sh /opt/scripts/update-root-hints.sh
RUN chmod +x /opt/scripts/update-root-hints.sh

# Modify startup
COPY entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
EOF

# Create update-root-hints.sh script
echo "Creating update-root-hints.sh..."
cat > update-root-hints.sh << 'EOF'
#!/bin/sh
# Script to update root hints file for Unbound DNS server

# Download the latest root hints
curl -s -o /opt/unbound/etc/unbound/root.hints https://www.internic.net/domain/named.cache

# Reload Unbound configuration to use the new hints if running
if pidof unbound > /dev/null; then
    unbound-control reload
    echo "Root hints updated successfully: $(date)"
else
    echo "Unbound not running, cannot reload configuration"
fi
EOF

# Create entrypoint with enhanced debugging and root.key generation
echo "Creating entrypoint.sh..."
cat > entrypoint.sh << 'EOF'
#!/bin/sh

# Download fresh root hints on startup
echo "Downloading fresh root hints..."
curl -s -o /opt/unbound/etc/unbound/root.hints https://www.internic.net/domain/named.cache

# Generate or update root trust anchor
echo "Generating root trust anchor..."
unbound-anchor -a /opt/unbound/etc/unbound/root.key || true
chmod 644 /opt/unbound/etc/unbound/root.key

# Check if config file exists
echo "Checking configuration..."
if [ ! -f /opt/unbound/etc/unbound/unbound.conf ]; then
    echo "ERROR: unbound.conf not found in the expected location"
    exit 1
fi

# Validate configuration before starting
echo "Validating Unbound configuration..."
/opt/unbound/sbin/unbound-checkconf /opt/unbound/etc/unbound/unbound.conf
if [ $? -ne 0 ]; then
    echo "ERROR: Configuration validation failed. See above for details."
    exit 1
fi

# List all files in the configuration directory
echo "Configuration directory contents:"
ls -la /opt/unbound/etc/unbound/

# Start Unbound with verbose logging
echo "Starting Unbound DNS server in debug mode..."
exec /opt/unbound/sbin/unbound -d -vvv -c /opt/unbound/etc/unbound/unbound.conf
EOF

# Create simplified unbound.conf
echo "Creating unbound.conf..."
cat > config/unbound.conf << 'EOF'
server:
    # Run as root user (simplifies things in container environment)
    username: ""

    # Log verbosely
    verbosity: 2
    use-syslog: yes

    # Listen on all interfaces, port 5353
    interface: 0.0.0.0
    port: 5353
    do-ip4: yes
    do-ip6: yes
    do-udp: yes
    do-tcp: yes

    # Security settings
    hide-identity: yes
    hide-version: yes
    harden-glue: yes
    harden-dnssec-stripped: yes

    # DNSSEC
    auto-trust-anchor-file: "/opt/unbound/etc/unbound/root.key"
    root-hints: "/opt/unbound/etc/unbound/root.hints"

    # Access control
    access-control: 0.0.0.0/0 allow
    access-control: ::/0 allow
EOF

# Download initial root.hints
echo "Downloading initial files..."
curl -s -o config/root.hints https://www.internic.net/domain/named.cache

# Create an initial empty root.key file with the correct permissions
touch config/root.key
chmod 644 config/root.key

# Set permissions
echo "Setting file permissions..."
chmod +x update-root-hints.sh entrypoint.sh
chmod 644 config/unbound.conf config/root.hints

echo "Setup complete! Run 'docker compose down && docker compose up -d --build' to rebuild and start the container."
