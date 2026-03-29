# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal **dotfiles repository** for a Debian/Ubuntu system using the **i3 tiling window manager**. The repository contains configuration files, installation scripts, and custom settings organized by application. It's designed for semi-automated system setup on fresh installations.

## Common Development Tasks

### Initial System Setup

For a fresh Debian/Ubuntu system, run the main setup script:
```bash
./scripts/setup.sh
```

This semi-automated script will:
- Upgrade system packages
- Install core packages (vim, zsh, git, tilix, feh, tree, etc.)
- Install Homebrew and tools (python@3.14, btop, bat, git-delta, oh-my-posh, go, uv)
- Install Microsoft products (PowerShell, VSCode)
- Install GitHub CLI
- Set up Oh My Zsh with plugins (autosuggestions, syntax-highlighting)
- Install FZF fuzzy finder
- Install ZEN browser via Flatpak
- Install Signal Desktop
- Set up Nemo file manager with custom keybindings
- Install auto-cpufreq

### Interactive Program Installation

For selective program installation using a dialog interface:
```bash
./scripts/install_programs.sh
```

This interactive installer allows selecting from 40+ programs including:
- System tools: htop, bpytop, nmap, tree, ranger, fzf
- Applications: flameshot, peek, slack, discord, Skype, Zoom
- Development tools: git, python3, sublime-text, vim, arduino-cli
- Utilities: tilix, nemo, dropbox, lxappearance, conky, feh, neofetch
- Additional customizations

### Docker Setup (Claude Code Environment)

Build the Claude Code Docker image:
```bash
docker build --tag claude-code:latest --file docker/Dockerfile.claude .
```

Run Claude Code in the project directory:
```bash
docker run -it -v $(pwd):/workspace claude-code bash
```

Inside the container, start Claude:
```bash
claude --settings .claude/settings.json
```

### Minimal Terminal-Only Docker Image

A minimal Ubuntu-based image with terminal tools, zsh configuration, and development utilities:

```bash
# Build
docker build --tag minimal:latest --file docker/Dockerfile.minimal .

# Run (default user: walu, password: walu)
docker run -it minimal:latest

# With volume mount
docker run -it -v $(pwd):/workspace minimal:latest
```

**Features:**
- Ubuntu 24.04 with essential CLI tools (git, vim, zsh, tree, curl, wget, htop, jq, screen, ncdu, ripgrep, fd)
- Homebrew packages: btop, bat, git-delta, exa, fzf, neofetch, uv, go
- Oh My Zsh with powerlevel10k theme and your custom config
- Python 3.14, Node.js, Go
- Claude Code CLI installed globally
- User `walu` with passwordless sudo

## Repository Structure

```
.
├── .claude/
│   └── settings.json          # Claude Code configuration (API settings, permissions)
├── .vscode/
│   ├── settings.json          # VSCode workspace settings (Python, JS/TS formatting)
│   └── extensions.json        # Recommended VSCode extensions
├── archive/                   # Old/backup configurations
│   └── dot_files/             # Legacy dotfiles (bash, vim configs)
├── config/
│   └── Microsoft.PowerShell_profile.ps1  # PowerShell profile
├── docker/
│   ├── Dockerfile.claude      # Docker image with Claude Code CLI
│   ├── Dockerfile.minimal     # Minimal Ubuntu base with terminal tools
│   └── README.md              # Docker usage instructions
├── programs/                  # Application-specific configurations
│   ├── i3/
│   │   ├── config            # i3 window manager config (keybindings, autostart)
│   │   ├── compton.conf      # Compositor settings
│   │   ├── i3status.conf     # Status bar configuration
│   │   └── scripts/          # i3 helper scripts
│   │       └── lock.sh       # i3lock screenshot-based screen lock
│   ├── rofi/                 # Rofi application launcher config
│   ├── tilix/                # Tilix terminal config
│   │   └── schemes/          # Gruvbox color schemes for tilix
│   ├── vim/
│   │   ├── colors/           # Vim color schemes
│   │   ├── indent/           # Vim indentation rules
│   │   ├── vim_setup.sh      # Vim installation script
│   │   └── .vimrc            # Legacy vim configuration
│   └── vscode/
│       ├── settings.json     # VSCode user settings
│       └── extensions.json   # VSCode recommended extensions
├── scripts/
│   ├── setup.sh              # Main semi-automated system setup script
│   └── install_programs.sh   # Interactive program installer
├── wallpapers/               # Wallpaper images
├── checklist.md              # Post-installation checklist
└── README.md                 # Repository description
```

## Key Configuration Details

### i3 Window Manager (programs/i3/config)

- **Mod key**: Super/Windows key (`Mod4`)
- **Keybindings**:
  - `$mod+Return`: Open terminal (tilix)
  - `$mod+q`: Kill focused window
  - `$mod+d`: Launch dmenu (application launcher)
  - `$mod+Escape`: Lock screen
  - `$mod+bar`: Launch rofi
- **Autostart**: Compton compositor runs at startup
- **Font**: MesloLSG NF (Nerd Font) for icons and text

### VSCode Settings (.vscode/settings.json)

- **Python**: Uses Ruff for formatting and linting
- **JS/TS**: Uses Prettier for formatting
- **Testing**: Pytest configured (tests directory)
- **Formatters**: Auto-format on save enabled
- **Rulers**: 79, 88, 100 character limits
- **Spell checker**: Custom dictionary with technical terms
- **Extensions**: See .vscode/extensions.json for recommended extensions

### Zsh Configuration (installed by setup.sh)

- Oh My Zsh framework
- Plugins:
  - zsh-autosuggestions
  - zsh-syntax-highlighting
  - git
- Theme: Powerlevel10k
- Custom colors and LS_COLORS configured

### Vim Configuration (archive/dot_files/vimrc)

- Color scheme: gruvbox (dark background)
- Tab settings: 4 spaces
- Vundle plugin manager installed
- Line numbers, cursorline, wildmenu enabled
- Leader key: `-`

## Important Notes

1. **Non-idempotent setup**: `setup.sh` is designed to run only once on a fresh system. It may fail or cause issues if run multiple times.

2. **User-specific Git config**: install_programs.sh sets git config to "Adam Walkiewicz" <aj.walkiewicz@gmail.com>. Update these values for different users.

3. **Homebrew on Linux**: The setup script installs Linuxbrew (Homebrew for Linux). This is intentional for cross-platform consistency.

4. **Claude Code Settings**: The `.claude/settings.json` file contains API configuration using OpenRouter. Do not commit sensitive tokens (the current file has an example token that should be rotated).

5. **Firefox removal**: The setup script removes Firefox to replace it with ZEN browser.

6. **VSCode configurations**: Both `programs/vscode/` (app-level) and `.vscode/` (workspace-level) contain configs. The workspace settings override app-level settings.

7. **Post-install manual steps**: The `checklist.md` contains manual configuration steps that require user interaction after the automated setup.

## Language and Framework Detection

This repository is primarily **configuration-only** - it contains no application code. When asked to "build" or "test" in this repository:
- Point to the appropriate configuration file in `programs/` or `.vscode/`
- Reference the setup scripts for system-level changes
- No compilation or testing framework is present

## Environment-Specific Considerations

- **Target OS**: Ubuntu/Debian-based Linux distributions
- **Display manager**: i3 window manager (no traditional DE)
- **Terminal**: Tilix with custom gruvbox schemes
- **Shell**: Zsh with Oh My Zsh
- **Browser**: ZEN browser (Flatpak) and Signal Desktop
- **Security**: doas configured for passwordless sudo (install_programs.sh option 33)

## Maintenance

- Configuration files should be edited in place and committed to this repository
- To apply changes: copy/symlink files to appropriate locations in ~/.config/ or home directory
- The repository serves as both backup and deployment mechanism
- Consider using a bare Git repository approach (git --git-dir) for easier management

## Troubleshooting

If setup fails:
1. Check logs in install_programs.sh (logs.txt)
2. Ensure running on Ubuntu/Debian with sudo access
3. Verify internet connectivity for package downloads
4. Some Flatpak installations may require Flatpak to be set up first
5. dialog package is auto-installed if missing for the interactive installer
