#!/bin/bash
ADDRESS=$(hyprctl clients -j | jq -r '.[] | select(.class | contains("outlook.office.com")) | .address' | head -1)
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
    
    chromium --profile-directory="Profile 1" --app="https://outlook.office.com" \
        --hide-scrollbars \
        --enable-features=UseOzonePlatform,WebAppWindowControlsOverlay \
        --ozone-platform=wayland \
        $EXTRA_FLAGS &
fi
