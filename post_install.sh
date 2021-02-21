#!/bin/bash

GREEN="\033[1;32m"
BLUE="\033[1;34m"
BOLD="\033[1m"
RESET="\033[0m"

function print_message {
	echo -e "############################################\n# $BOLD$GREEN $1: $RESET\n############################################"
}

function install_message {
	echo -e "############################################\n# $BOLD$BLUE Installing: $1: $RESET\n############################################"
}

echo "############################################"
echo "#  Welcome in first installation setup     #"
echo "#  script                                  #"
echo "#  by Adam Walkiewicz                      #"
echo "############################################"

print_message "Updating OS"

sudo apt update -y
sudo apt upgrade -y
sudo apt dist-upgrade -y
sudo apt autoremove -y

print_message "Done"

echo "############################################"
echo "# Instaling apps from standard repository  #"
echo "############################################"

# Dependencies for other apps (Doas)
sudo apt install build-essential make bison flex libpam0g-dev -y

# Basic mods and app standards
sudo apt install snapd gnome-tweak-tool flatpak -y

# Communication
sudo apt install discord chromium-browser -y
# Tools
sudo apt install tilix htop fdupes nemo gnome-tweaks \
neofetch nmap meld synaptic tree unrar flameshot \
minicom git -y
# Programming 
sudo apt install python3-pip python3-venv -y
# Work
sudo apt install peek nomachine slack-desktop sshpass zoom -y
 
print_message "Done"


echo "############################################"
echo "# Other apps                               #"
echo "############################################"

install_message "Sublime Text 3"

# Sublime text
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
sudo apt-get install apt-transport-https
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
sudo apt-get update
sudo apt-get install sublime-text

install_message "Dropbox"
cd ~ && wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -

install_message "Arduino-cli"

curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh

print_message "Done"

echo "############################################"
echo "# Flatpak apps                          #"
echo "############################################"

install_message "Skype"
flatpak install -y skype

install_message "Zoom"
flatpak install -y zoom

print_message "Done"

echo "############################################"
echo "# App images apps                          #"
echo "############################################"

install_message "Joplin"
wget -O - https://raw.githubusercontent.com/laurent22/joplin/dev/Joplin_install_and_update.sh | bash
print_message "Done"

echo "############################################"
echo "# Setting up Git                           #"
echo "############################################"

git config --global user.name "Adam Walkiewicz"
git config --global user.email "aj.walkiewicz@gmail.com"

print_message "Done"

echo "############################################"
echo "# Cloning git repositories                 #"
echo "############################################"

# Installing command-line fuzzy finder
print_message "Cloning: fuzzy finder"
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# Installing Oh My Bash
print_message "Cloning: Oh My Bash"
sh -c "$(wget https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh -O -)"
# Downloading my repo with scripts

# doas
print_message "Cloning: doas"
git clone https://github.com/slicer69/doas.git
cd doas
sudo make install
sudo /usr/local/etc/
echo "permit nopass $USER as root" >> /usr/local/etc/doas.conf

# My reposotory
print_message "Cloning: My repository"
# git clone 
# mv etc.

print_message "Done"

echo "############################################"
echo "# Installing snap programs                 #"
echo "############################################"

print_message "Done"

echo "############################################"
echo "# Configuring system settings              #"
echo "############################################"

# Setting nemo as default file manager
xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search

# Creating my bash settings

# Setting tilix as default terminal
# sudo update-alternatives --config x-terminal-emulator
# chose number

# Setting flameshot
# Set night mode
# Set gnome tweaks
# set configs from my github


echo "############################################"
echo "# Done.                                    #"
echo "# Thank you for using my setup script.     #"
echo "# Have a nice day!                         #"
echo "############################################"