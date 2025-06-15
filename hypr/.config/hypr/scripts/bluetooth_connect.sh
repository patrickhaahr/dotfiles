#!/bin/bash

# --- Configuration ---
# Source a local, untracked file for secrets.
# We check if the file exists before trying to source it.
if [ -f "$HOME/.local_secrets" ]; then
  source "$HOME/.local_secrets"
fi

# Validate that the variable was successfully loaded from the secrets file.
# The -z flag checks if the string is null (empty).
if [ -z "$SPEAKER_MAC_ADDR" ]; then
  echo "Error: SPEAKER_MAC_ADDR is not set or ~/.local_secrets is missing." >&2
  exit 1
fi

MAX_ATTEMPTS=5
ATTEMPT=1

# --- Script Logic ---
info() { echo "[INFO] $1"; }
fail() { echo "[FAIL] $1"; }

info "Ensuring Bluetooth is powered on..."
bluetoothctl power on

# Wait for Bluetooth service to settle
sleep 2

info "Starting connection attempts to device: $SPEAKER_MAC_ADDR"
while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
  # Check if the device is visible to bluetoothctl
  if bluetoothctl devices | grep -q "$SPEAKER_MAC_ADDR"; then
    info "Device found, attempting to connect (Attempt $ATTEMPT)..."
    if bluetoothctl connect "$SPEAKER_MAC_ADDR"; then
      info "Successfully connected to $SPEAKER_MAC_ADDR"
      exit 0
    else
      fail "Connection attempt $ATTEMPT failed."
    fi
  else
    fail "Device not found in scan (Attempt $ATTEMPT)."
  fi
  ATTEMPT=$((ATTEMPT + 1))
  sleep 2
done

fail "Failed to connect to $SPEAKER_MAC_ADDR after $MAX_ATTEMPTS attempts."
exit 1
