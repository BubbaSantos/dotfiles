#!/bin/bash
# Script to diagnose and fix multiple cava instances

echo "=== Checking for multiple cava instances ==="
echo

CAVA_COUNT=$(pgrep -c -f "cava")
echo "Number of cava processes running: $CAVA_COUNT"

if [ "$CAVA_COUNT" -gt 1 ]; then
    echo "⚠️  WARNING: Multiple cava instances detected!"
    echo
    echo "Processes:"
    ps aux | grep "[c]ava" | grep -v grep
    echo
    echo "Killing all cava instances..."
    pkill -9 -f "cava"
    sleep 1
    echo "✓ All cava instances killed"
else
    echo "✓ Only one or no cava instance running"
fi

echo
echo "=== Checking waybar config ==="
CONFIG_FILE="$HOME/.config/waybar/config.jsonc"

if [ -f "$CONFIG_FILE" ]; then
    echo "Config file: $CONFIG_FILE"
    echo
    echo "Current custom/cava settings:"
    sed -n '/"custom\/cava"/,/}/p' "$CONFIG_FILE"
    echo
    
    # Check for restart-interval
    if grep -q "restart-interval.*0" "$CONFIG_FILE"; then
        echo "✓ restart-interval is set to 0 (correct - won't auto-restart)"
    else
        echo "⚠️  restart-interval might cause issues"
    fi
else
    echo "Config file not found at $CONFIG_FILE"
fi

echo
echo "=== Recommended waybar config for cava ==="
cat << 'EOFCONFIG'
"custom/cava": {
  "exec": "~/.config/waybar/scripts/cava.sh",
  "format": "{}",
  "tooltip": false,
  "on-click": "playerctl play-pause",
  "on-click-right": "playerctl next",
  "on-click-middle": "ghostty -e wiremix",
  "on-scroll-up": "pamixer -i 2",
  "on-scroll-down": "pamixer -d 2",
  "restart-interval": 0
}
EOFCONFIG

echo
echo "=== Testing audio source ==="
DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null)
if [ -n "$DEFAULT_SINK" ]; then
    MONITOR="${DEFAULT_SINK}.monitor"
    echo "Default sink: $DEFAULT_SINK"
    echo "Monitor source: $MONITOR"
    
    # Verify it exists
    if pactl list sources short | grep -q "$MONITOR"; then
        echo "✓ Monitor source exists"
    else
        echo "⚠️  Monitor source not found"
        echo "Available monitor sources:"
        pactl list sources short | grep monitor
    fi
else
    echo "⚠️  Could not detect default sink"
fi

echo
echo "=== Quick Fix Commands ==="
echo "1. Kill all cava: pkill -9 cava"
echo "2. Reload waybar: killall waybar && waybar &"
echo "3. Check CPU usage: htop (filter by 'cava')"
echo
echo "If you still see multiple instances after reload, the issue is likely"
echo "in how waybar is starting the module. Check your waybar config."
