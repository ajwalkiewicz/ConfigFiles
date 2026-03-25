# ~/.zprofile - Login shell initialization
# Sourced by zsh on login. Sets up PATH and optionally starts X.

# Path
[ -d "$HOME/bin" ] && PATH="$HOME/bin:$PATH"
[ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"

# Homebrew
test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Go
[ -d "$HOME/go/bin" ] && PATH="$PATH:$HOME/go/bin"
[ -d "/usr/local/go/bin" ] && PATH="$PATH:/usr/local/go/bin"

# Start X on tty1 — only when USE_STARTX flag is set (Debian i3 setup).
# Create the flag: mkdir -p ~/.config/walu && touch ~/.config/walu/use_startx
# On DE-based systems (Pop!_OS, Ubuntu Desktop), this block is skipped.
if [[ -f "$HOME/.config/walu/use_startx" && -z "$DISPLAY" && "$XDG_VTNR" -eq 1 ]]; then
	exec startx
fi
