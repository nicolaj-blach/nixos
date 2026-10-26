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

  # OneDark Pro menus and tooltips for GTK3 apps (Emacs context menu)
  flake.homeManagerModules.theming = {
    xdg.configFile."gtk-3.0/gtk.css".text = ''
      menu, .menu, .context-menu, tooltip, tooltip.background {
        background-color: #21252b;
        color: #abb2bf;
        border: 1px solid #3e4451;
        border-radius: 0;
        box-shadow: none;
        font-family: "JetBrainsMono Nerd Font";
      }
      menu, .menu, .context-menu { padding: 4px 0; }
      tooltip * { color: #abb2bf; }
      menu menuitem { padding: 4px 12px; border-radius: 0; }
      menu menuitem:hover { background-color: #3e4451; color: #abb2bf; }
      menu menuitem:disabled { color: #5c6370; }
      menu menuitem arrow, menu menuitem check, menu menuitem radio { color: #61afef; }
      menu separator { background-color: #3e4451; margin: 4px 0; min-height: 1px; }
      menu arrow { background: none; }
      window.popup, .csd.popup decoration { border-radius: 0; box-shadow: none; }
    '';
  };
}
