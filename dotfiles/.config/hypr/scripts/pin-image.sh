#!/usr/bin/env bash

# Pin clipboard image on screen using imv
# The image opens as a floating, pinned, always-on-top window

MIME=$(wl-paste --list-types 2>/dev/null | grep -m1 'image/')

if [ -z "$MIME" ]; then
    notify-send "Pin Image" "No image in clipboard" -t 2000
    exit 1
fi

TMPFILE=$(mktemp /tmp/pinned-image-XXXXXX.png)
wl-paste --type "$MIME" > "$TMPFILE"

if [ ! -s "$TMPFILE" ]; then
    notify-send "Pin Image" "Failed to read clipboard image" -t 2000
    rm -f "$TMPFILE"
    exit 1
fi

# Launch imv - window rules in windowrules.conf handle floating/pinning
# imv sets the title to the filename, which contains "pinned-image"
imv "$TMPFILE" &

# Clean up temp file after imv exits
IMV_PID=$!
(wait "$IMV_PID" 2>/dev/null; rm -f "$TMPFILE") &
