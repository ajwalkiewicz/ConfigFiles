#!/usr/bin/env bash
# Dynamically parse i3 config and display keybindings in a floating window.
# Re-reads the config on every invocation so the help is always up to date.

set -euo pipefail

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/i3/config"

if [[ ! -f "$CONFIG" ]]; then
    notify-send "i3 Help" "Config file not found: $CONFIG"
    exit 1
fi

# Parse the config into a formatted help text.
# Collects section headers (lines between ====) and bindsym lines.
generate_help() {
    local section=""
    local output=""
    local in_mode=""

    while IFS= read -r line; do
        # Detect section headers: "# Key Bindings — Launchers & Applications"
        if [[ "$line" =~ ^#\ (.+) ]]; then
            candidate="${BASH_REMATCH[1]}"
            if [[ "$candidate" =~ ^=+ ]]; then continue; fi
            # Skip short comments; keep only meaningful section titles
            if (( ${#candidate} > 5 )); then
                section="$candidate"
            fi
            continue
        fi

        # Track mode blocks (e.g. resize)
        if [[ "$line" =~ ^mode\ \"([^\"]+)\" ]]; then
            in_mode="${BASH_REMATCH[1]}"
            continue
        fi
        if [[ "$line" == "}" ]]; then
            in_mode=""
            continue
        fi

        # Match bindsym lines
        if [[ "$line" =~ ^[[:space:]]*bindsym\ (.+) ]]; then
            binding="${BASH_REMATCH[1]}"
            # Split into key combo and action
            key="${binding%% *}"
            action="${binding#* }"
            # Strip common prefixes for cleaner display
            action="${action#exec }"
            action="${action#--no-startup-id }"

            # Prettify modifier names
            key="${key//\$mod/Super}"
            key="${key//Mod1/Alt}"
            key="${key//Mod4/Super}"

            prefix=""
            if [[ -n "$in_mode" ]]; then
                prefix="[$in_mode] "
            fi

            printf -v entry "  %-32s %s\n" "${prefix}${key}" "$action"
            output+="$entry"
        fi
    done < "$CONFIG"

    # Group output by section: re-parse to interleave headers
    local current_section=""
    local result=""
    local last_section=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^#\ (.+) ]]; then
            candidate="${BASH_REMATCH[1]}"
            if [[ "$candidate" =~ ^=+ ]]; then continue; fi
            if (( ${#candidate} > 5 )); then
                current_section="$candidate"
            fi
            continue
        fi
        if [[ "$line" =~ ^mode\ \"([^\"]+)\" ]]; then
            if [[ "$current_section" != "$last_section" && -n "$current_section" ]]; then
                result+=$'\n'"  $current_section"$'\n'"  $(printf '%.0s─' {1..50})"$'\n'
                last_section="$current_section"
            fi
            current_section="Mode: ${BASH_REMATCH[1]}"
            continue
        fi
        if [[ "$line" == "}" ]]; then
            continue
        fi
        if [[ "$line" =~ ^[[:space:]]*bindsym\ (.+) ]]; then
            if [[ "$current_section" != "$last_section" && -n "$current_section" ]]; then
                result+=$'\n'"  $current_section"$'\n'"  $(printf '%.0s─' {1..50})"$'\n'
                last_section="$current_section"
            fi
            binding="${BASH_REMATCH[1]}"
            key="${binding%% *}"
            action="${binding#* }"
            action="${action#exec }"
            action="${action#--no-startup-id }"
            key="${key//\$mod/Super}"
            key="${key//Mod1/Alt}"
            key="${key//Mod4/Super}"
            printf -v entry "  %-32s %s\n" "$key" "$action"
            result+="$entry"
        fi
    done < "$CONFIG"

    echo "$result"
}

HELP_TEXT="$(generate_help)"
TITLE="i3 Keyboard Shortcuts"

# Display using the best available tool
if command -v yad &>/dev/null; then
    echo -e "$HELP_TEXT" | yad --text-info \
        --title="$TITLE" \
        --width=700 --height=700 \
        --fontname="MesloLGS NF 10" \
        --button="Close:0" \
        --center
elif command -v zenity &>/dev/null; then
    echo -e "$HELP_TEXT" | zenity --text-info \
        --title="$TITLE" \
        --width=700 --height=700 \
        --font="MesloLGS NF 10"
else
    # Fallback: use xmessage
    echo -e "$HELP_TEXT" | xmessage -file - -title "$TITLE" -center
fi
