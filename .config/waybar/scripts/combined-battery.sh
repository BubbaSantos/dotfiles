#!/bin/bash

# State file to track display mode
STATE_FILE="/tmp/waybar-battery-mode"

# Initialize state file if it doesn't exist
if [ ! -f "$STATE_FILE" ]; then
    echo "percentage" > "$STATE_FILE"
fi

# Read current mode
MODE=$(cat "$STATE_FILE")

# Get battery values
BAT0_NOW=$(cat /sys/class/power_supply/BAT0/energy_now 2>/dev/null || echo 0)
BAT0_FULL=$(cat /sys/class/power_supply/BAT0/energy_full 2>/dev/null || echo 1)
BAT1_NOW=$(cat /sys/class/power_supply/BAT1/energy_now 2>/dev/null || echo 0)
BAT1_FULL=$(cat /sys/class/power_supply/BAT1/energy_full 2>/dev/null || echo 1)

# Calculate individual percentages
BAT0_PCT=$((BAT0_NOW * 100 / BAT0_FULL))
BAT1_PCT=$((BAT1_NOW * 100 / BAT1_FULL))

# Calculate combined percentage (weighted by capacity)
TOTAL_NOW=$((BAT0_NOW + BAT1_NOW))
TOTAL_FULL=$((BAT0_FULL + BAT1_FULL))
COMBINED_PCT=$((TOTAL_NOW * 100 / TOTAL_FULL))

# Get charging status and power consumption
AC_STATUS=$(cat /sys/class/power_supply/A*/online 2>/dev/null | head -1)
POWER=$(cat /sys/class/power_supply/BAT*/power_now 2>/dev/null | awk '{sum+=$1} END {print sum/1000000}')

# Calculate time remaining (in hours)
if [ "$AC_STATUS" = "1" ]; then
  STATUS="charging"
  ICON=""
  # Time to full charge
  if [ "$POWER" != "0" ] && [ -n "$POWER" ]; then
    ENERGY_NEEDED=$((TOTAL_FULL - TOTAL_NOW))
    TIME_HOURS=$(echo "scale=1; $ENERGY_NEEDED / ($POWER * 1000000)" | bc 2>/dev/null)
    if [ -n "$TIME_HOURS" ] && [ "$TIME_HOURS" != "0" ]; then
      HOURS=$(echo "$TIME_HOURS" | cut -d. -f1)
      MINUTES=$(echo "scale=0; ($TIME_HOURS - $HOURS) * 60 / 1" | bc 2>/dev/null)
      TIME_REMAINING="${HOURS}h ${MINUTES}m"
    else
      TIME_REMAINING="Calculating..."
    fi
  else
    TIME_REMAINING="Fully charged"
  fi
else
  STATUS="discharging"
  # Time until empty
  if [ "$POWER" != "0" ] && [ -n "$POWER" ]; then
    TIME_HOURS=$(echo "scale=1; $TOTAL_NOW / ($POWER * 1000000)" | bc 2>/dev/null)
    if [ -n "$TIME_HOURS" ]; then
      HOURS=$(echo "$TIME_HOURS" | cut -d. -f1)
      MINUTES=$(echo "scale=0; ($TIME_HOURS - $HOURS) * 60 / 1" | bc 2>/dev/null)
      TIME_REMAINING="${HOURS}h ${MINUTES}m"
    else
      TIME_REMAINING="Calculating..."
    fi
  else
    TIME_REMAINING="Unknown"
  fi
  
  # Choose icon based on percentage
  if [ $COMBINED_PCT -le 10 ]; then
    ICON=""
  elif [ $COMBINED_PCT -le 20 ]; then
    ICON=""
  elif [ $COMBINED_PCT -le 30 ]; then
    ICON=""
  elif [ $COMBINED_PCT -le 40 ]; then
    ICON=""
  elif [ $COMBINED_PCT -le 50 ]; then
    ICON=""
  elif [ $COMBINED_PCT -le 60 ]; then
    ICON=""
  elif [ $COMBINED_PCT -le 70 ]; then
    ICON=""
  elif [ $COMBINED_PCT -le 80 ]; then
    ICON=""
  elif [ $COMBINED_PCT -le 90 ]; then
    ICON=""
  else
    ICON=""
  fi
fi

# Add notification logic based on combined percentage
NOTIFICATION_SENT_FILE="/tmp/battery_notification_sent"
LOW_THRESHOLD=20
CRITICAL_THRESHOLD=10

# Only send notifications when discharging
if [ "$STATUS" = "discharging" ]; then
  if [ $COMBINED_PCT -le $CRITICAL_THRESHOLD ]; then
    if [ ! -f "${NOTIFICATION_SENT_FILE}_critical" ]; then
      notify-send -u critical "Critical Battery!" "Battery is critically low at ${COMBINED_PCT}%" -t 0
      touch "${NOTIFICATION_SENT_FILE}_critical"
      rm -f "${NOTIFICATION_SENT_FILE}_low"
    fi
  elif [ $COMBINED_PCT -le $LOW_THRESHOLD ]; then
    if [ ! -f "${NOTIFICATION_SENT_FILE}_low" ]; then
      notify-send -u normal "Low Battery" "Time to recharge! Battery is down to ${COMBINED_PCT}%" -t 0
      touch "${NOTIFICATION_SENT_FILE}_low"
    fi
    rm -f "${NOTIFICATION_SENT_FILE}_critical"
  else
    rm -f "${NOTIFICATION_SENT_FILE}_low" "${NOTIFICATION_SENT_FILE}_critical"
  fi
else
  rm -f "${NOTIFICATION_SENT_FILE}_low" "${NOTIFICATION_SENT_FILE}_critical"
fi

# Determine CSS class based on percentage and status
if [ "$STATUS" = "charging" ]; then
  CLASS="charging"
elif [ $COMBINED_PCT -le 10 ]; then
  CLASS="critical"
elif [ $COMBINED_PCT -le 20 ]; then
  CLASS="warning"
else
  CLASS="discharging"
fi

# Build display text based on mode
if [ "$MODE" = "percentage" ]; then
  DISPLAY_TEXT="$COMBINED_PCT% $ICON"
else
  DISPLAY_TEXT="$TIME_REMAINING $ICON"
fi

# Output JSON for waybar
echo "{\"text\": \"$DISPLAY_TEXT\", \"tooltip\": \"Combined: $COMBINED_PCT%\\nTime remaining: $TIME_REMAINING\\nBAT0 (Internal): $BAT0_PCT%\\nBAT1 (Removable): $BAT1_PCT%\\nPower: ${POWER}W\", \"class\": \"$CLASS\", \"percentage\": $COMBINED_PCT}"
