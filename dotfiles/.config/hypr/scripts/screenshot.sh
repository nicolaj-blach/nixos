#!/usr/bin/env bash

# Screenshot with flameshot: region select + annotate, save to ~/pictures/screenshots/{year}/{month}, copy to clipboard
dir="$HOME/pictures/screenshots/$(date +%Y)/$(date +%m)"
mkdir -p "$dir"
flameshot gui --path "$dir" --clipboard
