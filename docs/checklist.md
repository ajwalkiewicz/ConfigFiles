# Post Installation Checklist

## Debian 13 (Trixie) + i3 — MSI Modern 14 B11MO

### After running `debian_setup.sh`

1. **Deploy configs**: `./scripts/deploy_configs.sh && ./scripts/deploy_configs.sh --system`
2. **Set wallpaper**: Copy an image to `~/.wallpaper`
3. **Reboot** — Login at TTY1, X will auto-start via `.zprofile`

### After first boot into i3

4. **Verify hardware**:
   - [ ] WiFi connects (nm-applet in tray, SSID shown in i3status)
   - [ ] Bluetooth works (blueman-applet, pair a device)
   - [ ] Audio plays (speakers + headphones, use `pavucontrol` to test)
   - [ ] Brightness keys (Fn+Up/Down) adjust backlight
   - [ ] Volume keys (Fn+keys) adjust PipeWire volume
   - [ ] Touchpad: tap-to-click, natural scrolling, two-finger scroll
   - [ ] Battery percentage shows in i3status
   - [ ] Lid close → suspend, lid open → lock screen prompt

5. **Configure GTK theme**:
   - Open `lxappearance`
   - Set Widget theme: **Pop** (light)
   - Set Icon theme: **Pop**
   - Set Default font: **MesloLGS NF 10**
   - Set Cursor theme: **Adwaita** (size 24)

6. **Terminal setup**:
   - Set tilix as default: `sudo update-alternatives --config x-terminal-emulator`
   - Import gruvbox color scheme in Tilix preferences

7. **External monitor** (if needed):
   - Use `arandr` to arrange displays
   - Save layout script for automatic application

8. **Application logins**:
   - [ ] ZEN browser: login, install extensions, set as default browser
   - [ ] Signal Desktop: link to phone
   - [ ] NordVPN: `nordvpn login` then `nordvpn connect`
   - [ ] GitHub CLI: `gh auth login`

9. **VSCode**: Open and verify extensions load

10. **Set default applications**:
    - Browser: `xdg-settings set default-web-browser app.zen_browser.zen.desktop` (or via Flatpak)
    - Video player: `xdg-mime default mpv.desktop video/mp4`
    - File manager: should already be nemo (set by setup script)

### Keyboard reference (Mod = Super key)

| Key | Action |
|-----|--------|
| `Mod+Return` | Open Tilix |
| `Mod+d` | Rofi app launcher |
| `Mod+q` | Kill window |
| `Mod+Escape` | Lock screen |
| `Mod+n` | Open Nemo |
| `Mod+Shift+s` | Screenshot (flameshot) |
| `Mod+hjkl` | Focus left/down/up/right |
| `Mod+1-0` | Switch workspace |
| `Mod+Shift+e` | Exit i3 |

## Pop!_OS (legacy — see setup.sh)

- Setting tilix as default terminal
  `sudo update-alternatives --config x-terminal-emulator`
- Setting flameshot `/usr/bin/flameshot gui`
- Set gnome tweaks: hover focus, CapsLock as Ctrl
- Set configs from github repo
- Dropbox
- Oh my zsh
- Settings: pl keyboard, 24h time, night mode
