#!/bin/bash

# Get currently selected/highlighted text
SELECTED_TEXT=$(wl-paste -p 2>/dev/null)

# URL encode the selected text
ENCODED_TEXT=$(echo "$SELECTED_TEXT" | jq -sRr @uri)

# Launch Zen browser with Google search for the selected text
if [ -n "$SELECTED_TEXT" ]; then
    zen-browser "https://www.google.com/search?q=$ENCODED_TEXT" &
else
    zen-browser "https://www.google.com/search?q=" &
fi

# Capture the PID
ZEN_PID=$!

# Add window rules BEFORE the window appears
hyprctl keyword windowrulev2 "float, pid:$ZEN_PID"
hyprctl keyword windowrulev2 "size 720 495, pid:$ZEN_PID"
hyprctl keyword windowrulev2 "move 356 147, pid:$ZEN_PID"

# Wait for window to appear
sleep 0.3

# Focus the window
WINDOW_ADDRESS=$(hyprctl clients -j | jq -r ".[] | select(.pid == $ZEN_PID) | .address" | head -1)
if [ -n "$WINDOW_ADDRESS" ]; then
    hyprctl dispatch focuswindow address:$WINDOW_ADDRESS
fi
