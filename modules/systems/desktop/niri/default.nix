{ ... }:

{
  flake.nixosModules.niri = { pkgs, ... }: {
    programs.niri = {
      enable = true;
    };

    # XDG portal for screen sharing, file dialogs, etc.
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    };

    # Enable xwayland for X11 app compatibility
    environment.systemPackages = with pkgs; [
      xwayland-satellite
    ];
  };
}
