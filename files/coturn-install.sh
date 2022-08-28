#! /bin/bash
apt-get -y update
apt-get -y install coturn

#activate the service

rm /etc/default/coturn
touch /etc/default/coturn
echo "TURNSERVER_ENABLED=1" >> /etc/default/coturn

# Move the original turnserver configuration file to a backup in the same directory
mv /etc/turnserver.conf /etc/turnserver.conf.original


wget -c URL  -O turnserver.conf
cat ./turnserver.conf
echo "moving this file to /etc/turnserver.conf now... "
mv ./turnserver.conf /etc/turnserver.conf
nano /etc/turnserver.conf
