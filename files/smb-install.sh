#!/bin/bash
# samba_setup.sh
# This script installs Samba (if needed) and provides a menu to configure shares,
# adjust folder permissions, manage Samba users, and remove a share.
#
# Default permissions are set so that only known, authenticated Samba users
# may access and edit files. The script checks if any Samba user is configured
# and prompts you to create one if none exist. Additionally, when creating a user,
# you are prompted to set a password, and an option to edit a Samba user's password
# is provided.

# Ensure the script is run as root.
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root."
  exit 1
fi

# Function to check for and install Samba.
install_samba() {
  if ! dpkg -l | grep -q samba; then
    echo "Samba is not installed. Installing..."
    apt-get update && apt-get install samba -y
    if [ $? -ne 0 ]; then
      echo "Error installing Samba. Exiting."
      exit 1
    fi
  else
    echo "Samba is already installed."
  fi
}

# Function to check if any Samba users are configured.
check_samba_users() {
  # pdbedit -L lists Samba users; if none, prompt to create one.
  if ! pdbedit -L 2>/dev/null | grep -q '.'; then
    echo "No Samba users are configured."
    read -p "Do you want to create a Samba user now? (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
      add_samba_user
    else
      echo "Warning: Without Samba users, shares requiring authentication won't be accessible."
    fi
  else
    echo "Samba users are already configured."
  fi
}

# Function to add a new share to the Samba configuration.
add_share() {
  read -p "Enter share name (no spaces): " sharename
  read -p "Enter full directory path for the share: " dirpath
  read -p "Enter a comment/description for the share: " comment
  read -p "Enter comma-separated list of valid Samba users for this share (leave blank to allow all configured users): " valid_users

  # Create the directory if it does not exist.
  if [ ! -d "$dirpath" ]; then
    mkdir -p "$dirpath"
    echo "Directory created."
  fi

  # Set secure directory permissions (0770) so that only the owner and group have access.
  chmod 0770 "$dirpath"

  # Append share configuration to smb.conf with authentication required.
  {
    echo ""
    echo "[$sharename]"
    echo "   path = $dirpath"
    echo "   browseable = yes"
    echo "   writable = yes"
    echo "   guest ok = no"
    if [ -n "$valid_users" ]; then
      echo "   valid users = $valid_users"
    fi
    echo "   comment = $comment"
  } >> /etc/samba/smb.conf

  echo "Share '$sharename' added. Remember to restart Samba to apply changes."
}

# Function to remove an existing share from the Samba configuration.
remove_share() {
  read -p "Enter the share name to remove: " sharename
  # Backup the original configuration file.
  cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
  # Use Perl to remove the block corresponding to the share.
  perl -0777 -pi -e "s/\[\Q$sharename\E\].*?(?=\n\[|$)//s" /etc/samba/smb.conf
  echo "Share '$sharename' removed (backup saved as /etc/samba/smb.conf.bak)."
}

# Function to change permissions on a shared folder.
change_permissions() {
  read -p "Enter the full path of the directory: " dirpath
  if [ ! -d "$dirpath" ]; then
    echo "Directory does not exist."
    return
  fi
  read -p "Enter new permissions (e.g., 0770): " perms
  chmod "$perms" "$dirpath"
  echo "Permissions for $dirpath changed to $perms."
}

# Function to add a Samba user.
add_samba_user() {
  read -p "Enter the username to add: " username
  # Check if the Unix user exists. If not, ask to create it.
  if id "$username" &>/dev/null; then
    echo "User exists in the system."
  else
    read -p "User does not exist. Create a system user for '$username'? (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
      useradd -m "$username"
      echo "System user '$username' created."
    else
      echo "User not created. Returning to menu."
      return
    fi
  fi
  # Ask for Samba password.
  while true; do
    read -s -p "Enter Samba password for '$username': " password
    echo
    read -s -p "Confirm Samba password: " password_confirm
    echo
    if [ "$password" != "$password_confirm" ]; then
      echo "Passwords do not match. Please try again."
    else
      break
    fi
  done
  # Add the user to Samba using non-interactive mode.
  echo -e "$password\n$password" | smbpasswd -a -s "$username"
  echo "Samba user '$username' added."
}

# Function to edit a Samba user's password.
edit_samba_password() {
  read -p "Enter the Samba username to edit the password: " username
  # Check if the Samba user exists.
  if ! pdbedit -L 2>/dev/null | grep -q "^$username:"; then
    echo "Samba user '$username' does not exist."
    return
  fi
  while true; do
    read -s -p "Enter new password for '$username': " password
    echo
    read -s -p "Confirm new password: " password_confirm
    echo
    if [ "$password" != "$password_confirm" ]; then
      echo "Passwords do not match. Please try again."
    else
      break
    fi
  done
  echo -e "$password\n$password" | smbpasswd -s "$username"
  echo "Password updated for user '$username'."
}

# Function to remove a Samba user.
remove_samba_user() {
  read -p "Enter the username to remove from Samba: " username
  smbpasswd -x "$username"
  echo "Samba user '$username' removed."
}

# Function to restart Samba services.
restart_samba() {
  systemctl restart smbd
  systemctl restart nmbd
  echo "Samba services have been restarted."
}

# Main menu loop.
menu() {
  while true; do
    clear
    echo "-----------------------------------"
    echo "      Samba Configuration Menu     "
    echo "-----------------------------------"
    echo "1. Add new share"
    echo "2. Remove a share"
    echo "3. Change share folder permissions"
    echo "4. Add Samba user"
    echo "5. Edit Samba user password"
    echo "6. Remove Samba user"
    echo "7. Restart Samba services"
    echo "8. Exit"
    echo "-----------------------------------"
    read -p "Select an option [1-8]: " option

    case $option in
      1) add_share ;;
      2) remove_share ;;
      3) change_permissions ;;
      4) add_samba_user ;;
      5) edit_samba_password ;;
      6) remove_samba_user ;;
      7) restart_samba ;;
      8) echo "Exiting."; exit 0 ;;
      *) echo "Invalid option. Please try again." ; sleep 2 ;;
    esac
    echo ""
    read -p "Press Enter to continue..."
  done
}

# Execution starts here.
install_samba
check_samba_users
menu
