{ inputs, ... }:

{
  flake.nixosModules.otter-launcher = { ... }: { };

  flake.homeManagerModules.otter-launcher =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.otter-launcher;
      system = pkgs.stdenv.hostPlatform.system;
      otterConfig = ''
        [general]
        terminal_cmd = "${config.home.sessionVariables.TERMINAL or "kitty"} -e"

        [appearance]
        width = 40
        max_results = 10

        [search]
        applications = true
        files = false
        calculator = true
      '';
    in
    {
      options.programs.otter-launcher = {
        enable = lib.mkEnableOption "Otter Launcher";
        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.otter-launcher.packages.${system}.default;
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];
        xdg.configFile."otter-launcher/config.toml".text = otterConfig;

        custom.hyprland.windowRules.popupClasses = [ "otter-launcher" ];

        wayland.windowManager.hyprland.settings.bind =
          lib.mkIf (config.wayland.windowManager.hyprland.enable or false)
            [ "$mainMod, SPACE, exec, otter-launcher" ];

        programs.zsh.shellAliases.launcher = "otter-launcher";
      };
    };
}
