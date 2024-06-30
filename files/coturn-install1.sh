#!/bin/bash

# Install Coturn and generate a random shared secret

read -p "Enter your domain name: " DOMAIN
SHARED_SECRET=$(openssl rand -hex 20)

sudo apt-get update
sudo apt-get install coturn -y

# Backup the original configuration file
sudo cp /etc/turnserver.conf /etc/turnserver.conf.bak

# Configure Coturn
sudo sed -i "s/#listening-port=3478/listening-port=3478/g" /etc/turnserver.conf
sudo sed -i "s/#tls-listening-port=5349/tls-listening-port=5349/g" /etc/turnserver.conf
sudo sed -i "s/#fingerprint/certificate-fingerprint/g" /etc/turnserver.conf
sudo sed -i "s/#lt-cred-mech/lt-cred-mech/g" /etc/turnserver.conf
sudo sed -i "s/#use-auth-secret/use-auth-secret/g" /etc/turnserver.conf
sudo sed -i "s/#static-auth-secret=static-auth-secret/static-auth-secret=$SHARED_SECRET/g" /etc/turnserver.conf
sudo sed -i "s/#realm=.*/realm=$DOMAIN/g" /etc/turnserver.conf
sudo sed -i "s/#total-quota=100/total-quota=1000/g" /etc/turnserver.conf
sudo sed -i "s/#bps-capacity=0/bps-capacity=3000000/g" /etc/turnserver.conf

# Add user and password
sudo sed -i "s/#user=.*/user=%u:$SHARED_SECRET/g" /etc/turnserver.conf

# Restart Coturn
sudo systemctl restart coturn

# Display the shared secret
echo "The shared secret is: $SHARED_SECRET"
