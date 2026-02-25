#!/bin/bash
# Check if Keybr webapp is running
if hyprctl clients | grep -q "chrome-www.keybr.com__-Profile_1"; then
    # Focus the Keybr window
    hyprctl dispatch focuswindow "class:chrome-www.keybr.com__-Profile_1"
else
    # Launch Keybr webapp
    uwsm app -- chromium --new-window --ozone-platform=wayland --app="https://www.keybr.com/" &
fi
