# Minimal init config

# Home directory
mkdir -p ~/Pictures/wallpapers
mkdir ~/Video 
mkdir ~/Documents 
mkdir ~/bin

# Setting i3 configuration files
cp ~/Git/config-files/dot_files/Xresources ~/.Xresources
cp ~/Git/config-files/dot_files/xinitrc ~/.xinitrc
cp ~/Git/config-files/dot_files/xserverrc ~/.xserverrc
cp ~/Git/config-files/dot_files/bash_profile ~/.bash_profile

# Rofi
# mkdir -p ~/.config/rofi
# rofi -dump-config > ~/.config/rofi/config.rasi

# cp -r ~/Git/config-files/rofi/* ~/.config/rofi/
