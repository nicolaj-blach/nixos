{ inputs, ... }:

{
  flake.nixosModules.quickshell-bar =
    { pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
    in
    {
      services.upower.enable = true;

      environment.systemPackages = [
        inputs.quickshell-bar.packages.${system}.default
        inputs.quickshell-bar.packages.${system}.quickshell
      ];
    };

  flake.homeManagerModules.quickshell-bar =
    { config, lib, ... }:
    let
      cfg = config.services.quickshell-bar;
    in
    {
      options.services.quickshell-bar = {
        enable = lib.mkEnableOption "QuickShell top bar";
        autostart = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Start quickshell-bar automatically with niri";
        };
        systemMenuCommand = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Command run when left-clicking the monitor label";
        };
      };

      config = lib.mkIf cfg.enable {
        xdg.configFile."quickshell/config.json".text = builtins.toJSON {
          system_menu_cmd = cfg.systemMenuCommand;
        };

        xdg.configFile."niri/config.kdl".text = lib.mkIf cfg.autostart (
          lib.mkAfter ''
            spawn-at-startup "quickshell-bar"
          ''
        );
      };
    };
}
