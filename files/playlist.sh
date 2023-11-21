#!/bin/bash

# Array with ARD and ZDF channels
channels=( "Das Erste" "BR Fernsehen" "hr-fernsehen" "MDR Fernsehen" "NDR Fernsehen" "Radio Bremen TV" "rbb Fernsehen" "SR Fernsehen" "SWR Fernsehen BW" "SWR Fernsehen RP" "WDR Fernsehen" "3sat" "arte" "KiKA" "Phoenix" "tagesschau24" "ONE" )

# Function to get the stream URL of a given program
get_stream_url () {
    local program_name="$1"
    local stream_url=$(curl -s "https://api.ardmediathek.de/list/$program_name" | grep -oP '(?<=url":")[^"]*(?=","quality")' | sed 's/\\\//\//g')
    echo "$stream_url"
}

# Loop through the channels array and get the stream URLs for each channel
for channel in "${channels[@]}"
do
    echo "#EXTINF:-1,$channel"
    stream_url=$(get_stream_url "$channel")
    if [[ -n "$stream_url" ]]
    then
        echo "$stream_url"
    fi
done
