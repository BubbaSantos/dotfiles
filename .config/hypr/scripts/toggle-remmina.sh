#!/bin/bash
if hyprctl clients | grep -q "class: org.remmina.Remmina"; then
    hyprctl dispatch togglespecialworkspace remmina
else
    remmina &
    sleep 0.5
    hyprctl dispatch togglespecialworkspace remmina
fi
