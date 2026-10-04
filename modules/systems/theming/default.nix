{ ... }:

{
  flake.nixosModules.theming = { pkgs, lib, ... }: {

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

    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
    ];

    environment.systemPackages = with pkgs; [
      adwaita-icon-theme
      gnome-themes-extra
    ];
  };
}
