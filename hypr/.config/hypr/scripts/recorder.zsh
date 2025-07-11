#!/bin/zsh

# Define output directory and filename format
OUTPUT_DIR="$HOME/Videos/Recordings"
FILENAME=$(date +%Y-%m-%d_%H-%M-%S).mp4
FULL_PATH="${OUTPUT_DIR}/${FILENAME}"

# Ensure the output directory exists
mkdir -p "$OUTPUT_DIR"

echo "Select the area to record..."

# Get geometry from slurp and pipe it to wf-recorder
geometry=$(slurp)

if [ -n "$geometry" ]; then
    echo "Recording selected area: $geometry to $FULL_PATH"
    wf-recorder -f "$FULL_PATH" --geometry "$geometry"
else
    echo "No area selected. Exiting."
fi
