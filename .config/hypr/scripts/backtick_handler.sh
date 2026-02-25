#!/usr/bin/env bash
# Backtick key handler script
# Dependencies: wl-clipboard, wtype

STATE_FILE="/tmp/backtick_state"
DOUBLE_PRESS_THRESHOLD=300
current_time=$(date +%s%3N)

# Check if there's a recent press
if [ -f "$STATE_FILE" ]; then
    last_time=$(cat "$STATE_FILE")
    time_diff=$((current_time - last_time))
    
    if [ $time_diff -lt $DOUBLE_PRESS_THRESHOLD ]; then
        # Double press detected - select all and copy
        wtype -M ctrl -k a -k c -m ctrl
        rm -f "$STATE_FILE"
        exit 0
    fi
fi

# Mark this press
echo "$current_time" > "$STATE_FILE"

# Wait to see if another press comes
sleep 0.3

# Check if another press happened during wait
if [ -f "$STATE_FILE" ]; then
    stored_time=$(cat "$STATE_FILE")
    if [ "$stored_time" = "$current_time" ]; then
        # No second press - do copy now
        wtype -M ctrl -P c -p c -m ctrl
        rm -f "$STATE_FILE"
    fi
fi
```

**Updated Hyprland bindings**:
```
bind = , grave, exec, ~/.config/hypr/scripts/backtick_handler.sh
bind = CTRL, grave, exec, wtype -M ctrl -P v -p v -m ctrl
bind = SHIFT, grave, exec, hyprctl dispatch exec "omarchy-launch-walker -m clipboard"
