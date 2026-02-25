#!/bin/bash

STATE_FILE="/tmp/waybar-minimal"

if [ -f "$STATE_FILE" ]; then
    rm "$STATE_FILE"
else
    touch "$STATE_FILE"
fi

pkill -SIGUSR2 waybar
