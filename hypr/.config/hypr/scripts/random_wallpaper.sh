#!/bin/bash
#
# Optimized wallpaper randomizer for Hyprland
# Dynamic monitor detection, efficient wallpaper selection

# --- CONFIGURATION ---
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
ANIMATED_DIR_NAME="animated"
CHANCE_FOR_ANIMATED=10
LOCK_FILE="$HOME/.config/hypr/wallpaper_lock"
MAX_RETRIES=10
HYPRPAPER_TIMEOUT=10

# --- GLOBALS ---
declare -a STATIC_WALLPAPERS
declare -a ANIMATED_WALLPAPERS
declare -a MONITORS

# --- FUNCTIONS ---
log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

error_exit() {
    log "ERROR: $1"
    cleanup_and_exit 1
}

cleanup_and_exit() {
    rm -f "$LOCK_FILE"
    exit "${1:-0}"
}

# Get monitors dynamically and cache the result
get_monitors() {
    log "Detecting monitors..."
    
    # Get monitor names from hyprctl
    mapfile -t MONITORS < <(hyprctl monitors -j | jq -r '.[].name' 2>/dev/null)
    
    # Fallback if jq fails or no monitors found
    if [ "${#MONITORS[@]}" -eq 0 ]; then
        log "jq failed or no monitors, trying grep method"
        mapfile -t MONITORS < <(hyprctl monitors | grep "Monitor" | awk '{print $2}')
    fi
    
    # Ultimate fallback to common monitor names
    if [ "${#MONITORS[@]}" -eq 0 ]; then
        log "Warning: No monitors detected, using fallback names"
        MONITORS=("DP-1" "HDMI-A-1")
    fi
    
    log "Found ${#MONITORS[@]} monitor(s): ${MONITORS[*]}"
}

# Efficiently collect all wallpapers in one pass
collect_wallpapers() {
    log "Collecting wallpapers..."
    
    local static_count=0
    local animated_count=0
    
    # Clear arrays
    STATIC_WALLPAPERS=()
    ANIMATED_WALLPAPERS=()
    
    # Process all directories in one loop
    for dir in "$WALLPAPER_DIR"/*/; do
        [ -d "$dir" ] || continue
        
        local dirname=$(basename "$dir")
        
        if [ "$dirname" = "$ANIMATED_DIR_NAME" ]; then
            # Collect animated files
            for file in "$dir"*.{mp4,gif}; do
                [ -f "$file" ] && ANIMATED_WALLPAPERS+=("$file") && ((animated_count++))
            done
        else
            # Collect static files
            for file in "$dir"*.{png,jpg,jpeg,webp}; do
                [ -f "$file" ] && STATIC_WALLPAPERS+=("$file") && ((static_count++))
            done
        fi
    done
    
    log "Collected $static_count static and $animated_count animated wallpapers"
    
    # Validate we have wallpapers
    if [ "${#STATIC_WALLPAPERS[@]}" -eq 0 ] && [ "${#ANIMATED_WALLPAPERS[@]}" -eq 0 ]; then
        error_exit "No wallpapers found in $WALLPAPER_DIR"
    fi
}

# Optimized wallpaper selection with better randomness
select_wallpapers() {
    local selected_wallpapers=()
    local use_animated=false
    
    # Decide on animated wallpaper usage
    if [ "${#ANIMATED_WALLPAPERS[@]}" -gt 0 ] && [ $((RANDOM % 100)) -lt "$CHANCE_FOR_ANIMATED" ]; then
        use_animated=true
        # Log to stderr so it doesn't interfere with output
        log "Including animated wallpaper (${CHANCE_FOR_ANIMATED}% chance)" >&2
    fi
    
    # Select wallpapers based on number of monitors
    local num_monitors=${#MONITORS[@]}
    
    if $use_animated && [ "${#STATIC_WALLPAPERS[@]}" -gt 0 ]; then
        # Mix: one animated + static wallpapers
        selected_wallpapers+=("${ANIMATED_WALLPAPERS[$((RANDOM % ${#ANIMATED_WALLPAPERS[@]}))]}")
        
        # Fill remaining slots with static wallpapers
        for ((i=1; i<num_monitors; i++)); do
            selected_wallpapers+=("${STATIC_WALLPAPERS[$((RANDOM % ${#STATIC_WALLPAPERS[@]}))]}")
        done
    else
        # All static wallpapers
        if [ "${#STATIC_WALLPAPERS[@]}" -eq 0 ]; then
            log "ERROR: No static wallpapers available" >&2
            return 1
        fi
        
        # Select static wallpapers for all monitors
        for ((i=0; i<num_monitors; i++)); do
            selected_wallpapers+=("${STATIC_WALLPAPERS[$((RANDOM % ${#STATIC_WALLPAPERS[@]}))]}")
        done
    fi
    
    # Shuffle the selected wallpapers array for random monitor assignment
    local shuffled=()
    local temp_array=("${selected_wallpapers[@]}")
    
    while [ ${#temp_array[@]} -gt 0 ]; do
        local index=$((RANDOM % ${#temp_array[@]}))
        shuffled+=("${temp_array[$index]}")
        # Remove the selected element
        temp_array=("${temp_array[@]:0:$index}" "${temp_array[@]:$((index+1))}")
    done
    
    # REMOVED THE LOG STATEMENTS FROM HERE - they were causing the issue!
    
    printf '%s\n' "${shuffled[@]}"
}

# Wait for hyprpaper to be ready with timeout
wait_for_hyprpaper() {
    if pgrep -x "hyprpaper" > /dev/null; then
        log "hyprpaper is already running"
        return 0
    fi
    
    log "Starting hyprpaper daemon"
    hyprpaper &
    local hyprpaper_pid=$!
    
    # Wait for hyprpaper to be ready
    log "Waiting for hyprpaper to initialize..."
    local count=0
    while [ $count -lt $HYPRPAPER_TIMEOUT ]; do
        if hyprctl hyprpaper listloaded >/dev/null 2>&1; then
            log "hyprpaper is ready"
            return 0
        fi
        
        # Check if the process is still running
        if ! kill -0 $hyprpaper_pid 2>/dev/null; then
            error_exit "hyprpaper process died during startup"
        fi
        
        sleep 1
        ((count++))
    done
    
    log "Warning: hyprpaper initialization timeout, continuing anyway"
    return 1
}

# Optimized wallpaper application with better error handling
apply_wallpaper() {
    local monitor=$1
    local wallpaper=$2
    
    if [ -z "$wallpaper" ]; then
        log "No wallpaper specified for $monitor"
        return 0
    fi

    local extension="${wallpaper##*.}"
    local filename=$(basename "$wallpaper")
    
    log "Applying $filename to $monitor"

    case "$extension" in
        mp4|gif)
            # Animated wallpaper
            mpvpaper -o "--loop-file=inf --no-audio --hwdec=auto" "$monitor" "$wallpaper" >/dev/null 2>&1 &
            log "✓ Started animated wallpaper on $monitor"
            ;;
        png|jpg|jpeg|webp)
            # Static wallpaper with error handling
            if hyprctl hyprpaper preload "$wallpaper" >/dev/null 2>&1; then
                if hyprctl hyprpaper wallpaper "$monitor,$wallpaper" >/dev/null 2>&1; then
                    log "✓ Set static wallpaper on $monitor"
                else
                    log "✗ Failed to set wallpaper on $monitor"
                    return 1
                fi
            else
                log "✗ Failed to preload $filename"
                return 1
            fi
            ;;
        *)
            log "✗ Unsupported file type: $extension"
            return 1
            ;;
    esac
    
    return 0
}

# --- MAIN SCRIPT ---
# Prevent concurrent runs
if [ -f "$LOCK_FILE" ]; then
    log "Another instance is running, exiting"
    exit 0
fi

# Set up cleanup trap
touch "$LOCK_FILE"
trap 'cleanup_and_exit' EXIT INT TERM

log "=== Starting Wallpaper Randomizer ==="

# Initialize system
get_monitors
collect_wallpapers

# Show summary
log "Configuration: ${#MONITORS[@]} monitor(s), ${#STATIC_WALLPAPERS[@]} static, ${#ANIMATED_WALLPAPERS[@]} animated wallpapers"

# Prepare hyprpaper
wait_for_hyprpaper

# Clean up old animated wallpapers
log "Cleaning up old processes"
pkill mpvpaper 2>/dev/null || true
sleep 0.3

# Select and apply wallpapers
log "Selecting wallpapers..."
mapfile -t selected < <(select_wallpapers)

# Add the logging here instead
log "Selected wallpapers:"
for ((i=0; i<${#MONITORS[@]}; i++)); do
    if [ -n "${selected[$i]}" ]; then
        log "  ${MONITORS[$i]}: $(basename "${selected[$i]}")"
    fi
done

log "Applying wallpapers..."success_count=0
for ((i=0; i<${#MONITORS[@]}; i++)); do
    if apply_wallpaper "${MONITORS[$i]}" "${selected[$i]}"; then
        ((success_count++))
    fi
done

# Cleanup unused preloaded images
if [ $success_count -gt 0 ]; then
    hyprctl hyprpaper unload unused >/dev/null 2>&1 || true
    log "✓ Wallpaper update complete! ($success_count/${#MONITORS[@]} monitors updated)"
else
    log "✗ No wallpapers were successfully applied"
    cleanup_and_exit 1
fi

log "=== Wallpaper Randomizer Finished ==="
