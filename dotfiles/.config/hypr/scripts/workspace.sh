#!/usr/bin/env bash
# Dynamic monitor-relative workspace switcher
# Uses monitor index to calculate workspace offset:
#   Monitor 0: workspaces 1-9   (offset 0)
#   Monitor 1: workspaces 11-19 (offset 10)
#   Monitor 2: workspaces 21-29 (offset 20)
# Single monitor (laptop) uses offset 0

ws_num="$1"
action="${2:-switch}"

# Get the currently focused monitor
focused_monitor=$(hyprctl activeworkspace -j | jq -r '.monitor')

# Get monitor count and index
monitor_count=$(hyprctl monitors -j | jq 'length')
monitor_index=$(hyprctl monitors -j | jq -r --arg name "$focused_monitor" 'to_entries | .[] | select(.value.name == $name) | .key')

# Calculate offset: single monitor = 0, otherwise index * 10
if [[ "$monitor_count" -eq 1 ]]; then
    offset=0
else
    offset=$((monitor_index * 10))
fi

target_ws=$((ws_num + offset))

if [[ "$action" == "move" ]]; then
    hyprctl dispatch movetoworkspace "$target_ws"
else
    hyprctl dispatch workspace "$target_ws"
fi
