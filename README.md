# Config Files

Personal dotfiles and system configuration for two target environments:

- **Debian 13 (Trixie) + i3** — Minimal server-to-desktop setup on MSI Modern 14 B11MO
- **Pop!\_OS 22.04** — Legacy full desktop setup

## Debian 13 + i3 Setup (primary)

For a fresh Debian minimal/server install → i3 tiling window manager desktop.

### Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/ajwalkiewicz/ConfigFiles.git ~/Git/ConfigFiles
cd ~/Git/ConfigFiles

# 2. Run the setup script (installs all packages)
./scripts/debian_setup.sh          # Full setup
./scripts/debian_setup.sh --minimal  # Core desktop only

# 3. Deploy config files (symlinks to system locations)
./scripts/deploy_configs.sh
./scripts/deploy_configs.sh --system  # Also deploys /etc/ configs (sudo)

# 4. Copy a wallpaper
cp wallpapers/your-wallpaper.jpg ~/.wallpaper

# 5. Reboot — login at TTY, X auto-starts
sudo reboot
```

### What you get

| Component | Tool |
|-----------|------|
| Window Manager | i3 (gaps enabled) |
| Compositor | Picom |
| App Launcher | Rofi |
| Terminal | Tilix |
| Status Bar | i3status (WiFi, battery, volume, CPU) |
| Notifications | Dunst |
| File Manager | Nemo |
| Audio | PipeWire + WirePlumber |
| Network | NetworkManager + nm-applet |
| Bluetooth | BlueZ + Blueman |
| Screen Lock | i3lock-color (pixelated blur + clock) |
| Brightness | brightnessctl |
| Screenshots | Flameshot |
| GTK Theme | Pop (light) |

### Boot chain

```
TTY login → .zprofile → startx → .xserverrc → .xinitrc → i3
```

No display manager. X starts automatically on tty1.

### Key bindings (Mod = Super)

| Key | Action |
|-----|--------|
| `Mod+Return` | Tilix terminal |
| `Mod+d` | Rofi (apps) |
| `Mod+\|` | Rofi (windows) |
| `Mod+q` | Kill window |
| `Mod+Escape` | Lock screen |
| `Mod+n` | Nemo file manager |
| `Mod+Shift+s` | Screenshot |
| `Mod+hjkl` | Focus (vim-style) |
| `Mod+r` | Resize mode |
| `XF86Audio*` | Volume control (PipeWire) |
| `XF86MonBrightness*` | Screen brightness |

## Pop!\_OS Setup (legacy)

For Pop!\_OS 22.04 or similar Ubuntu/GNOME-based systems:

```bash
./scripts/setup.sh
```

See [setup.sh](scripts/setup.sh) for details.

## Repository Structure

```
.
├── scripts/
│   ├── debian_setup.sh        # Debian 13 → i3 desktop setup
│   ├── deploy_configs.sh      # Symlink configs to system locations
│   ├── setup.sh               # Pop!_OS setup (legacy)
│   └── install_programs.sh    # Interactive installer (legacy)
├── dot_files/
│   ├── xinitrc                # X session startup
│   ├── xserverrc              # X server startup
│   ├── zprofile               # Login shell (auto-startx)
│   └── Xresources             # X resources (DPI, cursor)
├── programs/
│   ├── i3/
│   │   ├── config             # i3 window manager config
│   │   ├── i3status.conf      # Status bar
│   │   ├── compton.conf       # Legacy compositor config
│   │   └── scripts/lock.sh    # i3lock-color lock script
│   ├── picom/picom.conf       # Picom compositor
│   ├── dunst/dunstrc          # Notification daemon
│   ├── rofi/                  # App launcher configs
│   ├── xorg/                  # Xorg configs (touchpad)
│   ├── tilix/                 # Terminal color schemes
│   ├── vim/                   # Vim setup + color schemes
│   └── vscode/                # VSCode settings + extensions
├── config/                    # PowerShell profile
├── docker/                    # Docker images (Claude Code, minimal)
├── wallpapers/                # Wallpaper images
├── archive/                   # Old/backup configurations
├── checklist.md               # Post-install manual steps
└── CLAUDE.md                  # Claude Code guidance
```

## Hardware Target

**MSI Modern 14 B11MO REV:1.0** — Intel 11th Gen Tiger Lake, Intel Iris Xe graphics, Intel AX201 WiFi. Requires `intel-microcode`, `firmware-iwlwifi`, and `firmware-misc-nonfree` from Debian non-free repos (handled by `debian_setup.sh`).
