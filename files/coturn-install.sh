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
echo "no-multicast-peers" >> /etc/turnserver.conf
echo "no-tcp-relay" >> /etc/turnserver.conf
echo "denied-peer-ip=10.0.0.0-10.255.255.255" >> /etc/turnserver.conf
echo "denied-peer-ip=192.168.0.0-192.168.255.255" >> /etc/turnserver.conf
echo "denied-peer-ip=172.16.0.0-172.31.255.255" >> /etc/turnserver.conf
echo "denied-peer-ip=0.0.0.0-0.255.255.255" >> /etc/turnserver.conf
echo "denied-peer-ip=100.64.0.0-100.127.255.255" >> /etc/turnserver.conf
echo "denied-peer-ip=127.0.0.0-127.255.255.255" >> /etc/turnserver.conf
echo "denied-peer-ip=169.254.0.0-169.254.255.255" >> /etc/turnserver.conf
echo "denied-peer-ip=192.0.0.0-192.0.0.255" >> /etc/turnserver.conf
echo "denied-peer-ip=192.0.2.0-192.0.2.255" >> /etc/turnserver.conf
echo "denied-peer-ip=192.88.99.0-192.88.99.255" >> /etc/turnserver.conf
echo "denied-peer-ip=198.18.0.0-198.19.255.255" >> /etc/turnserver.conf
echo "denied-peer-ip=198.51.100.0-198.51.100.255" >> /etc/turnserver.conf
echo "denied-peer-ip=203.0.113.0-203.0.113.255" >> /etc/turnserver.conf
echo "denied-peer-ip=240.0.0.0-255.255.255.255" >> /etc/turnserver.conf
service coturn restart
sleep 3
service coturn status
