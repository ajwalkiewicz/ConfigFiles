#!/usr/bin/bash
# ==============================================================================
# Monitor layout switcher — select configuration via rofi or CLI argument.
#
# Usage:
#   monitor_setup.sh              # Show rofi menu
#   monitor_setup.sh laptop       # Laptop only
#   monitor_setup.sh extend       # Extend to external (right)
#   monitor_setup.sh external     # External only
#   monitor_setup.sh mirror       # Mirror displays
# ==============================================================================

set -euo pipefail

# Auto-detect outputs. Adjust if your hardware differs.
LAPTOP=$(xrandr --query | grep ' connected' | grep -i 'edp\|lvds' | head -1 | awk '{print $1}')
EXTERNAL=$(xrandr --query | grep ' connected' | grep -iv 'edp\|lvds' | head -1 | awk '{print $1}')

apply_layout() {
    local mode="$1"

    case "$mode" in
        laptop)
            if [[ -n "$EXTERNAL" ]]; then
                xrandr --output "$EXTERNAL" --off --output "$LAPTOP" --auto --primary
            else
                xrandr --output "$LAPTOP" --auto --primary
            fi
            ;;
        extend)
            if [[ -z "$EXTERNAL" ]]; then
                notify-send "Monitor Setup" "No external monitor detected" 2>/dev/null || true
                return 1
            fi
            xrandr --output "$LAPTOP" --auto --primary \
                   --output "$EXTERNAL" --auto --right-of "$LAPTOP"
            ;;
        external)
            if [[ -z "$EXTERNAL" ]]; then
                notify-send "Monitor Setup" "No external monitor detected" 2>/dev/null || true
                return 1
            fi
            xrandr --output "$LAPTOP" --off \
                   --output "$EXTERNAL" --auto --primary
            ;;
        mirror)
            if [[ -z "$EXTERNAL" ]]; then
                notify-send "Monitor Setup" "No external monitor detected" 2>/dev/null || true
                return 1
            fi
            xrandr --output "$LAPTOP" --auto --primary \
                   --output "$EXTERNAL" --auto --same-as "$LAPTOP"
            ;;
        *)
            echo "Unknown mode: $mode" >&2
            return 1
            ;;
    esac

    # Re-apply wallpaper after layout change
    feh --bg-fill --no-fehbg "$HOME/.wallpaper" 2>/dev/null || true
}

# If an argument was given, use it directly
if [[ $# -ge 1 ]]; then
    apply_layout "$1"
    exit $?
fi

# Otherwise, show rofi menu
CHOICES="💻  Laptop only (laptop)\n🖥️  Extend right (extend)\n📺  External only (external)\n🪞  Mirror (mirror)"
SELECTED=$(echo -e "$CHOICES" | rofi -dmenu -i -p "Monitor layout" | grep -oP '\(\K[^)]+')

if [[ -n "$SELECTED" ]]; then
    apply_layout "$SELECTED"
fi
