#!/bin/bash
# Check if Jellyfin window exists
if hyprctl clients | grep -q "chrome-192.168.1.115_8096__-Profile_1"; then
    # Get the address of the first Jellyfin window
    jellyfin_addr=$(hyprctl clients -j | jq -r '.[] | select(.class == "chrome-192.168.1.115_8096__-Profile_1") | .address' | head -n 1)

    # Focus the Jellyfin window
    hyprctl dispatch focuswindow "address:$jellyfin_addr"
else
    # Launch Jellyfin
    chromium --ozone-platform=wayland --app=http://192.168.1.115:8096 &
fi
