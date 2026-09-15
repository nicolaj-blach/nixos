{ ... }:

{
  flake.nixosModules.flameshot = { pkgs, ... }: {
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
    environment.systemPackages = with pkgs; [
      flameshot
      grim
      slurp
    ];
  };

  flake.homeManagerModules.flameshot =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.custom.flameshot;
      flameshot-wayland = pkgs.writeShellScriptBin "flameshot-wayland" ''
        export QT_QPA_PLATFORM=wayland
        export XDG_CURRENT_DESKTOP=Hyprland
        exec ${pkgs.flameshot}/bin/flameshot "$@"
      '';
      flameshotConfig = ''
        [General]
        disabledGrimWarning=true
        useGrimAdapter=true
        showStartupLaunchMessage=false
        startupLaunch=false
        showDesktopNotification=true
        savePath=${config.home.homeDirectory}/Pictures/Screenshots
        savePathFixed=false
        showHelp=false
        showSidePanelButton=false
      '';
    in
    {
      options.custom.flameshot = {
        enable = lib.mkEnableOption "Flameshot with Hyprland fixes";
        useGrimAdapter = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [
          pkgs.flameshot
          flameshot-wayland
          pkgs.grim
          pkgs.slurp
        ];
        xdg.configFile."flameshot/flameshot.ini".text = flameshotConfig;
        home.file."Pictures/Screenshots/.keep".text = "";

        custom.hyprland.windowRules.overlayClasses = [ "flameshot" ];

        wayland.windowManager.hyprland.settings.bind =
          lib.mkIf (config.wayland.windowManager.hyprland.enable or false)
            [ ", Print, exec, flameshot-wayland gui" ];

        programs.zsh.shellAliases = {
          screenshot = "flameshot-wayland gui";
          ss = "flameshot-wayland gui";
          ssf = "flameshot-wayland full";
          ssc = "flameshot-wayland gui -c";
        };
      };
    };
}
