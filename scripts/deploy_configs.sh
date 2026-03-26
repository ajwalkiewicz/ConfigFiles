#!/usr/bin/bash
# ==============================================================================
# Deploy configuration files from this repo to system locations.
# Uses symlinks so changes in the repo are reflected immediately.
#
# Reads deploy.conf to decide which config groups to deploy.
#
# Usage:
#   chmod +x deploy_configs.sh
#   ./deploy_configs.sh              # Deploy user configs
#   ./deploy_configs.sh --system     # Also deploy /etc/ configs (sudo)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONF_FILE="$REPO_DIR/config/deploy.conf"
SYSTEM_MODE=false

for arg in "$@"; do
	case "$arg" in
		--system) SYSTEM_MODE=true ;;
	esac
done

# ------------------------------------------------------------------------------
# Read deploy.conf
# ------------------------------------------------------------------------------

# Defaults (if deploy.conf is missing or a key is absent)
USE_I3=yes
USE_STARTX=yes
USE_VSCODE=yes
USE_TILIX=yes
USE_XORG_SYSTEM=yes

if [[ -f "$CONF_FILE" ]]; then
	# Source only KEY=value lines, ignore comments and blanks
	while IFS='=' read -r key value; do
		key=$(echo "$key" | tr -d '[:space:]')
		value=$(echo "$value" | tr -d '[:space:]')
		case "$key" in
			USE_I3)          USE_I3="$value" ;;
			USE_STARTX)      USE_STARTX="$value" ;;
			USE_VSCODE)      USE_VSCODE="$value" ;;
			USE_TILIX)       USE_TILIX="$value" ;;
			USE_XORG_SYSTEM) USE_XORG_SYSTEM="$value" ;;
		esac
	done < <(grep -E '^[A-Z_]+=.+' "$CONF_FILE")
	echo "Loaded config from: $CONF_FILE"
else
	echo "WARN: $CONF_FILE not found, using defaults (all features enabled)."
fi

echo "  USE_I3=$USE_I3  USE_STARTX=$USE_STARTX  USE_VSCODE=$USE_VSCODE  USE_TILIX=$USE_TILIX"
echo ""

# ------------------------------------------------------------------------------
# Helper
# ------------------------------------------------------------------------------

link_config() {
	local src="$1"
	local dst="$2"

	if [ ! -e "$src" ]; then
		echo "SKIP: Source does not exist: $src"
		return
	fi

	mkdir -p "$(dirname "$dst")"

	if [ -L "$dst" ]; then
		rm "$dst"
	elif [ -e "$dst" ]; then
		local bak="${dst}.bak.$(date +%Y%m%d%H%M%S)"
		echo "BACKUP: $dst → $bak"
		mv "$dst" "$bak"
	fi

	ln -s "$src" "$dst"
	echo "LINK: $dst → $src"
}

# ==============================================================================
# 1. Universal dotfiles (config/) — always deployed
# ==============================================================================

echo "=== Deploying universal dotfiles (config/) ==="
echo ""

link_config "$REPO_DIR/config/.zprofile"    "$HOME/.zprofile"
link_config "$REPO_DIR/config/.zshrc"       "$HOME/.zshrc"
link_config "$REPO_DIR/config/.p10k.zsh"    "$HOME/.p10k.zsh"
link_config "$REPO_DIR/config/.vimrc"       "$HOME/.vimrc"
link_config "$REPO_DIR/config/.gitconfig"   "$HOME/.gitconfig"
link_config "$REPO_DIR/config/.screenrc"    "$HOME/.screenrc"
link_config "$REPO_DIR/config/.profile"     "$HOME/.profile"
link_config "$REPO_DIR/config/.bashrc"      "$HOME/.bashrc"
link_config "$REPO_DIR/config/.bash_logout" "$HOME/.bash_logout"
link_config "$REPO_DIR/config/.Xresources"  "$HOME/.Xresources"

# ==============================================================================
# 2. i3 + X11 session (conditional on USE_I3)
# ==============================================================================

if [[ "$USE_I3" == "yes" ]]; then
	echo ""
	echo "=== Deploying i3 + X11 configs ==="
	echo ""

	# i3
	link_config "$REPO_DIR/programs/i3" "$HOME/.config/i3"

	# Picom
	link_config "$REPO_DIR/programs/picom" "$HOME/.config/picom"

	# Rofi
	link_config "$REPO_DIR/programs/rofi" "$HOME/.config/rofi"

	# Dunst
	link_config "$REPO_DIR/programs/dunst" "$HOME/.config/dunst"


else
	echo ""
	echo "SKIP: i3 + X11 configs (USE_I3=no)"
fi

# ==============================================================================
# 3. Startx flag (conditional on USE_STARTX)
# ==============================================================================

STARTX_FLAG="$HOME/.config/walu/use_startx"

if [[ "$USE_STARTX" == "yes" && "$USE_I3" == "yes" ]]; then
	mkdir -p "$(dirname "$STARTX_FLAG")"
	touch "$STARTX_FLAG"
	echo "FLAG: Created $STARTX_FLAG (zprofile will auto-start X on tty1)"
else
	if [[ -f "$STARTX_FLAG" ]]; then
		rm "$STARTX_FLAG"
		echo "FLAG: Removed $STARTX_FLAG (no auto-startx)"
	fi
fi

# ==============================================================================
# 4. VSCode (conditional on USE_VSCODE)
# ==============================================================================

if [[ "$USE_VSCODE" == "yes" ]]; then
	VSCODE_DIR="$HOME/.config/Code/User"
	mkdir -p "$VSCODE_DIR"
	link_config "$REPO_DIR/programs/vscode/settings.json"    "$VSCODE_DIR/settings.json"
	link_config "$REPO_DIR/programs/vscode/keybindings.json" "$VSCODE_DIR/keybindings.json"
	link_config "$REPO_DIR/programs/vscode/extensions.json"  "$VSCODE_DIR/extensions.json"
else
	echo "SKIP: VSCode configs (USE_VSCODE=no)"
fi

# ==============================================================================
# 5. Tilix schemes (conditional on USE_TILIX)
# ==============================================================================

if [[ "$USE_TILIX" == "yes" ]] && [ -d "$REPO_DIR/programs/tilix/schemes" ]; then
	TILIX_DIR="$HOME/.config/tilix/schemes"
	mkdir -p "$TILIX_DIR"
	for scheme in "$REPO_DIR/programs/tilix/schemes"/*.json; do
		[ -f "$scheme" ] && link_config "$scheme" "$TILIX_DIR/$(basename "$scheme")"
	done
else
	echo "SKIP: Tilix schemes (USE_TILIX=no or no schemes found)"
fi

# ==============================================================================
# 6. Wallpapers (always, if present)
# ==============================================================================

if [ -d "$REPO_DIR/wallpapers" ]; then
	mkdir -p "$HOME/Pictures"
	link_config "$REPO_DIR/wallpapers" "$HOME/Pictures/wallpapers"
fi

# ==============================================================================
# 7. Vim colors and indent (always)
# ==============================================================================

mkdir -p "$HOME/.vim"
if [ -d "$REPO_DIR/programs/vim/colors" ]; then
	link_config "$REPO_DIR/programs/vim/colors" "$HOME/.vim/colors"
fi
if [ -d "$REPO_DIR/programs/vim/indent" ]; then
	link_config "$REPO_DIR/programs/vim/indent" "$HOME/.vim/indent"
fi

# ==============================================================================
# 8. System configs (require --system flag + sudo)
# ==============================================================================

if [[ "$SYSTEM_MODE" == true && "$USE_XORG_SYSTEM" == "yes" ]]; then
	echo ""
	echo "=== Deploying system configs (sudo required) ==="
	echo ""

	# Touchpad — intentionally uses cp (not symlink) for /etc/ configs.
	# System configs should not depend on user home or repo paths.
	sudo mkdir -p /etc/X11/xorg.conf.d
	sudo cp "$REPO_DIR/programs/xorg/40-libinput.conf" /etc/X11/xorg.conf.d/40-libinput.conf
	echo "COPY: /etc/X11/xorg.conf.d/40-libinput.conf"

	# Keyboard — CapsLock → Ctrl
	sudo cp "$REPO_DIR/programs/xorg/00-keyboard.conf" /etc/X11/xorg.conf.d/00-keyboard.conf
	echo "COPY: /etc/X11/xorg.conf.d/00-keyboard.conf"
elif [[ "$SYSTEM_MODE" == false ]]; then
	echo ""
	echo "NOTE: Run with --system to deploy /etc/X11/xorg.conf.d/ configs (sudo)."
fi

# ==============================================================================
# Summary
# ==============================================================================

echo ""
echo "=== Deployment complete ==="
echo ""
echo "Config: deploy.conf controls what gets deployed."
echo ""
echo "Always deployed:"
echo "  ~/.zprofile     ~/.zshrc       ~/.p10k.zsh"
echo "  ~/.vimrc        ~/.gitconfig   ~/.screenrc"
echo "  ~/.profile      ~/.bashrc      ~/.bash_logout"
echo "  ~/.Xresources"
if [[ "$USE_I3" == "yes" ]]; then
	echo ""
	echo "i3 desktop:"
	echo "  ~/.config/i3/    ~/.config/picom/   ~/.config/rofi/"
	echo "  ~/.config/dunst/"
	if [[ "$USE_STARTX" == "yes" ]]; then
		echo "  ~/.config/walu/use_startx  (auto-start X on tty1)"
	fi
fi
echo ""
echo "Don't forget:"
echo "  1. Copy a wallpaper to ~/.wallpaper"
echo "  2. Set GTK theme via lxappearance"
echo "  3. Run: xrdb -merge ~/.Xresources"
