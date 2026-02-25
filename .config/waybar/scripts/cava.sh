#!/bin/bash

LOCKFILE="/tmp/waybar-cava.lock"
PIDFILE="/tmp/waybar-cava.pid"

cleanup() {
    pkill -P $$ 2>/dev/null
    rm -f "$PIDFILE" "$LOCKFILE"
    exit 0
}

trap cleanup EXIT INT TERM

# Kill existing cava
pkill -9 -f "cava -p" 2>/dev/null
sleep 0.2

# Try lock
exec 9>"$LOCKFILE"
flock -n 9 || exit 1

# Check PID
if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE" 2>/dev/null)
    [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null && exit 1
fi

echo $$ > "$PIDFILE"

# Detect source
SINK=$(pactl get-default-sink 2>/dev/null)
SOURCE="${SINK:+${SINK}.monitor}"
[ -z "$SOURCE" ] && SOURCE=$(pactl list sources short | grep monitor | head -1 | awk '{print $2}')
[ -z "$SOURCE" ] && SOURCE="auto"

# Detect method
METHOD="pulse"
pgrep -x pipewire >/dev/null && METHOD="pipewire"

# Run cava
silent=0
cava -p <(cat <<EOFCAVA
[general]
bars = 8
framerate = 60
lower_cutoff_freq = 50
higher_cutoff_freq = 10000

[input]
method = $METHOD
source = $SOURCE

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
bar_delimiter = 32

[smoothing]
monstercat = 1
waves = 0
gravity = 150
noise_reduction = 65
EOFCAVA
) 2>/dev/null | while IFS= read -r line; do
    # Player check every 30 frames
    if [ $((silent % 30)) -eq 0 ]; then
        playing=""
        for p in $(playerctl -l 2>/dev/null); do
            [ "$(playerctl -p "$p" status 2>/dev/null)" = "Playing" ] && playing="yes" && break
        done
    fi
    
    [ -z "$playing" ] && echo "" && continue
    
    # Audio check
    has_audio=""
    for v in $line; do
        [ "$v" -gt 0 ] && has_audio="yes" && break
    done
    
    if [ -n "$has_audio" ]; then
        silent=0
        out=""
        for v in $line; do
            case $v in
                0) out+="▁ ";;
                1) out+="▂ ";;
                2) out+="▃ ";;
                3) out+="▄ ";;
                4) out+="▅ ";;
                5) out+="▆ ";;
                6) out+="▇ ";;
                7) out+="█ ";;
            esac
        done
        echo "$out"
    else
        ((silent++))
        [ $silent -ge 300 ] && echo "" || echo "▁ ▁ ▁ ▁ ▁ ▁ ▁ ▁ "
    fi
done
