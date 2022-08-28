#! /bin/bash
apt-get -y update
apt-get -y install coturn

#activate the service

rm /etc/default/coturn
touch /etc/default/coturn
echo "TURNSERVER_ENABLED=1" >> /etc/default/coturn

# Move the original turnserver configuration file to a backup in the same directory
mv /etc/turnserver.conf /etc/turnserver.conf.original

# get the config 
wget -c https://raw.githubusercontent.com/soloPFL/soloPFL.github.io/main/files/turnserver-clean.conf -O turnserver.conf
cat ./turnserver.conf
echo "moving this file to /etc/turnserver.conf now... "
mv ./turnserver.conf /etc/turnserver.conf

sed -i 's/[your-password]/theunbelievablepassword/' /etc/turnserver.conf
sed -i 's/[your-server-address]/theunbelievableserveraddress/' /etc/turnserver.conf