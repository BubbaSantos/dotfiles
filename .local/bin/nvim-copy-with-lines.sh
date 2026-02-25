#!/bin/bash
# Script to add line numbers and copy to clipboard in nvim (Wayland version)

# Send Escape first to ensure we're in normal mode
ydotool key 1:0

# Add line numbers
ydotool type ':% !nl -ba'
ydotool key 28:1 28:0  # Enter key
sleep 0.3

# Select all (ggVG)
ydotool type 'ggVG'
sleep 0.2

# Copy to system clipboard
ydotool type '"+y'
sleep 0.3

# Undo
ydotool key 1:0  # Escape
ydotool type 'u'
