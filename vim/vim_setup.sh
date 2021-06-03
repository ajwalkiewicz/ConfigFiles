#!bin/bash
# Simple setup for vim

# Download repository
git clone https://github.com/ajwalkiewicz/MyConfigFiles.git ~/Git/

# Install Vundle - plugin manager
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

cp ~/Git/MyConfigFiles/vim/indent ~/.vim/
cp ~/Git/MyConfigFiles/vim/colors ~/.vim/
