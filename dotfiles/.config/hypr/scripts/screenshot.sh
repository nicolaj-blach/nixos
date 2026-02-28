#!/usr/bin/env bash

# Screenshot with flameshot: region select + annotate, save to ~/pictures/screenshots/{year}/{month}, copy to clipboard
# QT_SCREEN_SCALE_FACTORS fixes the zoomed-in issue with fractional Wayland scaling
dir="$HOME/pictures/screenshots/$(date +%Y)/$(date +%m)"
mkdir -p "$dir"
QT_SCREEN_SCALE_FACTORS="1" flameshot gui --path "$dir" --clipboard
