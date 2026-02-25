#!/bin/bash

# Check if FotMob webapp is running
if hyprctl clients | grep -q "chrome-www.fotmob.com__en-Profile_1"; then
    # Toggle the special workspace
    hyprctl dispatch togglespecialworkspace fotmob
else
    # Launch FotMob webapp
    chromium --profile-directory="Profile 1" --app="https://www.fotmob.com/en" --hide-scrollbars &
fi
