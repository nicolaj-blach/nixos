{ inputs, ... }:

{
  flake.nixosModules.ags =
    { lib, pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      topBar = inputs.ags-bar.packages.${system}.default;
      agsPackage = inputs.ags.packages.${system}.default;
      astalLibs = with inputs.astal.packages.${system}; [
        io
        astal4
        battery
        bluetooth
        wireplumber
        network
        hyprland
      ];
      typelibPath = lib.concatMapStringsSep ":" (l: "${l}/lib/girepository-1.0") astalLibs;
    in
    {
      services.upower.enable = true;
      environment.sessionVariables.GI_TYPELIB_PATH = typelibPath;
      environment.systemPackages = [
        topBar
        agsPackage
      ]
      ++ astalLibs;
    };

  flake.homeManagerModules.ags =
    { config, lib, ... }:
    let
      cfg = config.services.ags-bar;
      defaultColors = ''
        @define-color bar_bg #282c34;
        @define-color bar_fg #abb2bf;
        @define-color bar_border #3e4451;
        @define-color bar_accent #61afef;
        @define-color bar_accent2 #c678dd;
        @define-color bar_muted #545862;
        @define-color bar_red #e06c75;
        @define-color bar_green #98c379;
        @define-color bar_cyan #56b6c2;
        @define-color bar_orange #d19a66;
      '';
    in
    {
      options.services.ags-bar = {
        enable = lib.mkEnableOption "AGS Top Bar";
        autostart = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        colors = lib.mkOption {
          type = lib.types.lines;
          default = defaultColors;
        };
      };

      config = lib.mkIf cfg.enable {
        xdg.configFile."ags/colors.css".text = cfg.colors;

        wayland.windowManager.hyprland.settings.exec-once = lib.mkIf (
          cfg.autostart && (config.wayland.windowManager.hyprland.enable or false)
        ) [ "top-bar" ];

        programs.zsh.shellAliases = {
          bar = "pkill -9 gjs; sleep 0.5; top-bar & disown";
          bar-kill = "pkill -9 gjs";
        };
      };
    };
}
