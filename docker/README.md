# Dockerfiles

# Claude Code setup in the docker

Build docker with the following command:

```bash
docker build --tag claude-code:latest --file docker/Dockerfile.claude .
```

Run claude-code docker in the project directory

```bash
docker run -it -v $(pwd):/workspace claude-code bash
```

Inside the docker run claude

```bash
claude
```

If you already has settings.json for claude, you can point to the settings,
buy using `--settings` flag:

```bash
claude --settings .claude/settings.json
```

# Minimal Ubuntu Docker (Terminal-Only)

A minimal Docker image with terminal-focused development tools, zsh, and your preferred configuration.

## Build

```bash
docker build --tag minimal:latest --file docker/Dockerfile.minimal .
```

## Run

```bash
docker run -it minimal:latest
```

The container starts as user `walu` (password: `walu`) with zsh as default shell and `/workspace` as the working directory.

### With Volume Mount

Mount current directory for development:

```bash
docker run -it -v $(pwd):/workspace minimal:latest
```

### With Port Forwarding (for SSH, etc.)

```bash
docker run -it -p 2222:22 -v $(pwd):/workspace minimal:latest
```

## Included Tools

**System utils:** git, vim, tree, curl, wget, htop, jq, screen, ncdu, ripgrep, fd, sudo, ssh

**Homebrew packages:** btop, bat, git-delta, exa, fzf, neofetch, uv, go

**Shell:** Oh My Zsh with powerlevel10k theme, zsh-autosuggestions, zsh-syntax-highlighting

**Languages:** Python 3.14 (Homebrew), Node.js, Go, npm

**Other:** Claude Code CLI installed globally

## Configuration Files

The image copies your configuration from `config/` directory:
- **Shell**: `.zshrc`, `.p10k.zsh` (powerlevel10k prompt), `.bashrc`, `.profile`
- **Git**: `.gitconfig` (with delta pager, vim editor, push.default=current)
- **Vim**: `.vimrc` (Vundle plugins: NERDTree, tagbar, vim-airline, gitgutter, etc.)
- **Screen**: `.screenrc`
- **X resources**: `.Xresources`

## VSCode Integration

If you use VSCode with this container, your keybindings from `programs/vscode/keybindings.json` include:
- `Ctrl+Shift+S`: Focus testing panel
- `Ctrl+Shift+O`: Open todo-tree
- `Ctrl+J`: Toggle maximized panel
- `Shift+Alt+Left/Right`: Navigate back/forward

Your VSCode workspace settings (`.vscode/settings.json`) configure:
- Python: Ruff for formatting/linting
- JS/TS: Prettier
- Auto-format on save
- Rulers at 79, 88, 100 characters

Copy these files to your host's VSCode settings for a consistent experience.

## Notes

- User `walu` has sudo privileges (passwordless)
- `fd` command is available (symlinked from `fdfind`)
- Default shell is zsh with custom aliases and LS_COLORS
- Working directory is `/workspace` (owned by walu)