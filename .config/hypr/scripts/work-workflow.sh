#!/bin/bash
# Work Workflow Script
# Opens applications in designated workspaces

SUPPRESS_FILE="$HOME/.cache/hypr-split-ratio-suppress"

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

touch "$SUPPRESS_FILE"

# Launch Vivaldi browser with Midas homepage
vivaldi https://midaspro.mab.org.uk/Midas.Homepage/ &
wait_for_window "vivaldi-stable"
hyprctl dispatch movetoworkspacesilent 1,class:vivaldi-stable

# Launch Outlook
uwsm app -- chromium --new-window --ozone-platform=wayland --app="https://outlook.office.com/mail" --profile-directory="Profile 1" --force-new-instance &
wait_for_window "chrome-outlook.office.com__mail-Profile_1"
hyprctl dispatch movetoworkspacesilent 2,class:chrome-outlook.office.com__mail-Profile_1

# Launch Teams for Linux
uwsm app -- /opt/teams-for-linux/teams-for-linux &
wait_for_window "teams-for-linux"
hyprctl dispatch movetoworkspacesilent 3,class:teams-for-linux

# Launch Notion
uwsm app -- chromium --new-window --ozone-platform=wayland --app="https://notion.so" --profile-directory="Profile 1" --force-new-instance &
wait_for_window "chrome-notion.so__-Profile_1"
hyprctl dispatch movetoworkspacesilent 4,class:chrome-notion.so__-Profile_1

rm -f "$SUPPRESS_FILE"

hyprctl dispatch workspace 1
notify-send "Work Workflow" "Applications launched" -t 3000
