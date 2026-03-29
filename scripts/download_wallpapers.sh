#!/usr/bin/bash
# ==============================================================================
# Download Pop!_OS wallpapers into ~/Pictures/wallpapers/pop-os/
# Uses a shallow clone to minimize disk usage.
#
# Usage:
#   ./download_wallpapers.sh
# ==============================================================================

set -euo pipefail

DEST="$HOME/Pictures/wallpapers/pop-os"

if [[ -d "$DEST" ]]; then
    echo "Pop!_OS wallpapers already present at $DEST"
    echo "To update, remove the directory and re-run this script."
    exit 0
fi

echo "Downloading Pop!_OS wallpapers..."
mkdir -p "$(dirname "$DEST")"
git clone --depth 1 https://github.com/pop-os/wallpapers.git "$DEST"

# Remove git metadata to save space (these are just images)
rm -rf "$DEST/.git"

echo ""
echo "Done. Wallpapers saved to: $DEST"
echo ""
echo "To set a wallpaper:"
echo "  cp $DEST/<image> ~/.wallpaper"
echo "  feh --bg-fill ~/.wallpaper"
