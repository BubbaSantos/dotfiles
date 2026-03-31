#!/bin/bash
APP_CLASS="chrome-to-do.office.com__tasks_inbox-Default"
if hyprctl clients -j | grep -q "\"class\": \"$APP_CLASS\""; then
    hyprctl dispatch togglespecialworkspace todo
else
    hyprctl dispatch exec "[workspace special:todo silent]" "chromium --profile-directory='Default' --app=https://to-do.office.com/tasks/inbox"
    # Wait for the window to appear, then toggle to it
    for i in $(seq 1 20); do
        sleep 0.3
        if hyprctl clients -j | grep -q "\"class\": \"$APP_CLASS\""; then
            hyprctl dispatch togglespecialworkspace todo
            break
        fi
    done
fi
