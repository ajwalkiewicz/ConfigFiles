#!/usr/bin/env bash
# Screen lock script using i3lock-color with pixelated screenshot background.
# Requires: scrot, imagemagick (convert), i3lock-color

IMG=/tmp/i3lock.png

# Take screenshot and pixelate it
scrot -o "$IMG"
convert "$IMG" -scale 10% -scale 1000% "$IMG"

# Lock with i3lock-color
i3lock \
    --image="$IMG" \
    --clock \
    --indicator \
    --inside-color=00000080 \
    --ring-color=FBB86Cff \
    --line-uses-ring \
    --keyhl-color=FFFFFFff \
    --bshl-color=d75f5fff \
    --separator-color=00000000 \
    --insidever-color=00000080 \
    --ringver-color=FBB86Cff \
    --insidewrong-color=d75f5f80 \
    --ringwrong-color=d75f5fff \
    --time-color=FFFFFFff \
    --date-color=FFFFFFcc \
    --time-str="%H:%M" \
    --date-str="%A, %d %B" \
    --time-font="MesloLGS NF" \
    --date-font="MesloLGS NF" \
    --time-size=48 \
    --date-size=18 \
    --radius=120 \
    --ring-width=8 \
    --nofork

# Clean up
rm -f "$IMG"
