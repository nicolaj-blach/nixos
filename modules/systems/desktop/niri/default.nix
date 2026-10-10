{ inputs, ... }:

{
  flake.nixosModules.niri = { pkgs, unstablePkgs, ... }: {
    programs.niri = {
      enable = true;
      # Temporary: unreleased main for multi-monitor portal screenshots; see AGENTS.md
      package = unstablePkgs.niri.overrideAttrs {
        version = "26.04-unstable-${inputs.niri-src.shortRev}";
        src = inputs.niri-src;
        cargoDeps = unstablePkgs.rustPlatform.fetchCargoVendor {
          src = inputs.niri-src;
          hash = "sha256-JJfJ8o5yuI8mfXDkEfdCVcqQpxIXICV3dji7HoLgKBI=";
        };
        doInstallCheck = false;
      };
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
