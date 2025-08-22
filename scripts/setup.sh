#!/usr/bin/bash

# Upgrade system
sudo apt update && sudo apt upgrade --yes

# Commona packages
sudo apt install \
	vim \
	zsh \
	git \
	exa \
	mpv \
	xsel \
	tree \
	nemo \
	tilix \
	screen \
	ffmpeg \
	neofetch \
	gnome-tweaks \
	openssh-server \
	openssh-client \
	--yes

# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew install \
	python@3.13 \
	btop \
	bat \
	jandedobbeleer/oh-my-posh/oh-my-posh

# Python
sudo apt install \
	python3-venv \
	python3-pip \
	--yes

brew install uv
# Alternatively directly from Astral:
# curl -LsSf https://astral.sh/uv/install.sh | sh

# Go
brew install go

# Microsoft
curl -sSL -O https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install \
	powershell \
	code \
	--yes
pwsh -c "Install-Module -Name PSFzf -Scope CurrentUser"
pwsh -c "Update-Help"

# Oh My Posh
brew install jandedobbeleer/oh-my-posh/oh-my-posh

# Github
(type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
	&& sudo mkdir -p -m 755 /etc/apt/keyrings \
        && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y

# Set tilix to default shell
sudo update-alternatives --config x-terminal-emulator

# Update shell
chsh --shell /usr/bin/zsh

## Install Oh-My-Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

## Install plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

## Add plugins to .zshrc
cat << EOF >> $HOME/.zshrc

# Plugins
plugins=(
git
zsh-syntax-highlighting
zsh-autosuggestions
)

EOF

## Change colors
cat << EOF >> $HOME/.zshrc

ZSH_HIGHLIGHT_STYLES[suffix-alias]=fg="#BBBF40",bold
ZSH_HIGHLIGHT_STYLES[precommand]=fg="#BBBF40",bold
ZSH_HIGHLIGHT_STYLES[arg0]=fg="#BBBF40",bold
export LS_COLORS=$LS_COLORS:'di=1;37;44:'

EOF

# Install FZF
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# Install ZEN browser
flatpak install flathub app.zen_browser.zen

# Install nordvpn
sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
# nordvpn login
# nordvpn connect

# Remove Firefox
sudo apt remove firefox

# Install Singal
wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
cat signal-desktop-keyring.gpg | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' |\
  sudo tee /etc/apt/sources.list.d/signal-xenial.list
sudo apt update && sudo apt install signal-desktop

# Setup Nemo
xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
gsettings set org.cinnamon.desktop.default-applications.terminal exec tilix
mkdir -p ~/.gnome2/accels
touch ~/.gnome2/accels/nemo
nemo &
echo '(gtk_accel_path "<Actions>/DirViewActions/OpenInTerminal" "F4")' >> ~/.gnome2/accels/nemo

# Clean Up
rm -r \
	signal-desktop-keyring.gpg \
	packages-microsoft-prod.deb

# Other
# Gedit

[ command -v gedit ] && sudo apt install gedit-plugins

# Checklist
# Copy .zprofile
# Set in gnome tewaks 
# - focus on hover
# - CapsLock as Ctrl
# Get setup for VSCode
# Log in and install extesnions to ZEN browser
# Set ZEN browser to default
# Set mpv to default player

