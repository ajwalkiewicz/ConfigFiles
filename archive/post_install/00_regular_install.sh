#!/bin/bash
source utils.sh

print_message "Updating OS"

sudo apt update -y
sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt autoremove -y

print_message "Done"

# Basic mods and app standards
sudo apt install snapd gnome-tweak-tool flatpak -y

sudo apt install discord -y
sudo apt install tilix htop fdupes nemo gnome-tweaks \
neofetch nmap \
minicom git -y
# Programming 
sudo apt install python3-pip python3-venv meld -y
# Work
# sudo apt install peek slack-desktop sshpass \
# tftpd-hpa tftp-hpa nfs-kernel-server nfs-common -y
 
print_message "Done"

install_message "Sublime Text 3"

# Sublime text
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
sudo apt-get install apt-transport-https
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
sudo apt-get update
sudo apt-get install sublime-text

# install_message "Dropbox"
# cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -

install_message "Arduino-cli"

curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh

print_message "Done"

install_message "Skype"
flatpak install -y skype

install_message "Zoom"
flatpak install -y zoom

print_message "Done"

install_message "Joplin"
wget -O - https://raw.githubusercontent.com/laurent22/joplin/dev/Joplin_install_and_update.sh | bash
print_message "Done"
