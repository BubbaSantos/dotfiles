#!/bin/bash
# Check if X webapp is running
if hyprctl clients | grep -q "chrome-x.com__-Profile_1"; then
    # Toggle the special workspace
    hyprctl dispatch togglespecialworkspace x
else
    # Launch X webapp
    chromium --profile-directory="Profile 1" --app="https://x.com" --hide-scrollbars &
fi
