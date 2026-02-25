#!/bin/bash
# ~/.config/waybar/scripts/wifi-toggle.sh

STATE_FILE="/tmp/waybar-wifi-state"

# Check current state
if [ -f "$STATE_FILE" ]; then
    # Currently showing percentage, switch to name only
    rm "$STATE_FILE"
else
    # Currently showing name only, switch to percentage
    touch "$STATE_FILE"
fi

# Reload waybar
pkill -SIGUSR2 waybar
