#!/usr/bin/env bash
# Backtick key handler script - universal copy/paste
# Single press: copy | Double press: select-all + copy
STATE_FILE="/tmp/backtick_state"
DOUBLE_PRESS_THRESHOLD=300

current_time=$(date +%s%3N)

# Universal copy: Ctrl+Insert works in terminals too (unlike Ctrl+C)
copy() {
    hyprctl dispatch sendshortcut "CTRL, Insert,"
}

# Select-all is genuinely Ctrl+A everywhere, including terminals' apps
select_all() {
    hyprctl dispatch sendshortcut "CTRL, A,"
}

# Check if there's a recent press
if [ -f "$STATE_FILE" ]; then
    last_time=$(cat "$STATE_FILE")
    time_diff=$((current_time - last_time))

    if [ "$time_diff" -lt "$DOUBLE_PRESS_THRESHOLD" ]; then
        # Double press detected - select all and copy
        select_all
        sleep 0.05
        copy
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
        copy
        rm -f "$STATE_FILE"
    fi
fi
