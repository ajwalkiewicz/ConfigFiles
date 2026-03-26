#!/usr/bin/bash
# ==============================================================================
# Power menu via rofi — shutdown, reboot, suspend, lock, logout.
# ==============================================================================

set -euo pipefail

OPTIONS="🔒  Lock\n🚪  Logout\n😴  Suspend\n🔄  Reboot\n⏻   Shutdown"

SELECTED=$(echo -e "$OPTIONS" | rofi -dmenu -i -p "Power" -theme-str 'window {width: 300px;}' | awk '{print $2}')

case "$SELECTED" in
    Lock)
        sh ~/.config/i3/scripts/lock.sh
        ;;
    Logout)
        i3-msg exit
        ;;
    Suspend)
        sh ~/.config/i3/scripts/lock.sh && systemctl suspend
        ;;
    Reboot)
        systemctl reboot
        ;;
    Shutdown)
        systemctl poweroff
        ;;
    *)
        exit 0
        ;;
esac
