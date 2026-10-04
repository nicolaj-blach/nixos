{ ... }:

{
  flake.nixosModules.niri = { pkgs, ... }: {
    programs.niri = {
      enable = true;
    };

    # XDG portal for screen sharing, file dialogs, etc.
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gnome
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-termfilechooser
      ];
      config.niri = {
        default = [
          "gnome"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Access" = "gtk";
        "org.freedesktop.impl.portal.Notification" = "gtk";
        "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
        "org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
      };
    };

    # Enable xwayland for X11 app compatibility
    environment.systemPackages = with pkgs; [
      xwayland-satellite
    ];
  };
}
