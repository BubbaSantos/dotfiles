#!/bin/bash
ADDRESS=$(hyprctl clients -j | jq -r '.[] | select(.class | contains("web.whatsapp.com")) | .address' | head -1)
if [ -n "$ADDRESS" ]; then
    # Toggle the special workspace
    hyprctl dispatch togglespecialworkspace whatsapp
else
    # Check if system prefers dark mode
    COLOR_SCHEME=$(gsettings get org.gnome.desktop.interface color-scheme)
    
    if [[ "$COLOR_SCHEME" == *"dark"* ]]; then
        EXTRA_FLAGS="--force-dark-mode --enable-features=WebContentsForceDark"
    else
        EXTRA_FLAGS=""
    fi
    
    # Launch WhatsApp webapp
    chromium --profile-directory="Profile 1" --app="https://web.whatsapp.com" \
        --hide-scrollbars \
        $EXTRA_FLAGS &
fi
