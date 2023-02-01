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

# Get the number of FTP users
echo -n "Enter the number of FTP users: "
read num_ftp_users

# Loop to create FTP users
for (( i=1; i<=num_ftp_users; i++ ))
do
    echo -n "Enter FTP username $i: "
    read ftp_username

    echo -n "Enter password for $ftp_username: "
    read ftp_password

    # Create the FTP user and set its password
    sudo useradd $ftp_username
    echo "$ftp_username:$ftp_password" | sudo chpasswd

    # Add the user to the userlist file
    echo $ftp_username >> /etc/vsftpd.userlist
done

# Restart vsftpd to apply the changes
sudo service vsftpd restart
