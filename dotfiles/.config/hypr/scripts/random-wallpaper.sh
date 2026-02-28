#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/.config/wallpapers"

WALLPAPER=$(find -L "$WALLPAPER_DIR" -type f \( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.webp' \) | shuf -n 1)

if [ -n "$WALLPAPER" ]; then
    swww img "$WALLPAPER"
fi
