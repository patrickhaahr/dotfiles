#!/bin/zsh

# This script creates a HIGH-QUALITY GIF of a selected screen area, saves it
# to a permanent location, and copies the FILE PATH to the clipboard.

# --- Configuration ---
DURATION=8
# The final GIFs will be saved here.
CAPTURE_DIR="$HOME/Pictures/GIF-Captures"

# --- Secure Temporary Files ---
# These are intermediate files that will be cleaned up.
TEMP_VIDEO=$(mktemp /tmp/screenrecord-XXXXXX.mp4)
PALETTE=$(mktemp /tmp/palette-XXXXXX.png)

# --- Cleanup ---
# This trap ensures the intermediate video and palette are always deleted.
trap 'rm -f "$TEMP_VIDEO" "$PALETTE"' EXIT

# --- Script Start ---
# Ensure the destination directory exists
mkdir -p "$CAPTURE_DIR"

# 1. Select area with slurp
notify-send "GIF Capture" "Select an area to record..."
GEOMETRY=$(slurp)
if [ -z "$GEOMETRY" ]; then exit 1; fi

# 2. Record a high-quality video
notify-send "GIF Capture" "Recording..."
wf-recorder -y --codec libx264 -g "$GEOMETRY" -f "$TEMP_VIDEO" &
WF_PID=$!
sleep $DURATION
kill -INT $WF_PID
wait $WF_PID 2>/dev/null
sleep 0.5

# 3. Check if video was created
if [ ! -s "$TEMP_VIDEO" ]; then
	notify-send "GIF Capture Failed" "Recording failed."
	exit 1
fi

# 4. Convert to a High-Quality GIF
# The "Converting..." notification has been removed as requested.
FILENAME="capture-$(date +%F_%H-%M-%S).gif"
FINAL_GIF_PATH="$CAPTURE_DIR/$FILENAME"

# Redirect ffmpeg's verbose output to /dev/null to keep things clean.
# Pass 1: Generate a custom color palette.
ffmpeg -y -i "$TEMP_VIDEO" \
	-vf "fps=15,scale=640:-1:flags=lanczos,palettegen" "$PALETTE" \
	>/dev/null 2>&1

# Pass 2: Use the palette to create the final GIF.
ffmpeg -y -i "$TEMP_VIDEO" -i "$PALETTE" \
	-filter_complex "[0]fps=15,scale=640:-1[scaled];[scaled][1]paletteuse" \
	"$FINAL_GIF_PATH" >/dev/null 2>&1

# 5. Check if GIF was created
if [ ! -s "$FINAL_GIF_PATH" ]; then
	notify-send "GIF Capture Failed" "Conversion failed."
	exit 1
fi

# 6. Copy the FILE PATH to the clipboard
URI="file://$(realpath "$FINAL_GIF_PATH")"
echo -n "$URI" | wl-copy --type text/uri-list

# 7. Notify user of success
# Using a newline character (\n) for formatting and adding a small sleep
# to ensure the notification has time to display before the script exits.
notify-send "GIF Capture" "Success! GIF saved and path copied.\nLocation: $FILENAME"
sleep 0.1
