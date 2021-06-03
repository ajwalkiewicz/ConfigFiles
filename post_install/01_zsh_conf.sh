# ZSH configuration
# https://www.howtoforge.com/tutorial/how-to-setup-zsh-and-oh-my-zsh-on-linux/

sudo apt install zsh

# Setting ZSH as a default shell for root
chsh -s /usr/bin/zsh root

echo $SHELL

# Installing Oh MY ZSH
sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Fonts
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf

# Installing powerline 10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Coping dot files
cp ~/Git/config-files/dot_files/zshrc ~/.zshrc

# Run powerline 10k configuration
p10k configure
