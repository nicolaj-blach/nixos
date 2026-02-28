#!/usr/bin/env bash

# Screenshot: grim (capture) + slurp (region select) + satty (annotate)
# Saves to ~/pictures/screenshots/{year}/{month}, copies to clipboard

dir="$HOME/pictures/screenshots/$(date +%Y)/$(date +%m)"
mkdir -p "$dir"
filepath="$dir/$(date +%Y%m%d-%H%M%S).png"

# Select region, capture, then open annotation editor
grim -g "$(slurp)" - | satty --filename - --output-filename "$filepath" --copy-command "wl-copy"
