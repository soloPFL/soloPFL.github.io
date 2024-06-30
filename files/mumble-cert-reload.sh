#!/bin/bash

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
