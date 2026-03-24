#!/bin/bash
LOCKFILE="/tmp/waybar-cava.lock"
PIDFILE="/tmp/waybar-cava.pid"
PLAYER_STATE_FILE="/tmp/waybar-cava-playing"

cleanup() {
    pkill -P $$ 2>/dev/null
    rm -f "$PIDFILE" "$LOCKFILE" "$PLAYER_STATE_FILE"
    exit 0
}
trap cleanup EXIT INT TERM

pkill -9 -f "cava -p" 2>/dev/null
sleep 0.1

exec 9>"$LOCKFILE"
flock -n 9 || exit 1

if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE" 2>/dev/null)
    [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null && exit 1
fi
echo $$ > "$PIDFILE"

SINK=$(pactl get-default-sink 2>/dev/null)
SOURCE="${SINK:+${SINK}.monitor}"
[ -z "$SOURCE" ] && SOURCE=$(pactl list sources short | grep monitor | head -1 | awk '{print $2}')
[ -z "$SOURCE" ] && SOURCE="auto"

METHOD="pulse"
pgrep -x pipewire >/dev/null && METHOD="pipewire"

# Poll player state in background, write to file every 2s
# Much cheaper than spawning playerctl per-frame
player_watcher() {
    while true; do
        playing=""
        for p in $(playerctl -l 2>/dev/null); do
            [ "$(playerctl -p "$p" status 2>/dev/null)" = "Playing" ] && playing="yes" && break
        done
        echo "$playing" > "$PLAYER_STATE_FILE"
        sleep 2
    done
}
player_watcher &
WATCHER_PID=$!

silent=0

# stdbuf -oL forces line-buffered output from cava
stdbuf -oL cava -p <(cat <<EOFCAVA
[general]
bars = 8
framerate = 30
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
gravity = 500
noise_reduction = 55
EOFCAVA
) 2>/dev/null | while IFS= read -r line; do
    playing=$(cat "$PLAYER_STATE_FILE" 2>/dev/null)

    if [ -z "$playing" ]; then
        echo ""
        continue
    fi

    has_audio=""
    for v in $line; do
        [ "$v" -gt 0 ] 2>/dev/null && has_audio="yes" && break
    done

    if [ -n "$has_audio" ]; then
        silent=0
        out=""
        for v in $line; do
            case $v in
                0) out+="▁ ";; 1) out+="▂ ";; 2) out+="▃ ";;
                3) out+="▄ ";; 4) out+="▅ ";; 5) out+="▆ ";;
                6) out+="▇ ";; 7) out+="█ ";;
            esac
        done
        printf '%s\n' "$out"
    else
        ((silent++))
        [ $silent -ge 150 ] && printf '\n' || printf '▁ ▁ ▁ ▁ ▁ ▁ ▁ ▁ \n'
    fi
done

kill $WATCHER_PID 2>/dev/null
