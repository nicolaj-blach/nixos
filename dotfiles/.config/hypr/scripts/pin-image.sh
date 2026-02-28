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

# Launch imv in the background
imv "$TMPFILE" &
IMV_PID=$!

# Wait for the imv window to appear, then float and pin it
for _ in $(seq 1 20); do
    sleep 0.1
    ADDR=$(hyprctl clients -j | jq -r ".[] | select(.pid == $IMV_PID) | .address")
    if [ -n "$ADDR" ]; then
        hyprctl --batch "dispatch togglefloating address:$ADDR; dispatch pin address:$ADDR; dispatch resizewindowpixel exact 30% 30%,address:$ADDR; dispatch movewindowpixel exact 68% 2%,address:$ADDR"
        break
    fi
done

# Wait for imv to close, then clean up
wait "$IMV_PID" 2>/dev/null
rm -f "$TMPFILE"
