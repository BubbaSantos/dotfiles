#!/bin/bash

# Get current mako mode
MODE=$(makoctl mode)

# Output JSON based on mode
if [ "$MODE" = "do-not-disturb" ]; then
    echo '{"class":"dnd-active","text":"󰂛"}'
else
    echo '{"class":"dnd-inactive","text":"󰂚"}'
fi
