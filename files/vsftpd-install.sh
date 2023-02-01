#!/bin/bash

# Update the package repository
sudo apt-get update

# Install vsftpd
sudo apt-get install vsftpd -y

# Backup the default configuration file
sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.bak

# Write a new configuration file
sudo echo "listen=YES" > /etc/vsftpd.conf
sudo echo "local_enable=YES" >> /etc/vsftpd.conf
sudo echo "write_enable=YES" >> /etc/vsftpd.conf
sudo echo "local_umask=022" >> /etc/vsftpd.conf
sudo echo "chroot_local_user=NO" >> /etc/vsftpd.conf
sudo echo "user_sub_token=\$USER" >> /etc/vsftpd.conf
sudo echo "local_root=/var/ftp/shared" >> /etc/vsftpd.conf
sudo echo "userlist_enable=YES" >> /etc/vsftpd.conf
sudo echo "userlist_file=/etc/vsftpd.userlist" >> /etc/vsftpd.conf
sudo echo "userlist_deny=NO" >> /etc/vsftpd.conf

# Create the shared folder and set permissions
sudo mkdir /var/ftp/shared
sudo chmod 777 /var/ftp/shared

# Create the FTP users and set their passwords
sudo useradd ftpuser1
echo "ftpuser1:password1" | sudo chpasswd
sudo useradd ftpuser2
echo "ftpuser2:password2" | sudo chpasswd

# Create the userlist file and add users
sudo echo "ftpuser1" > /etc/vsftpd.userlist
sudo echo "ftpuser2" >> /etc/vsftpd.userlist

# Restart vsftpd to apply the changes
sudo service vsftpd restart
