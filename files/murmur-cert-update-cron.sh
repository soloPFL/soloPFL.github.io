#!/bin/bash

# Get the script's directory
SCRIPT_DIR=$(pwd)
SCRIPT_NAME=$0

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
