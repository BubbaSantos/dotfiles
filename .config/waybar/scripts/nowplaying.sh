#!/bin/bash
# State file to track hidden status
STATE_FILE="/tmp/waybar_nowplaying_hidden"

# Function to escape special characters for Pango markup
escape_text() {
  echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g'
}

# Function to escape special characters for JSON
escape_json() {
  echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/'"'"'/\\'"'"'/g'
}

# Check if hidden mode is enabled
if [ -f "$STATE_FILE" ]; then
  HIDDEN=true
else
  HIDDEN=false
fi

# Get the current player status
status=$(playerctl status 2>/dev/null)

if [ "$status" = "Playing" ] || [ "$status" = "Paused" ]; then
  # Get metadata
  artist=$(playerctl metadata artist 2>/dev/null)
  title=$(playerctl metadata title 2>/dev/null)
  album=$(playerctl metadata album 2>/dev/null)
  
  if [ -n "$artist" ] && [ -n "$title" ]; then
    # Escape special characters for display text (Pango markup)
    artist_escaped=$(escape_text "$artist")
    title_escaped=$(escape_text "$title")
    
    # Escape for JSON tooltip
    artist_json=$(escape_json "$artist")
    title_json=$(escape_json "$title")
    album_json=$(escape_json "$album")
    
    # Determine what to display based on hidden state
    if [ "$HIDDEN" = true ]; then
      # Hidden mode - show placeholder
      text="🎵 Playing"
      tooltip="Track hidden (middle-click to show)"
    else
      # Normal mode - show full info (title first, then artist)
      text="${title_escaped} - ${artist_escaped}"
      
      # Build tooltip with song, artist, album format
      tooltip="Song: ${title_json}\\nArtist: ${artist_json}"
      if [ -n "$album" ]; then
        tooltip="${tooltip}\\nAlbum: ${album_json}"
      fi
    fi
    
    # Build the JSON output - use printf for safety
    if [ "$status" = "Playing" ]; then
      printf '{"text":"%s","tooltip":"%s","class":"playing"}\n' "$text" "$tooltip"
    else
      printf '{"text":"⏸ %s","tooltip":"⏸ %s","class":"paused"}\n' "$text" "$tooltip"
    fi
  else
    echo '{"text":"","class":"stopped"}'
  fi
else
  echo '{"text":"","class":"stopped"}'
fi
