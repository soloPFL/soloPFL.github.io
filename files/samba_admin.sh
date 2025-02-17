#!/bin/bash
# samba_admin.sh
# Comprehensive Samba Administration Script for Ubuntu
#
# This script installs/updates Samba and provides an interactive menu for:
#   - Configuring global settings (workgroup, server string, netbios name, security)
#   - Managing shares (adding, removing, listing, and setting folder permissions)
#   - Managing Samba users (adding with password setup, editing passwords, removing, and listing)
#   - Backing up/restoring the smb.conf file and restarting Samba services
#   - Testing the configuration (using testparm)
#   - Viewing Samba logs and active connections
#   - Displaying a table of shares with their directory paths and valid users
#   - Generating an fstab entry for client mounting
#   - Fixing access rights for all shares based on their configured valid users
#   - Setting (or updating) which users can access a specific share
#   - Displaying a manual that explains all options and what they do
#
# Sensible defaults are used when settings are not specified.
#
# Run this script as root.

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

CONFIG_FILE="/etc/samba/smb.conf"
BACKUP_FILE="/etc/samba/smb.conf.bak"

##############################
# Install/Update Samba       #
##############################
install_samba() {
    echo "Updating package lists..."
    apt-get update -y

    echo "Installing/updating Samba..."
    output=$(apt-get install samba -y 2>&1)
    if echo "$output" | grep -q "is already the newest version"; then
        echo "Samba is already installed and up-to-date."
    elif [ $? -eq 0 ]; then
        echo "Samba installed/updated successfully."
    else
        echo "Error installing/updating Samba. Exiting."
        exit 1
    fi
}

##############################
# Backup/Restore Config      #
##############################
backup_config() {
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    echo "Backup created at $BACKUP_FILE"
}

restore_config() {
    if [ -f "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" "$CONFIG_FILE"
        echo "Configuration restored from backup."
    else
        echo "No backup file found."
    fi
}

##############################
# Global Settings            #
##############################
configure_global_settings() {
    echo "Configuring global Samba settings..."
    backup_config

    current_workgroup=$(grep -i 'workgroup' "$CONFIG_FILE" | head -n1 | awk '{print $3}')
    current_server_string=$(grep -i 'server string' "$CONFIG_FILE" | head -n1 | cut -d '=' -f2- | sed 's/^[ \t]*//')
    current_netbios=$(grep -i 'netbios name' "$CONFIG_FILE" | head -n1 | awk '{print $3}')
    current_security=$(grep -i '^ *security' "$CONFIG_FILE" | head -n1 | awk '{print $2}')

    echo "Current global settings (if set):"
    echo "  Workgroup     : ${current_workgroup:-Not set}"
    echo "  Server string : ${current_server_string:-Not set}"
    echo "  NetBIOS name  : ${current_netbios:-Not set}"
    echo "  Security mode : ${current_security:-Not set}"
    echo ""

    read -p "Enter Workgroup (default WORKGROUP): " workgroup
    workgroup=${workgroup:-WORKGROUP}
    read -p "Enter Server string (description, default 'Samba Server'): " server_string
    server_string=${server_string:-Samba Server}
    read -p "Enter NetBIOS name (default is hostname): " netbios_name
    netbios_name=${netbios_name:-$(hostname)}
    read -p "Enter Security mode (user/share) (default user): " security_mode
    security_mode=${security_mode:-user}

    awk -v wg="$workgroup" -v ss="$server_string" -v nb="$netbios_name" -v sec="$security_mode" '
        BEGIN { in_global=0 }
        /^ *\[global\]/ {
            print;
            print "   workgroup = " wg;
            print "   server string = " ss;
            print "   netbios name = " nb;
            print "   security = " sec;
            in_global=1;
            next;
        }
        in_global && /^\s*\[/ { in_global=0 }
        !in_global { print }
    ' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

    echo "Global settings updated."
}

##############################
# Share Management           #
##############################
add_share() {
    read -p "Enter share name (no spaces): " sharename
    read -p "Enter full directory path for the share: " dirpath
    read -p "Enter a comment/description for the share (default 'Samba Share'): " comment
    comment=${comment:-Samba Share}
    read -p "Enter comma-separated list of valid Samba users for this share (leave blank for open access): " valid_users

    if [ ! -d "$dirpath" ]; then
        mkdir -p "$dirpath"
        echo "Directory created."
    fi

    chmod 0770 "$dirpath"

    {
        echo ""
        echo "[$sharename]"
        echo "   path = $dirpath"
        echo "   browseable = yes"
        echo "   writable = yes"
        echo "   guest ok = no"
        echo "   create mask = 0660"
        echo "   directory mask = 0770"
        if [ -n "$valid_users" ]; then
            echo "   valid users = $valid_users"
        fi
        echo "   comment = $comment"
    } >> "$CONFIG_FILE"

    # If valid users are defined, create a dedicated group and fix rights accordingly.
    if [ -n "$valid_users" ]; then
        group_name="smb_${sharename}"
        if ! getent group "$group_name" > /dev/null; then
            groupadd "$group_name"
        fi
        IFS=',' read -ra USERS <<< "$valid_users"
        for user in "${USERS[@]}"; do
            user=$(echo "$user" | xargs)
            usermod -aG "$group_name" "$user"
        done
        chown root:"$group_name" "$dirpath"
        chmod 0770 "$dirpath"
    fi

    echo "Share '$sharename' added with default settings."
}

remove_share() {
    read -p "Enter the share name to remove: " sharename
    backup_config
    perl -0777 -pi -e "s/\[\Q$sharename\E\].*?(?=\n\[|$)//s" "$CONFIG_FILE"
    echo "Share '$sharename' removed (backup saved as $BACKUP_FILE)."
}

list_shares() {
    echo "Configured Samba shares:"
    grep "^\[" "$CONFIG_FILE" | grep -iv "global"
}

change_permissions() {
    read -p "Enter the full path of the directory: " dirpath
    if [ ! -d "$dirpath" ]; then
        echo "Directory does not exist."
        return
    fi
    read -p "Enter new permissions (e.g., 0770, default 0770): " perms
    perms=${perms:-0770}
    chmod "$perms" "$dirpath"
    echo "Permissions for $dirpath changed to $perms."
}

##############################
# Samba User Management      #
##############################
check_samba_users() {
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

add_samba_user() {
    read -p "Enter the username to add: " username
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
    echo -e "$password\n$password" | smbpasswd -a -s "$username"
    echo "Samba user '$username' added."
}

edit_samba_password() {
    read -p "Enter the Samba username to edit the password: " username
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

remove_samba_user() {
    read -p "Enter the username to remove from Samba: " username
    smbpasswd -x "$username"
    echo "Samba user '$username' removed."
}

list_samba_users() {
    echo "Configured Samba users:"
    pdbedit -L
}

##############################
# Configuration Testing      #
##############################
test_configuration() {
    echo "Testing Samba configuration with testparm..."
    testparm -s
    read -p "Press Enter to return to the menu..."
}

##############################
# View Logs and Connections  #
##############################
view_logs() {
    LOGFILE="/var/log/samba/log.smbd"
    if [ -f "$LOGFILE" ]; then
        echo "Showing last 20 lines of $LOGFILE:"
        tail -n 20 "$LOGFILE"
    else
        echo "Log file $LOGFILE not found."
    fi
    read -p "Press Enter to return to the menu..."
}

view_active_connections() {
    echo "Active Samba connections (smbstatus):"
    smbstatus
    read -p "Press Enter to return to the menu..."
}

##############################
# Show Access Table          #
##############################
show_access_table() {
    echo "Access Table (Share | Directory | Valid Users):"
    awk 'BEGIN {
           FS="\n"; RS="\\[";
           OFS="\t"; print "Share", "Directory", "Valid Users"
         }
         {
           if($1 ~ /global/i) next;
           share=substr($1,1,index($1,"]")-1);
           path=""; valid="";
           n = split($0, lines, "\n");
           for(i=2; i<=n; i++){
             if(lines[i] ~ /^[ \t]*path[ \t]*=/) {
                sub(/^[ \t]*path[ \t]*=[ \t]*/, "", lines[i]);
                path=lines[i];
             }
             if(lines[i] ~ /^[ \t]*valid users[ \t]*=/) {
                sub(/^[ \t]*valid users[ \t]*=[ \t]*/, "", lines[i]);
                valid=lines[i];
             }
           }
           print share, path, valid;
         }' "$CONFIG_FILE" | column -t -s $'\t'
    echo ""
    read -p "Press Enter to return to the menu..."
}

##############################
# Generate fstab Entry       #
##############################
generate_fstab_entry() {
    echo "Generate an fstab entry for mounting a Samba share."
    read -p "Enter the server address (IP or hostname): " server
    read -p "Enter the share name: " share
    read -p "Enter the local mount point (e.g., /mnt/samba_share): " mountpoint
    read -p "Enter mount options (default: credentials=/root/.smbcredentials,iocharset=utf8,sec=ntlm): " options
    options=${options:-credentials=/root/.smbcredentials,iocharset=utf8,sec=ntlm}
    
    entry="//$server/$share  $mountpoint  cifs  $options  0  0"
    echo ""
    echo "Generated fstab entry:"
    echo "$entry"
    echo ""
    echo "$entry" > fstab_entry.txt
    echo "The entry has been written to fstab_entry.txt in the current directory."
    read -p "Press Enter to return to the menu..."
}

##############################
# Fix All Access Rights      #
##############################
fix_all_access_rights() {
    echo "Fixing access rights for all shares..."
    shares=$(grep "^\[" "$CONFIG_FILE" | grep -iv "global" | sed 's/\[\(.*\)\]/\1/')
    for share in $shares; do
        share_path=$(awk -v share="[$share]" 'BEGIN {found=0} 
          {if ($0==share) {found=1} else if(found && $0 ~ /^\[/) {exit} else if(found && $0 ~ /^[ \t]*path[ \t]*=/) {sub(/^[ \t]*path[ \t]*=[ \t]*/, ""); print; exit}}' "$CONFIG_FILE")
        valid_users=$(awk -v share="[$share]" 'BEGIN {found=0} 
          {if ($0==share) {found=1} else if(found && $0 ~ /^\[/) {exit} else if(found && $0 ~ /^[ \t]*valid users[ \t]*=/) {sub(/^[ \t]*valid users[ \t]*=[ \t]*/, ""); print; exit}}' "$CONFIG_FILE")
        if [ -n "$share_path" ]; then
            if [ -n "$valid_users" ]; then
                group_name="smb_${share}"
                if ! getent group "$group_name" > /dev/null; then
                    groupadd "$group_name"
                fi
                IFS=',' read -ra USERS <<< "$valid_users"
                for user in "${USERS[@]}"; do
                    user=$(echo "$user" | xargs)
                    usermod -aG "$group_name" "$user"
                done
                chown root:"$group_name" "$share_path"
                chmod 0770 "$share_path"
                echo "Fixed access rights for share '$share'."
            else
                chmod 0770 "$share_path"
                echo "Fixed access rights for share '$share' (no valid users defined)."
            fi
        else
            echo "Could not determine path for share '$share'."
        fi
    done
    read -p "Press Enter to return to the menu..."
}

##############################
# Set/Update Share Access    #
##############################
set_share_access() {
    read -p "Enter the share name to update access: " sharename
    share_path=$(awk -v share="[$sharename]" 'BEGIN {found=0} 
      {if ($0==share) {found=1} else if(found && $0 ~ /^\[/) {exit} else if(found && $0 ~ /^[ \t]*path[ \t]*=/) {sub(/^[ \t]*path[ \t]*=[ \t]*/, ""); print; exit}}' "$CONFIG_FILE")
    if [ -z "$share_path" ]; then
       echo "Share '$sharename' not found in smb.conf."
       return
    fi
    read -p "Enter comma-separated list of valid Samba users for share '$sharename': " valid_users
    # Update or insert valid users line for the share in smb.conf
    perl -0777 -pi -e "s/(\[\Q$sharename\E\].*?valid users\s*=\s*).*(\n)/\1$valid_users\2/s" "$CONFIG_FILE"
    if ! grep -A 10 "^\[$sharename\]" "$CONFIG_FILE" | grep -q "valid users"; then
        perl -0777 -pi -e "s/(\[\Q$sharename\E\].*?\n)/\1   valid users = $valid_users\n/s" "$CONFIG_FILE"
    fi
    group_name="smb_${sharename}"
    if ! getent group "$group_name" > /dev/null; then
        groupadd "$group_name"
    fi
    IFS=',' read -ra USERS <<< "$valid_users"
    for user in "${USERS[@]}"; do
        user=$(echo "$user" | xargs)
        usermod -aG "$group_name" "$user"
    done
    chown root:"$group_name" "$share_path"
    chmod 0770 "$share_path"
    echo "Access rights for share '$sharename' updated."
    read -p "Press Enter to return to the menu..."
}

##############################
# Manual Display             #
##############################
print_manual() {
    cat <<'EOF'
Samba Administration Script Manual

This script provides an interactive menu for administering your Samba server.
Below are the available options and their explanations:

1. Configure Global Settings:
   - Modify Samba's global configuration (workgroup, server string, netbios name, security).
   - Defaults are used if no value is provided.

2. Add New Share:
   - Create a new share by specifying a share name, directory path, and an optional comment.
   - When valid users are provided, a dedicated group is created and access rights are fixed.
   - Default settings: browsable, writable, guest access disabled, create mask 0660, directory mask 0770.

3. Remove a Share:
   - Remove an existing share definition from the Samba configuration.
   - A backup of the configuration is created before removal.

4. List Shares:
   - Display all share definitions (excluding the [global] section) from the Samba configuration.

5. Change Share Folder Permissions:
   - Change the file system permissions for a specified share directory.
   - The default permission is 0770 if not specified.

6. Add Samba User:
   - Create a new Samba user.
   - Optionally create the corresponding Unix system user if it does not exist.
   - You will be prompted to enter and confirm a password.

7. Edit Samba User Password:
   - Change the password for an existing Samba user, with confirmation.

8. Remove Samba User:
   - Remove an existing Samba user from the Samba database.

9. List Samba Users:
   - Display all Samba users currently configured.

10. Backup smb.conf:
    - Create a backup copy of the current Samba configuration file.

11. Restore smb.conf from Backup:
    - Restore the Samba configuration from a previously created backup.

12. Restart Samba Services:
    - Restart the Samba services to apply configuration changes.

13. Manual:
    - Display this manual with detailed explanations for all options.

14. Test Samba Configuration:
    - Run 'testparm' to validate the current Samba configuration.

15. View Samba Logs:
    - Display the last 20 lines of the Samba log (e.g., log.smbd).

16. View Active Connections:
    - Show active Samba connections using 'smbstatus'.

17. Show Access Table:
    - Display a table of shares showing the share name, directory path, and valid users (if defined).

18. Generate fstab Entry:
    - Generate an fstab entry to mount a Samba share on a client.
    - The entry is saved to 'fstab_entry.txt' in the current directory.

19. Fix All Access Rights:
    - For each share in smb.conf, update file system permissions.
    - If a share has a 'valid users' list, a dedicated group is created and users are added.
    - The share directory ownership is set to root:group and permissions fixed to 0770.

20. Set Share Access:
    - Update the valid users for a specific share.
    - This function modifies the smb.conf for that share and fixes the folder's access rights accordingly.

21. Exit:
    - Exit the administration script.

EOF
    read -p "Press Enter to return to the menu..."
}

##############################
# Restart Samba Services     #
##############################
restart_samba() {
    systemctl restart smbd
    systemctl restart nmbd
    echo "Samba services have been restarted."
    read -p "Press Enter to return to the menu..."
}

##############################
# Main Menu                  #
##############################
main_menu() {
    while true; do
        clear
        echo "-----------------------------------------"
        echo "       Samba Administration Menu         "
        echo "-----------------------------------------"
        echo " 1. Configure Global Settings"
        echo " 2. Add New Share"
        echo " 3. Remove a Share"
        echo " 4. List Shares"
        echo " 5. Change Share Folder Permissions"
        echo " 6. Add Samba User"
        echo " 7. Edit Samba User Password"
        echo " 8. Remove Samba User"
        echo " 9. List Samba Users"
        echo "10. Backup smb.conf"
        echo "11. Restore smb.conf from Backup"
        echo "12. Restart Samba Services"
        echo "13. Manual"
        echo "14. Test Samba Configuration"
        echo "15. View Samba Logs"
        echo "16. View Active Connections"
        echo "17. Show Access Table"
        echo "18. Generate fstab Entry"
        echo "19. Fix All Access Rights"
        echo "20. Set Share Access"
        echo "21. Exit"
        echo "-----------------------------------------"
        read -p "Select an option [1-21]: " option

        case $option in
            1) configure_global_settings ;;
            2) add_share ;;
            3) remove_share ;;
            4) list_shares ;;
            5) change_permissions ;;
            6) add_samba_user ;;
            7) edit_samba_password ;;
            8) remove_samba_user ;;
            9) list_samba_users ;;
            10) backup_config ;;
            11) restore_config ;;
            12) restart_samba ;;
            13) print_manual ;;
            14) test_configuration ;;
            15) view_logs ;;
            16) view_active_connections ;;
            17) show_access_table ;;
            18) generate_fstab_entry ;;
            19) fix_all_access_rights ;;
            20) set_share_access ;;
            21) echo "Exiting."; exit 0 ;;
            *) echo "Invalid option. Please try again." ; sleep 2 ;;
        esac
        echo ""
        read -p "Press Enter to continue..."
    done
}

##############################
# Script Execution           #
##############################
install_samba
check_samba_users
main_menu
