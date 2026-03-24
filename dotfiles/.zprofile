# ~/.zprofile - Login shell init

# User scripts
export PATH="$HOME/.local/bin:$PATH"

# Auto-start Hyprland on tty1 via uwsm for proper session management
if [[ -z $DISPLAY && $(tty) == /dev/tty1 ]]; then
  exec start-hyprland
fi
