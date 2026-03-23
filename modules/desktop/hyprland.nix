{ pkgs, inputs, ... }:

{
  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
    };

    hyprlock.enable = true;

    # Requires inputs.walker.nixosModules.default to be imported at the host level
    walker.enable = true;
  };

  # Load split-monitor-workspaces plugin at startup
  environment.systemPackages = [
    inputs.split-monitor-workspaces.packages.${pkgs.system}.split-monitor-workspaces
  ];

  security.pam.services.hyprlock.nodelay = true;
}
