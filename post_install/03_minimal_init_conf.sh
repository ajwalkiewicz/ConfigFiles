#!/bin/bash
# Minimal init config

# Home directory
mkdir -p ~/Pictures/wallpapers
mkdir ~/Video 
mkdir ~/Documents 
mkdir ~/bin

# Initialize X server and i3
cp ~/Git/config-files/dot_files/Xresources ~/.Xresources
cp ~/Git/config-files/dot_files/xinitrc ~/.xinitrc
cp ~/Git/config-files/dot_files/xserverrc ~/.xserverrc
cp ~/Git/config-files/dot_files/zprofile ~/.zprofile

# i3 config files
cp -rf ~/Git/config-files/i3 ~/.config/

# Rofi
# mkdir -p ~/.config/rofi
# rofi -dump-config > ~/.config/rofi/config.rasi

# cp -r ~/Git/config-files/rofi/* ~/.config/rofi/
