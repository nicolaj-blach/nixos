{ ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  programs.hyprlock.enable = true;
  security.pam.services.hyprlock.nodelay = true;

  # Requires inputs.walker.nixosModules.default to be imported at the host level
  programs.walker.enable = true;
}
