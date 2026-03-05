# ~/.zprofile - Login shell init
# Auto-start Hyprland on tty1
if [[ -z $DISPLAY && $(tty) == /dev/tty1 ]]; then
  exec hyprland
fi
