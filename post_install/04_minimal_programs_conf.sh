#!/bin/bash
# Additinal progams for minimal installation
sudo apt update

# Installing command-line fuzzy finder
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# flameshoot - screen copy
# synaptic - gui for managing packages
sudo apt install synaptic flameshot tree pv untar nmap -y

# pfetch - minimal replacement fo neofetch
git clone https://github.com/dylanaraps/pfetch.git ~/Git/pfetch
echo "alias pfetch='~/Git/pfetch/pfetch'" >> ~/.zshrc

doas -- apt install ranger -y

# Bpytop
pip3 install bpytop

# Microsoft Edge
## Setup
sudo apt install curl
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-dev.list'
sudo rm microsoft.gpg
## Install
sudo apt update
sudo apt install microsoft-edge-dev
