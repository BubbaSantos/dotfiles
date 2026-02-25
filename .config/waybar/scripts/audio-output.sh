#!/bin/bash
# Get current default sink
current_sink=$(pactl get-default-sink)

# Determine icon based on actual sink names
if echo "$current_sink" | grep -qi "Focusrite\|Vocaster"; then
    icon=""
    tooltip="Output: Vocaster One"
elif echo "$current_sink" | grep -qi "Logitech\|Z407"; then
    icon="󰓃"
    tooltip="Output: Logitech Speakers"
else
    # Fallback for other sinks
    icon="󱑽"
    tooltip="Output: $current_sink"
fi

# Output JSON for Waybar
echo "{\"text\":\"$icon\", \"tooltip\":\"$tooltip\"}"

