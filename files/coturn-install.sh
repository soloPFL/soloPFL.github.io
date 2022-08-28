#! /bin/bash




apt-get -y update
apt-get -y install coturn

#activate the service

rm /etc/default/coturn
touch /etc/default/coturn
echo "TURNSERVER_ENABLED=1" >> /etc/default/coturn

# Move the original turnserver configuration file to a backup in the same directory
mv /etc/turnserver.conf /etc/turnserver.conf.original
touch /etc/turnserver.conf
# get the config 


read -p 'Input a shared secret aka password : ' pwdinput
read -p 'Input you hostname aka realm : ' hostinput
password=$pwdinput
host=$hostinput

echo "listening-port=3478" >> /etc/turnserver.conf
echo "fingerprint" >> /etc/turnserver.conf
echo "lt-cred-mech" >> /etc/turnserver.conf
echo "use-auth-secret" >> /etc/turnserver.conf
echo "static-auth-secret=$password" >> /etc/turnserver.conf
echo "realm=$host" >> /etc/turnserver.conf
echo "no-tls" >> /etc/turnserver.conf
echo "no-dtls" >> /etc/turnserver.conf
echo "syslog" >> /etc/turnserver.conf

service coturn restart
sleep 3
service coturn status
