#!/bin/bash
ADDRESS=$(hyprctl clients -j | jq -r '.[] | select(.class | contains("outlook.office.com")) | .address' | head -1)
if [ -n "$ADDRESS" ]; then
    hyprctl dispatch focuswindow "address:$ADDRESS"
else
    chromium --profile-directory="Profile 1" --app="https://outlook.office.com" \
        --hide-scrollbars \
        --enable-features=UseOzonePlatform,WebAppWindowControlsOverlay \
        --ozone-platform=wayland \
        --disable-features=WaylandWpColorManagerV1,WebContentsForceDark &
fi
