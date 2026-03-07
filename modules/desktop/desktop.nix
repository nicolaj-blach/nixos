{ pkgs, lib, ... }:

{

  # Tell GTK apps to use dark mode via dconf
  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            gtk-theme = "Adwaita-dark";
            cursor-theme = "Adwaita";
            cursor-size = lib.gvariant.mkInt32 24;
          };
        };
      }
    ];
  };

  # Qt apps: follow GTK theme
  qt = {
    enable = true;
    platformTheme = "gtk2";
    style = "adwaita-dark";
  };

  environment.systemPackages = with pkgs; [
    adwaita-icon-theme
    gnome-themes-extra
  ];

  # Yazi as the file picker portal (used by browsers, etc.)
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-termfilechooser
    ];
    config.hyprland = {
      "org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
    };
  };
}
