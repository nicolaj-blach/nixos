{ pkgs, ... }:

{
  # Dark theme for GTK apps (Adwaita-dark)
  environment.systemPackages = with pkgs; [
    adwaita-icon-theme
    gnome-themes-extra
  ];

  # Tell GTK apps to use dark mode via dconf
  programs.dconf = {
    enable = true;
    profiles.user.databases = [
      {
        settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            gtk-theme = "Adwaita-dark";
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

  # Yazi as default file browser
  xdg.mime = {
    enable = true;
    defaultApplications = {
      "inode/directory" = "yazi.desktop";
    };
  };

  environment.etc."xdg/applications/yazi.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Yazi
    Comment=Terminal file manager
    Exec=ghostty -e yazi %u
    Icon=utilities-file-manager
    Terminal=false
    Categories=System;FileManager;
    MimeType=inode/directory;
  '';

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
