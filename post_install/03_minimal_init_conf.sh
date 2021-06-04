# Minimal init config

# Home directory
mkdir Pictures Video Documents bin
mkdir Pictures/wallpapers

# Setting i3 configuration files
ln -s ~/Git/config-files/dot_files/.Xresources
ln -s ~/Git/config-files/dot_files/.initrc
ln -s ~/Git/config-files/dot_files/.xserverrc

# Rofi
mkdir -p ~/.config/rofi
rofi -dump-config > ~/.config/rofi/config.rasi

cp -r ~/Git/config-files/rofi/* ~/.config/rofi/
