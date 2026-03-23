#!/usr/bin/env bash
# Monitor-relative workspace switcher
# Desktop (3 monitors) - each monitor has its own 1-9 workspaces:
#   Center (DP-3):    1-9
#   Left (HDMI-A-2): 11-19
#   Right (DP-2):    21-29
# Laptop/other - uses workspaces 1-9 directly (no offset)

ws_num="$1"
action="${2:-switch}"

# Get the currently focused monitor
focused_monitor=$(hyprctl activeworkspace -j | jq -r '.monitor')

# Calculate workspace offset based on monitor
# Unknown monitors (laptop eDP-1, etc.) default to offset 0
case "$focused_monitor" in
    "DP-3")
        offset=0
        ;;
    "HDMI-A-2")
        offset=10
        ;;
    "DP-2")
        offset=20
        ;;
    *)
        # Laptop or unknown monitor - use standard workspaces 1-9
        offset=0
        ;;
esac

target_ws=$((ws_num + offset))

if [[ "$action" == "move" ]]; then
    hyprctl dispatch movetoworkspace "$target_ws"
else
    hyprctl dispatch workspace "$target_ws"
fi
