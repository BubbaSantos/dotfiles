#!/bin/bash
ADDRESS=$(hyprctl clients -j | jq -r '.[] | select(.class | contains("teams.microsoft.com")) | .address' | head -1)
if [ -n "$ADDRESS" ]; then
    hyprctl dispatch focuswindow "address:$ADDRESS"
else
    # Check if system prefers dark mode
    COLOR_SCHEME=$(gsettings get org.gnome.desktop.interface color-scheme)
    
    if [[ "$COLOR_SCHEME" == *"dark"* ]]; then
        EXTRA_FLAGS="--force-dark-mode --enable-features=WebContentsForceDark"
    else
        EXTRA_FLAGS=""
    fi
    
    chromium --profile-directory="Profile 1" --app="https://teams.microsoft.com/v2/" \
        --enable-features=WebAppWindowControlsOverlay \
        --ozone-platform=wayland \
        $EXTRA_FLAGS &
fi
