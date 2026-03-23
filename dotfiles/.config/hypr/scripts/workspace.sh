#!/usr/bin/env bash
# Dynamic monitor-relative workspace switcher
# Uses monitor x-position (left to right) to calculate workspace offset:
#   Leftmost monitor:  workspaces 1-9   (offset 0)
#   Center monitor:    workspaces 11-19 (offset 10)
#   Rightmost monitor: workspaces 21-29 (offset 20)
# Single monitor (laptop) uses offset 0

ws_num="$1"
action="${2:-switch}"

# Get the currently focused monitor
focused_monitor=$(hyprctl activeworkspace -j | jq -r '.monitor')

# Get monitor count
monitor_count=$(hyprctl monitors -j | jq 'length')

# Calculate offset based on x-position order (left to right)
if [[ "$monitor_count" -eq 1 ]]; then
    offset=0
else
    # Sort monitors by x-position and find index of focused monitor
    monitor_index=$(hyprctl monitors -j | jq -r --arg name "$focused_monitor" '
        sort_by(.x) | to_entries | .[] | select(.value.name == $name) | .key
    ')
    offset=$((monitor_index * 10))
fi

target_ws=$((ws_num + offset))

if [[ "$action" == "move" ]]; then
    hyprctl dispatch movetoworkspace "$target_ws"
else
    hyprctl dispatch workspace "$target_ws"
fi
