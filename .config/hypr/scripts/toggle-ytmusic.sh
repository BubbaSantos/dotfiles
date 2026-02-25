#!/bin/bash

# Check if YT Music webapp is running
if hyprctl clients | grep -q "chrome-music.youtube.com__-Profile_1"; then
    # Toggle the special workspace
    hyprctl dispatch togglespecialworkspace ytmusic
else
    # Launch YT Music webapp
    chromium --profile-directory="Profile 1" --app="https://music.youtube.com" --hide-scrollbars &
fi
