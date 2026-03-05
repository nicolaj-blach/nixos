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

  # Yazi as default file browser
  xdg.mime = {
    enable = true;
    defaultApplications = {
      "inode/directory" = "yazi.desktop";
      "text/html" = "zen.desktop";
      "x-scheme-handler/http" = "zen.desktop";
      "x-scheme-handler/https" = "zen.desktop";
      "text/plain" = "nvim.desktop";
    };
  };
environment = {
  # Dark theme for GTK apps (Adwaita-dark)
  systemPackages = with pkgs; [
    adwaita-icon-theme
    gnome-themes-extra
  ];

  etc."xdg/applications/yazi.desktop".text = ''
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

  etc."xdg/applications/nvim.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Neovim
    Comment=Terminal text editor
    Exec=ghostty -e nvim %F
    Icon=nvim
    Terminal=false
    Categories=Utility;TextEditor;
    MimeType=text/plain;
  '';
};

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
