#!/bin/bash
# Script for setting up VIM

# coping files from github
cp -r ~/Git/config-files/vim ~/.vim
cp ~/Git/config-files/dot_files/vimrc ~/.vimrc

# Install Vundle - plugin manager
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

# To do:
# Tag bar config - require 
doas -- apt update 
doas -- apt install \
gcc make \
pkg-config autoconf automake \
python3-docutils \
libseccomp-dev \
libjansson-dev \
libyaml-dev \
libxml2-dev
git clone https://github.com/universal-ctags/ctags.git ~/Git/ctags
cd ~/Git/ctags
./autogen.sh
./configure # defaults to /usr/local
make
doas -- make install # may require extra privileges depending on where to install
cd ~/
