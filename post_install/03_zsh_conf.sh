#!/bin/bash
# ZSH configuration
# https://www.howtoforge.com/tutorial/how-to-setup-zsh-and-oh-my-zsh-on-linux/

doas -- apt install zsh

# Setting ZSH as a default shell for root
doas -- chsh -s /usr/bin/zsh $USER

echo $SHELL

# Installing Oh MY ZSH
sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && echo "Success"

# Fonts
if [ ! -d "/usr/local/share/fonts/" ]; then
   mkdir -p /usr/local/share/fonts 
fi

doas -- wget -O '/usr/local/share/fonts/MesloLGS NF Regular.ttf' 'https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf' 
doas -- wget -O '/usr/local/share/fonts/MesloLGS NF Bold.ttf''https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf'

# Installing zsh-syntax-highlightning
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Installing zsh autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Installing powerline 10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Coping dot files
cp ~/Git/config-files/dot_files/zshrc ~/.zshrc

# Run powerline 10k configuration
source ~/.zshrc
p10k configure
