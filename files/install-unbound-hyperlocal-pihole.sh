#! /bin/bash

#Install unbound
apt install unbound
#Download the unbound config and creat other configs
wget -P /etc/unbound/unbound.conf.d/ -O pi-hole.conf https://raw.githubusercontent.com/soloPFL/soloPFL.github.io/main/files/pi-hole.conf-unbound
touch /etc/dnsmasq.d/99-edns.conf
echo 'edns-packet-max=1232' >> /etc/dnsmasq.d/99-edns.conf
service unbound restart