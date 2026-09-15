{ inputs, ... }:

{
  flake.nixosModules.hyprland =
    { pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
    in
    {
      programs = {
        hyprland = {
          enable = true;
          xwayland.enable = true;
          withUWSM = true;
          package = inputs.hyprland.packages.${system}.hyprland;
          portalPackage = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
        };

        hyprlock.enable = true;
      };

      environment.systemPackages = [
        inputs.split-monitor-workspaces.packages.${system}.split-monitor-workspaces
      ];

      security.pam.services.hyprlock.nodelay = true;
    };
}
