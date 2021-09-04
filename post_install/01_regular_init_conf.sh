#!/bin/bash
source utils.sh

mkdir -p ~/bin

git config --global user.name "Adam Walkiewicz"
git config --global user.email "aj.walkiewicz@gmail.com"

# doas
# Dependencies for other apps (Doas)
sudo apt install build-essential make bison flex libpam0g-dev -y

print_message "Cloning: doas"
mkdir ~/Git
git clone https://github.com/slicer69/doas.git ~/Git/doas
cd ~/Git/doas
sudo make install
sudo mkdir /usr/local/etc/
echo "permit nopass $USER as root" > /usr/local/etc/doas.conf
cd ~/

# Setting terminal in nemor to tilix
xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
gsettings set org.cinnamon.desktop.default-applications.terminal exec tilix
mkdir -p ~/.gnome2/accels
touch ~/.gnome2/accels/nemo
nemo &
echo '(gtk_accel_path "<Actions>/DirViewActions/OpenInTerminal" "F4")' >> ~/.gnome2/accels/nemo
