#!/bin/bash
# Minimall installation script for debian with i3

VB=false
INTEL=false
AMD=fasle

HELP=false
NRUSER=$(echo /home/* | cut -d" " -f1 | cut -d"/" -f3) # non-root user

# basic options
while getopts hviad flag; do
    case "${flag}" in
        v) VB=true;;
        i) INTEL=true;;
        a) AMD=true;;
		h) HELP=true;;
        d) set -x;;
		*) HELP=true;;
    esac
done

# Additional repositories

mv /etc/apt/sources.list /etc/apt/sources.list.bak

tee /etc/apt/sources.list<<EOF
deb http://deb.debian.org/debian buster main contrib non-free
deb-src http://deb.debian.org/debian buster main contrib non-free

deb http://deb.debian.org/debian-security/ buster/updates main contrib non-free
deb-src http://deb.debian.org/debian-security/ buster/updates main contrib non-free

deb http://deb.debian.org/debian buster-updates main contrib non-free
deb-src http://deb.debian.org/debian buster-updates main contrib non-free
EOF

apt update && apt upgrade -y

$INTEL && apt install intel-microcode # For Intel CPU
$AMD && apt install amd64-microcode # For AMD CPU

apt install gnupg -y

# For virtualbox
if $VB; then
    wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | apt-key add -
    wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | apt-key add -
    tee /etc/apt/sources.list.d/virtualbox.list<<EOF
deb http://download.virtualbox.org/virtualbox/debian bionic contrib
EOF
    apt-get install virtualbox-guest-additions-iso
fi

# i3wm and enviroment
apt install i3 xorg suckless-tools nitrogen compton tilix rxvt-unicode imagemagick scrot xsel rofi xsettingsd lxappearance -y
# apt install fonts-noto fonts-mplus -y # fonts
# apt install lightdm -y # lightdm
apt install conky -y # System monitor

# i3 - main window manager. 
# If doesn't install all components atomatically, install:
# i3-wm dunst i3lock i3status suckless-tools

# lightdm - display manager
# nitrogen - wallpaper handler
# compton - is a compositor to provide some desktop effects like shadow, transparency, fade, and transiton.
# Hsetroot is a wallpaper handler. i3 has no wallpaper handler by default.
# URxvt - lightweight terminal emulator, part of i3-sensible-terminal.
# tilix - my favorite terminal
# Xsel - program to access X clipboard. We need it to make copy-paste in URxvt available. Hit Alt+C to copy, and Alt+V to paste.
# Rofi is a program launcher, similar with dmenu but with more options.
# Noto Sans and M+ are my favourite fonts used in my configuration.
# Xsettingsd is a simple settings daemon to load fontconfig and some other options. Without this, fonts would look rasterized in some applications.
# LXAppearance is used for changing GTK theme icons, fonts, and some other preferences.
# Scrot is for taking screenshoot. I use it in my configuration for Print Screen button. I set my Print Screen button to take screenshoot using scrot, then automatically open it using Viewnior image viewer.

# Dependencies (doas)
apt install build-essential make bison flex libpam0g-dev -y   

# Standard application
apt install python3-pip python3-venv vim -y

# Installing iwd - replacement for network manager
apt install iwd -y
systemctl enable iwd.service
systemctl start iwd.service

# Battery

# Installing doas - replacement for sudo
cd
mkdir ~/Git
git clone https://github.com/slicer69/doas.git ~/Git/doas
cd ~/Git/doas
make install
mkdir /usr/local/etc/
echo "permit nopass $NRUSER as root" > /usr/local/etc/doas.conf
cd ~/

# Setting alias for sudo 
echo "alias sudo='doas --'" >> /home/$NRUSER/.bashrc

# My config files gitgub in home directory
mkdir /home/$NRUSER/Git
git clone https://github.com/ajwalkiewicz/config-files.git /home/$NRUSER/Git/config-files
chown -R $NRUSER:$NRUSER /home/$NRUSER/Git
