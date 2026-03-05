# ~/.zprofile - Login shell init

# User scripts
export PATH="$HOME/.local/bin:$PATH"

# Auto-start Hyprland on tty1
if [[ -z $DISPLAY && $(tty) == /dev/tty1 ]]; then
  exec hyprland
fi
