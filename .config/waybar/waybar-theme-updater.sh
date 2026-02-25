#!/bin/bash
# Simple Waybar Theme Updater
# Applies your template structure to all themes with proper colors
THEMES_DIR="$HOME/.config/omarchy/themes"
TEMPLATE_FILE="$HOME/.config/waybar/style-template.css"
# Check if template exists
if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "Error: Template file not found at $TEMPLATE_FILE"
  exit 1
fi
# Define colors for each theme (format: bg_color|border_color|foreground|muted_color|active_workspace|active_text)
declare -A THEME_COLORS
THEME_COLORS[gruvbox]="rgba(40, 40, 40, 0.8)|#d5c4a1|#ebdbb2|#fb4934|rgba(213, 196, 161, 0.3)|#83a598"
THEME_COLORS[catppuccin]="rgba(30, 30, 46, 0.8)|#cba6f7|#cdd6f4|#f38ba8|rgba(203, 166, 247, 0.3)|#89b4fa"
THEME_COLORS[catppuccin-latte]="rgba(239, 241, 245, 0.9)|#8839ef|#1a1a1a|#d20f39|rgba(136, 57, 239, 0.3)|#1e66f5"
THEME_COLORS[everforest]="rgba(45, 50, 40, 0.8)|#a7c080|#d3c6aa|#e67e80|rgba(167, 192, 128, 0.3)|#7fbbb3"
THEME_COLORS[flexoki-light]="rgba(240, 235, 227, 0.9)|#879a39|#100f0f|#d14d41|rgba(135, 154, 57, 0.3)|#4385be"
THEME_COLORS[kanagawa]="rgba(31, 31, 40, 0.8)|#957fb8|#dcd7ba|#e82424|rgba(149, 127, 184, 0.3)|#7e9cd8"
THEME_COLORS[matte-black]="rgba(20, 20, 20, 0.8)|#666666|#d0d0d0|#ff5555|rgba(102, 102, 102, 0.3)|#4a9eff"
THEME_COLORS[nord]="rgba(46, 52, 64, 0.8)|#88c0d0|#eceff4|#bf616a|rgba(136, 192, 208, 0.3)|#88c0d0"
THEME_COLORS[osaka-jade]="rgba(28, 28, 38, 0.8)|#9ece6a|#a9b1d6|#f7768e|rgba(158, 206, 106, 0.3)|#7aa2f7"
THEME_COLORS[ristretto]="rgba(35, 33, 31, 0.8)|#8c7a6a|#ddc7a1|#ea6962|rgba(140, 122, 106, 0.3)|#7daea3"
THEME_COLORS[rose-pine]="rgba(35, 33, 54, 0.8)|#c4a7e7|#e0def4|#eb6f92|rgba(196, 167, 231, 0.3)|#9ccfd8"
THEME_COLORS[tokyo-night]="rgba(26, 27, 38, 0.8)|#7aa2f7|#a9b1d6|#f7768e|rgba(122, 162, 247, 0.3)|#7aa2f7"
echo "🎨 Updating waybar themes from template..."
echo
# Process each theme
for theme_dir in "$THEMES_DIR"/*; do
  if [ ! -d "$theme_dir" ]; then
    continue
  fi
  
  theme_name=$(basename "$theme_dir")
  output_file="$theme_dir/waybar.css"
  
  # Get colors for this theme
  colors="${THEME_COLORS[$theme_name]}"
  
  if [ -z "$colors" ]; then
    echo "⚠ Skipping $theme_name (no colors defined)"
    continue
  fi
  
  # Parse colors
  IFS='|' read -r bg_color border_color foreground muted_color active_workspace active_text <<< "$colors"
  
  echo "✨ Updating $theme_name..."
  
  # Create the themed CSS file
  cat > "$output_file" << EOF
/* Theme: $theme_name */
/* Generated from template: $(date) */
/* Color Variables */
@define-color bg_color $bg_color;
@define-color border_color $border_color;
@define-color foreground $foreground;
@define-color muted_color $muted_color;
@define-color active_workspace $active_workspace;
@define-color active_text $active_text;
@define-color background $bg_color;
EOF
  
  # Append template content
  cat "$TEMPLATE_FILE" >> "$output_file"
  
  echo "  ✓ Created $output_file"
done
echo
echo "✅ All themes updated!"
echo "💡 Switch themes with: omarchy-theme-set <theme-name>"

# Reload waybar
killall waybar
sleep 1
waybar &
