#!/bin/bash

# Set your domain name here
YOUR_DOMAIN="example.com"

# Get the script's directory
SCRIPT_DIR=$(pwd)
SCRIPT_NAME=$(basename "$0")

# Define log file path
LOG_FILE="$SCRIPT_DIR/script_log.txt"

# Function to rotate the log file
rotate_log() {
    if [ -f "$LOG_FILE" ]; then
        mv "$LOG_FILE" "$LOG_FILE.$(date +'%Y%m%d%H%M%S')"
    fi
    touch "$LOG_FILE"
}

# Rotate the log before writing
rotate_log

# Redirect script output to both the terminal and the log file
exec > >(tee -a "$LOG_FILE") 2>&1

# Construct the cron job entry
CRONTAB_ENTRY="0 2 * * * $SCRIPT_DIR/$SCRIPT_NAME"

# Check if the script is already in the crontab
if ! crontab -l | grep -q "$CRONTAB_ENTRY"; then
    echo "Do you want to add this script to your crontab to run daily at 2 AM? (y/n)"
    read choice

    if [ "$choice" == "y" ] || [ "$choice" == "Y" ]; then
        # Add the script to the crontab
        (crontab -l ; echo "$CRONTAB_ENTRY") | crontab -
        echo "Script added to crontab."
    else
        echo "Script not added to crontab."
    fi
else
    echo "Script is already present in the crontab."
fi

# Specify the paths for your certificate files
CERT_PATH="/etc/letsencrypt/live/$YOUR_DOMAIN/fullchain.pem"
PREV_CERT_HASH="/tmp/prev_cert_hash"

# Get the current hash of the certificate
CERT_HASH=$(md5sum "$CERT_PATH" | cut -d ' ' -f 1)

# Check if the previous hash is different from the current hash
if [ -f "$PREV_CERT_HASH" ] && [ "$(cat "$PREV_CERT_HASH")" == "$CERT_HASH" ]; then
    echo "Certificate has not changed. No action needed."
    exit 0
fi

# Store the current hash as the previous hash
echo "$CERT_HASH" > "$PREV_CERT_HASH"

# Find the process ID of murmurd
MURMURD_PID=$(pgrep -x murmurd)

if [ -z "$MURMURD_PID" ]; then
    echo "murmurd process not found."
    exit 1
fi

# Send the SIGUSR1 signal to reload the certificate
kill -SIGUSR1 $MURMURD_PID

echo "Sent SIGUSR1 signal to reload the certificate for the murmurd process."

# Short delay before restarting the server (adjust as needed)
sleep 5

# Restart the murmurd server
sudo service murmurd restart

echo "murmurd server has been restarted."
