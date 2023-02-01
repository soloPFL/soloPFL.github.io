#!/bin/bash

if ! dpkg -s vsftpd &> /dev/null; then
    # vsftpd is not installed, install it
    sudo apt-get update
    sudo apt-get install vsftpd -y
else
    echo "vsftpd is already installed."
fi

if [ -f "/etc/vsftpd.conf.bak" ]; then
    # vsftpd is already configured, do nothing
    echo "vsftpd is already configured."
else
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
    sudo chmod 775 /var/ftp/shared
fi

# Get the number of FTP users
echo -n "Enter the number of FTP users: "
read num_ftp_users

# Create a group for FTP users
sudo groupadd ftpusers

# Loop to create FTP users
for (( i=1; i<=num_ftp_users; i++ ))
do
    echo -n "Enter FTP username $i: "
    read ftp_username

    if id "$ftp_username" >/dev/null 2>&1; then
        echo "$ftp_username already exists."
    else
        echo -n "Enter password for $ftp_username: "
        read ftp_password

        # Create the FTP user and set its password
        sudo useradd $ftp_username
        echo "$ftp_username:$ftp_password" | sudo chpasswd

        # Add the user to the ftpusers group
        sudo usermod -a -G ftpusers $ftp_username

        # Add the user to the userlist file
        echo $ftp_username >> /etc/vsftpd.userlist
    fi
done

# Set the shared folder's group to ftpusers
sudo chgrp ftpusers /var/ftp/shared

# Restart vsftpd to apply the changes
sudo service vsftpd restart
