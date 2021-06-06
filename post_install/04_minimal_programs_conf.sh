#!/bin/bash
# Additinal progams for minimal installation
doas -- apt update

# Installing command-line fuzzy finder
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# flameshoot - screen copy
# synaptic - gui for managing packages
doas -- apt install synaptic flameshot tree pv untar nmap -y

# pfetch - minimal replacement fo neofetch
git clone https://github.com/dylanaraps/pfetch.git ~/Git/pfetch
echo "alias pfetch='~/Git/pfetch/pfetch'" >> ~/.zshrc

doas -- apt install ranger -y

# Bpytop
pip3 install bpytop

# Microsoft Edge
## Setup
doas --  apt install curl
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
doas -- install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
doas -- sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-dev.list'
doas -- rm microsoft.gpg
## Install
doas -- apt update
doas -- apt install microsoft-edge-dev
