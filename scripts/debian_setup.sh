#!/usr/bin/bash
# ==============================================================================
# Debian 13 (Trixie) Minimal → i3 Desktop Setup
# Target: MSI Modern 14 B11MO (Intel Tiger Lake)
#
# This script transforms a Debian server/minimal install into a fully
# functional i3 tiling window manager desktop. Run once on a fresh system.
#
# Usage:
#   chmod +x debian_setup.sh
#   ./debian_setup.sh              # Full setup on real hardware
#   ./debian_setup.sh --minimal    # Core desktop only (no apps/Homebrew)
#   ./debian_setup.sh --vm          # VM mode (skips hardware firmware/bluetooth/etc.)
#   ./debian_setup.sh --vm --minimal # VM + minimal
#   ./debian_setup.sh --from 15     # Resume from phase 15
#
# After running, deploy configs with: ./deploy_configs.sh
# Then reboot — login at TTY and X will auto-start via .zprofile.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$REPO_DIR/debian_setup.log"
MINIMAL=false
VM_MODE=false
START_PHASE=1

while [[ $# -gt 0 ]]; do
	case "$1" in
		--minimal) MINIMAL=true ;;
		--vm) VM_MODE=true ;;
		--from) START_PHASE="${2:?'--from requires a phase number (1-22)'}" ; shift ;;
	esac
	shift
done

if ! [[ "$START_PHASE" =~ ^[0-9]+$ ]] || (( START_PHASE < 1 || START_PHASE > 22 )); then
	echo "ERROR: --from must be a number between 1 and 22" >&2
	exit 1
fi

# Logging
exec > >(tee -a "$LOG_FILE") 2>&1
echo "=== Debian i3 Setup started at $(date) ==="

if (( START_PHASE > 1 )); then
	echo ">>> Resuming from Phase $START_PHASE — skipping phases 1 through $((START_PHASE - 1))"
fi

# ------------------------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------------------------

section() {
	echo ""
	echo "======================================================================"
	echo "  $1"
	echo "======================================================================"
	echo ""
}

confirm() {
	read -rp "$1 [Y/n] " response
	case "$response" in
		[nN]) return 1 ;;
		*) return 0 ;;
	esac
}

run_phase() {
	(( $1 >= START_PHASE ))
}

# ==============================================================================
# Phase 1: Non-free firmware repos
# ==============================================================================

if run_phase 1; then
section "Phase 1: Enabling non-free firmware repos"

# Ensure non-free and non-free-firmware components are available
if ! grep -q "non-free-firmware" /etc/apt/sources.list 2>/dev/null; then
	echo "Adding non-free-firmware component to sources.list..."
	sudo sed -i 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list
fi

sudo apt update
sudo apt upgrade --yes
fi

# ==============================================================================
# Phase 2: Core X11 + i3
# ==============================================================================

if run_phase 2; then
section "Phase 2: Installing X11 + i3 core"

sudo apt install --yes \
	xorg \
	xinit \
	x11-xserver-utils \
	i3 \
	i3status \
	i3lock \
	suckless-tools
fi

# ==============================================================================
# Phase 3: Intel hardware firmware (MSI Modern 14) — skipped in VM mode
# ==============================================================================

if run_phase 3; then
if [[ "$VM_MODE" == false ]]; then
	section "Phase 3: Intel firmware"

	sudo apt install --yes \
		intel-microcode \
		firmware-misc-nonfree \
		firmware-iwlwifi
else
	section "Phase 3: Intel firmware (SKIPPED — VM mode)"
fi
fi

# ==============================================================================
# Phase 4: Touchpad (libinput) — skipped in VM mode
# ==============================================================================

if run_phase 4; then
if [[ "$VM_MODE" == false ]]; then
	section "Phase 4: Touchpad / input drivers"

	sudo apt install --yes \
		xserver-xorg-input-libinput

	echo "NOTE: Touchpad config will be deployed by deploy_configs.sh"
else
	section "Phase 4: Touchpad (SKIPPED — VM mode)"
fi
fi

# ==============================================================================
# Phase 5: Audio — PipeWire + WirePlumber
# ==============================================================================

if run_phase 5; then
section "Phase 5: Audio (PipeWire)"

sudo apt install --yes \
	pipewire \
	pipewire-pulse \
	pipewire-alsa \
	wireplumber \
	pavucontrol \
	playerctl

# Enable PipeWire for the user
systemctl --user --now enable pipewire pipewire-pulse wireplumber 2>&1 || \
	echo "WARN: Could not enable PipeWire user services (will work after first X session)"
fi

# ==============================================================================
# Phase 6: Bluetooth — skipped in VM mode
# ==============================================================================

if run_phase 6; then
if [[ "$VM_MODE" == false ]]; then
	section "Phase 6: Bluetooth"

	sudo apt install --yes \
		bluez \
		blueman

	sudo systemctl enable bluetooth
else
	section "Phase 6: Bluetooth (SKIPPED — VM mode)"
fi
fi

# ==============================================================================
# Phase 7: Network — NetworkManager
# ==============================================================================

if run_phase 7; then
section "Phase 7: Network (NetworkManager)"

sudo apt install --yes \
	network-manager \
	network-manager-gnome

sudo systemctl enable NetworkManager
fi

# ==============================================================================
# Phase 8: Desktop utilities
# ==============================================================================

if run_phase 8; then
section "Phase 8: Desktop utilities"

DESKTOP_PKGS=(
	picom
	rofi
	dunst
	feh
	scrot
	imagemagick
	xsel
	xclip
	xss-lock
	xdg-utils
	xsettingsd
	lxappearance
	arandr
	flameshot
	libnotify-bin
)

# brightnessctl is only useful on real hardware
if [[ "$VM_MODE" == false ]]; then
	DESKTOP_PKGS+=(brightnessctl)
fi

sudo apt install --yes "${DESKTOP_PKGS[@]}"
fi

# ==============================================================================
# Phase 9: Terminal, shell, file manager, and common tools
# ==============================================================================

if run_phase 9; then
section "Phase 9: Core applications"

sudo apt install --yes \
	vim \
	zsh \
	git \
	mpv \
	feh \
	tree \
	nemo \
	tilix \
	screen \
	tty-clock \
	ffmpeg \
	curl \
	wget \
	gnupg \
	openssh-server \
	openssh-client \
	python3-venv \
	python3-pip \
	flatpak

# Set tilix as default terminal
# Debian registers tilix.wrapper, not tilix, in the alternatives system
TILIX_BIN="/usr/bin/tilix.wrapper"
[ -x "$TILIX_BIN" ] || TILIX_BIN="/usr/bin/tilix"
if ! update-alternatives --query x-terminal-emulator 2>/dev/null | grep -q "$TILIX_BIN"; then
	sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$TILIX_BIN" 50
fi
sudo update-alternatives --set x-terminal-emulator "$TILIX_BIN"

# Set zsh as default shell (sudo avoids interactive password prompt)
sudo chsh -s /usr/bin/zsh "$USER"

# Set VIM as default editor
sudo update-alternatives --install /usr/bin/editor editor /usr/bin/vim 100
sudo update-alternatives --set editor /usr/bin/vim

# Install Vundle (VIM plugin manager)
if [ ! -d "$HOME/.vim/bundle/Vundle.vim" ]; then
	git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi


fi

# ==============================================================================
# Phase 10: Nerd Fonts (MesloLGS NF)
# ==============================================================================

if run_phase 10; then
section "Phase 10: Nerd Fonts"

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

if ! fc-list | grep -qi "MesloLGS"; then
	echo "Installing MesloLGS NF..."
	FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.tar.xz"
	tmp_dir=$(mktemp -d)
	wget -qO "$tmp_dir/Meslo.tar.xz" "$FONT_URL"
	tar -xf "$tmp_dir/Meslo.tar.xz" -C "$FONT_DIR"
	rm -rf "$tmp_dir"
	fc-cache -fv
	echo "MesloLGS NF installed."
else
	echo "MesloLGS NF already installed, skipping."
fi
fi

# ==============================================================================
# Phase 11: i3lock-color (build from source)
# ==============================================================================

if run_phase 11; then
section "Phase 11: i3lock-color"

if command -v i3lock-color &>/dev/null || i3lock --version 2>&1 | grep -qi color; then
	echo "i3lock-color already installed, skipping."
else

sudo apt install --yes \
	autoconf \
	gcc \
	make \
	pkg-config \
	libpam0g-dev \
	libcairo2-dev \
	libfontconfig1-dev \
	libxcb-composite0-dev \
	libev-dev \
	libx11-xcb-dev \
	libxcb-xkb-dev \
	libxcb-xinerama0-dev \
	libxcb-randr0-dev \
	libxcb-image0-dev \
	libxcb-util0-dev \
	libxcb-xrm-dev \
	libxkbcommon-dev \
	libxkbcommon-x11-dev \
	libjpeg-dev

BUILD_DIR=$(mktemp -d)
git clone https://github.com/Raymo111/i3lock-color.git "$BUILD_DIR/i3lock-color"
cd "$BUILD_DIR/i3lock-color"
./install-i3lock-color.sh
cd "$REPO_DIR"
rm -rf "$BUILD_DIR"

echo "i3lock-color installed."

fi # end i3lock-color guard
fi

# ==============================================================================
# Phase 12: Pop GTK Theme + Icons
# ==============================================================================

if run_phase 12; then
section "Phase 12: Pop GTK Theme"

sudo apt install --yes \
	gnome-themes-extra \
	adwaita-icon-theme

# Install Pop GTK theme from System76 (requires building from source)
if [ ! -d /usr/share/themes/Pop ] && [ ! -d "$HOME/.themes/Pop" ]; then
	echo "Installing Pop GTK theme..."
	mkdir -p "$HOME/.themes" "$HOME/.icons"
	tmp_dir=$(mktemp -d)

	# Build dependencies for Pop GTK theme
	sudo apt install --yes meson sassc libglib2.0-dev

	# Pop GTK Theme — must be built with meson
	GIT_TERMINAL_PROMPT=0 git clone --depth 1 https://github.com/pop-os/gtk-theme.git "$tmp_dir/pop-theme" 2>/dev/null || \
		echo "WARN: Pop theme clone failed. Install manually via lxappearance."

	if [ -d "$tmp_dir/pop-theme" ]; then
		cd "$tmp_dir/pop-theme"
		meson setup build -Dprefix="$HOME/.local"
		ninja -C build install
		cd "$REPO_DIR"
		echo "Pop GTK theme built and installed to ~/.local/share/themes/"
	fi

	# Pop Icon Theme (pre-built, just copy)
	GIT_TERMINAL_PROMPT=0 git clone --depth 1 https://github.com/pop-os/icon-theme.git "$tmp_dir/pop-icons" 2>/dev/null || \
		echo "WARN: Pop icon theme clone failed. Install manually."

	if [ -d "$tmp_dir/pop-icons/Pop" ]; then
		cp -r "$tmp_dir/pop-icons/Pop" "$HOME/.icons/"
	fi

	rm -rf "$tmp_dir"
	echo "Pop theme installed. Configure via lxappearance."
else
	echo "Pop theme already present, skipping."
fi
fi

# ==============================================================================
# Phase 13: Logind — lid close / suspend — skipped in VM mode
# ==============================================================================

if run_phase 13; then
if [[ "$VM_MODE" == false ]]; then
	section "Phase 13: Logind configuration"

	LOGIND_CONF="/etc/systemd/logind.conf"
	if ! grep -q "^HandleLidSwitch=suspend" "$LOGIND_CONF" 2>/dev/null; then
		echo "Configuring lid close → suspend..."
		sudo sed -i 's/^#HandleLidSwitch=.*/HandleLidSwitch=suspend/' "$LOGIND_CONF"
		sudo sed -i 's/^#HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=suspend/' "$LOGIND_CONF"
		sudo sed -i 's/^#IdleAction=.*/IdleAction=suspend/' "$LOGIND_CONF"
		sudo sed -i 's/^#IdleActionSec=.*/IdleActionSec=30min/' "$LOGIND_CONF"
		sudo systemctl restart systemd-logind 2>/dev/null || true
	fi
else
	section "Phase 13: Logind (SKIPPED — VM mode)"
fi
fi

# ==============================================================================
# Phase 14: Flatpak setup
# ==============================================================================

if run_phase 14; then
section "Phase 14: Flatpak"

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

if [[ "$MINIMAL" == false ]]; then

# ==============================================================================
# Phase 15: Homebrew + CLI tools
# ==============================================================================

if run_phase 15; then
section "Phase 15: Homebrew + CLI tools"

if ! command -v brew &>/dev/null; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

brew install \
	python@3.14 \
	btop \
	bat \
	git-delta \
	jandedobbeleer/oh-my-posh/oh-my-posh \
	go \
	uv
fi

# ==============================================================================
# Phase 16: Microsoft products
# ==============================================================================

if run_phase 16; then
section "Phase 16: Microsoft (VSCode + PowerShell)"

# --- VS Code ---
if ! command -v code &>/dev/null; then
	wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | \
		sudo tee /etc/apt/keyrings/packages.microsoft.gpg > /dev/null
	echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
		sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
	sudo apt update
	sudo apt install --yes code
fi

# --- PowerShell (not in Debian 13 prod repo — install .deb from GitHub) ---
if ! command -v pwsh &>/dev/null; then
	PS_VERSION=$(curl -fsSL https://api.github.com/repos/PowerShell/PowerShell/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
	PS_DEB="powershell_${PS_VERSION#v}-1.deb_amd64.deb"
	wget -qO "/tmp/$PS_DEB" "https://github.com/PowerShell/PowerShell/releases/download/${PS_VERSION}/${PS_DEB}"
	sudo dpkg -i "/tmp/$PS_DEB" || sudo apt install --fix-broken --yes
	rm -f "/tmp/$PS_DEB"
	pwsh -c "Install-Module -Name PSFzf -Scope CurrentUser -Force" || true
fi
fi

# ==============================================================================
# Phase 17: GitHub CLI
# ==============================================================================

if run_phase 17; then
section "Phase 17: GitHub CLI"

if ! command -v gh &>/dev/null; then
	sudo mkdir -p -m 755 /etc/apt/keyrings
	wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
		sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
	sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
		sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
	sudo apt update
	sudo apt install --yes gh
fi
fi

# ==============================================================================
# Phase 18: Oh My Zsh + plugins
# ==============================================================================

if run_phase 18; then
section "Phase 18: Oh My Zsh"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || \
	git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || \
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# Powerlevel10k theme
[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ] || \
	git clone --depth 1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"

# chucknorris plugin depends on fortune
sudo apt install --yes fortune-mod

# NOTE: Plugin config (plugins=, ZSH_HIGHLIGHT_STYLES, LS_COLORS) lives in
# config/.zshrc — deploy_configs.sh symlinks it to ~/.zshrc.
fi

# ==============================================================================
# Phase 19: FZF
# ==============================================================================

if run_phase 19; then
section "Phase 19: FZF"

if [ ! -d "$HOME/.fzf" ]; then
	git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
	"$HOME/.fzf/install" --all
fi
fi

# ==============================================================================
# Phase 20: Applications (ZEN browser, Signal, NordVPN)
# ==============================================================================

if run_phase 20; then
section "Phase 20: Applications"

# ZEN browser via Flatpak
if confirm "Install ZEN browser (Flatpak)?"; then
	flatpak install -y flathub app.zen_browser.zen || true
fi

# Signal Desktop
if confirm "Install Signal Desktop?"; then
	wget -qO- https://updates.signal.org/desktop/apt/keys.asc | \
		gpg --dearmor | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
	echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' | \
		sudo tee /etc/apt/sources.list.d/signal-xenial.list > /dev/null
	sudo apt update
	sudo apt install --yes signal-desktop || echo "WARN: Signal Desktop installation failed."
fi

# NordVPN
if confirm "Install NordVPN?"; then
	sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh) || echo "WARN: NordVPN installation failed."
	echo "Run 'nordvpn login' and 'nordvpn connect' after setup."
fi
fi

# ==============================================================================
# Phase 21: Nemo file manager setup
# ==============================================================================

if run_phase 21; then
section "Phase 21: Nemo configuration"

xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search 2>/dev/null || true
mkdir -p "$HOME/.gnome2/accels"
touch "$HOME/.gnome2/accels/nemo"
NEMO_ACCEL='(gtk_accel_path "<Actions>/DirViewActions/OpenInTerminal" "F4")'
grep -qF "$NEMO_ACCEL" "$HOME/.gnome2/accels/nemo" || echo "$NEMO_ACCEL" >> "$HOME/.gnome2/accels/nemo"
fi

# ==============================================================================
# Phase 22: auto-cpufreq
# ==============================================================================

if run_phase 22; then
section "Phase 22: auto-cpufreq"

if [[ "$VM_MODE" == true ]]; then
	echo "SKIPPED — not needed in VM mode."
elif command -v auto-cpufreq &>/dev/null; then
	echo "auto-cpufreq already installed, skipping."
elif confirm "Install auto-cpufreq (laptop power management)?"; then
	BUILD_DIR=$(mktemp -d)
	git clone https://github.com/AdnanHodzic/auto-cpufreq.git "$BUILD_DIR/auto-cpufreq"
	cd "$BUILD_DIR/auto-cpufreq"
	sudo ./auto-cpufreq-installer
	cd "$REPO_DIR"
	rm -rf "$BUILD_DIR"
fi
fi

fi # end of --minimal guard

# ==============================================================================
# Done
# ==============================================================================

section "Setup Complete"

echo "Next steps:"
echo "  1. Run:  ./deploy_configs.sh"
echo "  2. Copy a wallpaper to:  ~/.wallpaper"
echo "  3. Reboot and login at TTY — X will auto-start"
echo "  4. Configure GTK theme via:  lxappearance"
echo "  5. See checklist.md for manual post-install tasks"
echo ""
echo "Log saved to: $LOG_FILE"
