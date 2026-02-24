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

  # Portal settings for apps that query the system color scheme (Electron, Firefox, etc.)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
