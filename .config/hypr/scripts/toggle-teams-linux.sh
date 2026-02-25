#!/bin/bash
ADDRESS=$(hyprctl clients -j | jq -r '.[] | select(.class == "teams-for-linux") | .address' | head -1)
if [ -n "$ADDRESS" ]; then
    hyprctl dispatch focuswindow "address:$ADDRESS"
else
    /opt/teams-for-linux/teams-for-linux &
fi
