# Additinal progams for minimal installation

# Installing command-line fuzzy finder
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# flameshoot
sudo apt install synaptic flameshot tree pv untar nmap -y

# pfetch - minimal replacement fo neofetch
git clone https://github.com/dylanaraps/pfetch.git ~/Git/pfetch
echo "alias pfetch='~/Git/pfetch/pfetch'" >> ~/.zshrc

doas -- apt install ranger -y
