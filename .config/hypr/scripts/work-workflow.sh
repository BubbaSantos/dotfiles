#!/bin/bash

# Work Workflow Script
# Opens applications in designated workspaces

# Function to wait for a window with specific class to appear
wait_for_window() {
    local class_pattern="$1"
    local max_wait=10
    local count=0
    
    while [ $count -lt $max_wait ]; do
        if hyprctl clients | grep -q "$class_pattern"; then
            return 0
        fi
        sleep 0.5
        ((count++))
    done
    return 1
}

# Launch Vivaldi browser with Midas homepage on workspace 1
hyprctl dispatch workspace 1
vivaldi https://midaspro.mab.org.uk/Midas.Homepage/ &
wait_for_window "class.*vivaldi"
sleep 0.1

# Launch Outlook on workspace 2
hyprctl dispatch workspace 2
uwsm app -- chromium --new-window --ozone-platform=wayland --app="https://outlook.office.com/mail" --force-new-instance &
wait_for_window "chrome-outlook.office.com"
sleep 0.1


# Launch Teams on workspace 3
hyprctl dispatch workspace 3
sleep 0.1
uwsm app -- chromium --new-window --ozone-platform=wayland --app="https://teams.microsoft.com" --force-new-instance &
wait_for_window "chrome-teams.microsoft.com"

# Launch Notion on workspace 4
hyprctl dispatch workspace 4
sleep 0.1
uwsm app -- chromium --new-window --ozone-platform=wayland --app="https://notion.so" --force-new-instance &
wait_for_window "chrome-notion.so"

# Return to workspace 1
hyprctl dispatch workspace 1

# Send notification
notify-send "Work Workflow" "Applications launched" -t 3000
