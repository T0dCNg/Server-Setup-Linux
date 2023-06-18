#!/bin/bash

# Check if the script is being run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." 
   exit 1
fi

# Update the package lists
apt update

# Upgrade installed packages
apt upgrade -y

# Clean up unused packages and cached files
apt autoremove -y
apt autoclean

# Print a message indicating completion
echo "Update and upgrade completed."

