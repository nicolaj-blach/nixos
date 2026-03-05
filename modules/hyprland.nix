{ ... }:

{
programs = {
  hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  hyprlock.enable = true;

  # Requires inputs.walker.nixosModules.default to be imported at the host level
  walker.enable = true;
};
  security.pam.services.hyprlock.nodelay = true;
}
