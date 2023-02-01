#!/bin/bash

# Replace these with your own Strato login credentials
strato_username="your_strato_username"
strato_password="your_strato_password"

# Replace this with the hostname you want to update
hostname="your_dns_hostname.example.com"

# Find the current IPv4 address using ifconfig.co
ip_address=$(curl -4 -s https://ifconfig.co/ip)

# Construct the URL to update the host
url="https://dyndns.strato.com/nic/update?hostname=${hostname}&myip=${ip_address}"

# Perform the request to update the host via IPv4
response=$(curl -4 -u "${strato_username}:${strato_password}" "${url}")

# Check the response and print a message
if [ "${response}" == "good ${ip_address}" ]; then
  echo "DNS host successfully updated"
else
  echo "Error updating DNS host: ${response}"
fi
