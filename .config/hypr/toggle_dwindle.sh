#!/bin/bash
config="$HOME/.config/hypr/looknfeel.conf"

# Check if force_split is commented out
if grep -q "^[[:space:]]*#default_split_ratio = 1.35" "$config"; then
    # Uncomment the lines
    sed -i 's/^[[:space:]]*#default_split_ratio = 1.35/    default_split_ratio = 1.35/' "$config"
    sed -i 's/^[[:space:]]*#force_split = 2/    force_split = 2/' "$config"
    hyprctl reload
    notify-send "Dwindle Layout" "Split ratio 70/30" -u low
else
    # Comment out the lines
    sed -i 's/^[[:space:]]*default_split_ratio = 1.35/    #default_split_ratio = 1.35/' "$config"
    sed -i 's/^[[:space:]]*force_split = 2/    #force_split = 2/' "$config"
    hyprctl reload
    notify-send "Dwindle Layout" "Split ratio 50/50" -u low
fi
