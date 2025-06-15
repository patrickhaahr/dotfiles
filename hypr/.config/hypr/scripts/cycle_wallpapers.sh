#!/bin/bash

# Directory containing wallpapers
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
LOCK_FILE="$HOME/.config/hypr/wallpaper_lock"

# Wallpaper sets: main monitor, second monitor
SET1_MAIN="2.png"
SET1_SECOND="1.png"
SET2_MAIN="law.webp"
SET2_SECOND="shanks.jpg"

# State file to track current set
STATE_FILE="$HOME/.config/hypr/wallpaper_state"

# Check for lock file to prevent concurrent runs
if [ -f "$LOCK_FILE" ]; then
    exit 0
fi
touch "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"; exit' EXIT INT TERM

# Check if hyprctl is installed
if ! command -v hyprctl &> /dev/null; then
    exit 1
fi

# Check if wallpapers exist
for wp in "$SET1_MAIN" "$SET1_SECOND" "$SET2_MAIN" "$SET2_SECOND"; do
    if [ ! -f "$WALLPAPER_DIR/$wp" ]; then
        exit 1
    fi
done

# Ensure hyprpaper is running
if ! pgrep -x "hyprpaper" > /dev/null; then
    hyprpaper &
    sleep 1
fi

# Read current state or default to 0
if [ -f "$STATE_FILE" ]; then
    CURRENT_STATE=$(cat "$STATE_FILE")
else
    CURRENT_STATE=0
fi

# Determine next state (0 or 1)
NEXT_STATE=$(( (CURRENT_STATE + 1) % 2 ))

# Get monitor names dynamically
MONITORS=($(hyprctl monitors | grep "Monitor" | awk '{print $2}'))
MAIN_MONITOR=${MONITORS[0]:-DP-1}
SECOND_MONITOR=${MONITORS[1]:-HDMI-A-1}

# Apply wallpapers based on state
if [ "$NEXT_STATE" -eq 0 ]; then
    # Set 1: 1.png (main), 2.png (second)
    hyprctl hyprpaper preload "$WALLPAPER_DIR/$SET1_MAIN"
    hyprctl hyprpaper preload "$WALLPAPER_DIR/$SET1_SECOND"
    hyprctl hyprpaper wallpaper "$MAIN_MONITOR,$WALLPAPER_DIR/$SET1_MAIN"
    hyprctl hyprpaper wallpaper "$SECOND_MONITOR,$WALLPAPER_DIR/$SET1_SECOND"
else
    # Set 2: shanks.jpg (main), law.webp (second)
    hyprctl hyprpaper preload "$WALLPAPER_DIR/$SET2_MAIN"
    hyprctl hyprpaper preload "$WALLPAPER_DIR/$SET2_SECOND"
    hyprctl hyprpaper wallpaper "$MAIN_MONITOR,$WALLPAPER_DIR/$SET2_MAIN"
    hyprctl hyprpaper wallpaper "$SECOND_MONITOR,$WALLPAPER_DIR/$SET2_SECOND"
fi

# Save the next state
echo "$NEXT_STATE" > "$STATE_FILE"
