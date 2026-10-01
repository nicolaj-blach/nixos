{ inputs, ... }:

{
  flake.nixosModules.zen-browser = { ... }: { };

  flake.homeManagerModules.zen-browser =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.zen-browser;
      system = pkgs.stdenv.hostPlatform.system;
    in
    {
      options.programs.zen-browser = {
        enable = lib.mkEnableOption "Zen Browser";
        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.zen-browser.packages.${system}.beta.override {
            extraPolicies.Preferences = {
              # Use the xdg portal file picker (yazi) and ask where to save downloads
              "widget.use-xdg-desktop-portal.file-picker" = {
                Value = 1;
                Status = "default";
              };
              "browser.download.useDownloadDir" = {
                Value = false;
                Status = "default";
              };
            };
          };
        };
        setAsDefault = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];

        programs.zsh.shellAliases = {
          zen = "zen-beta";
          browser = "zen-beta";
          b = "zen-beta";
        };

        home.sessionVariables = lib.mkIf cfg.setAsDefault {
          BROWSER = "zen-beta";
        };

        wayland.windowManager.hyprland.settings.bind =
          lib.mkIf (config.wayland.windowManager.hyprland.enable or false)
            [ "$mainMod, B, exec, zen-beta" ];

        xdg.mimeApps.defaultApplications = lib.mkIf cfg.setAsDefault {
          "text/html" = "zen-beta.desktop";
          "x-scheme-handler/http" = "zen-beta.desktop";
          "x-scheme-handler/https" = "zen-beta.desktop";
          "x-scheme-handler/about" = "zen-beta.desktop";
          "x-scheme-handler/unknown" = "zen-beta.desktop";
        };
      };
    };
}
