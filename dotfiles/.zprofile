# ~/.zprofile - Login shell init

# User scripts
export PATH="$HOME/.local/bin:$PATH"

# Auto-start Hyprland on tty1
if [[ -z $DISPLAY && $(tty) == /dev/tty1 ]]; then
  sleep 0.5  # allow systemd services to settle
  exec hyprland
fi
