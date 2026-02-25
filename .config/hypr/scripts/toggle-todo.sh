#!/bin/bash
APP_CLASS="chrome-to-do.office.com__tasks_inbox-Profile_1"

if hyprctl clients -j | grep -q "\"class\": \"$APP_CLASS\""; then
    hyprctl dispatch togglespecialworkspace todo
else
    hyprctl dispatch exec "[workspace special:todo silent]" "google-chrome-stable --profile-directory='Profile 1' --app=https://to-do.office.com/tasks/inbox"
fi
