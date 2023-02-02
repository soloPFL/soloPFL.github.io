#!/bin/bash

# Check if vsftpd is already installed
if ! dpkg-query -W vsftpd; then
  sudo apt-get update
  sudo apt-get install vsftpd -y
fi

# Generate self-signed SSL certificate
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/vsftpd.pem -out /etc/ssl/certs/vsftpd.pem -subj "/C=DE/ST=Bayern/L=Rosenheim/O=Org/CN=vsftpd"

# Add FTP user if not already exists
read -p "Enter FTP username: " ftp_username
if ! id "$ftp_username" >/dev/null 2>&1; then
  sudo useradd -m $ftp_username -s /usr/sbin/nologin
fi

# Set FTP user password
echo "Setting password for FTP user $ftp_username"
sudo passwd $ftp_username

# Create shared directory if not already exists
shared_dir="/var/ftp/shared"
if [ ! -d "$shared_dir" ]; then
  sudo mkdir -p $shared_dir
  sudo chown nobody:nogroup $shared_dir
  sudo chmod a-w $shared_dir
fi

# Backup original config file
sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.bak

# Configure vsftpd
sudo bash -c "cat > /etc/vsftpd.conf <<EOF
listen=YES
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
chroot_local_user=YES
secure_chroot_dir=/var/run/vsftpd/empty
rsa_cert_file=/etc/ssl/certs/vsftpd.pem
rsa_private_key_file=/etc/ssl/private/vsftpd.pem
ssl_enable=YES
allow_anon_ssl=NO
force_local_data_ssl=YES
force_local_logins_ssl=YES
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO
pam_service_name=vsftpd
user_config_dir=/etc/vsftpd_user_conf
EOF"

# Create user config directory
sudo mkdir /etc/vsftpd_user_conf

# Create user config file
sudo bash -c "cat > /etc/vsftpd_user_conf/$ftp_username <<EOF
local_root=$shared_dir
write_enable=YES
EOF"

# Restart vsftpd service
sudo systemctl restart vsftpd
