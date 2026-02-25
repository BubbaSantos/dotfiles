#!/bin/bash

# Get mako mode status
MODE=$(makoctl mode)

# Count pending notifications
COUNT=$(makoctl history | jq '[.[] | select(.dismissed == false)] | length' 2>/dev/null || echo 0)

if [ "$MODE" = "dnd" ]; then
  # DND mode active - show crossed out bell
  echo "{\"text\": \"\ ", \"class\": \"dnd-active\", \"tooltip\": \"Notifications disabled\"}"
else
  # Normal mode
  if [ "$COUNT" -gt 0 ]; then
    echo "{\"text\": \"\", \"class\": \"notification\", \"tooltip\": \"$COUNT notification(s)\"}"
  else
    echo "{\"text\": \"\", \"class\": \"normal\", \"tooltip\": \"No notifications\"}"
  fi
fi
