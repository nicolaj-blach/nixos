{ ... }:

{
  # Mako is started by niri (spawn-at-startup), so only the config is managed here
  flake.homeManagerModules.mako =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.custom.mako;
    in
    {
      options.custom.mako = {
        enable = lib.mkEnableOption "mako notification config";
      };

      config = lib.mkIf cfg.enable {
        xdg.configFile."mako/config".text = ''
          # OneDark colors
          background-color=#282c34ee
          text-color=#abb2bf
          border-color=#3e4451
          progress-color=over #61afef

          # Layout
          max-visible=3
          sort=-time
          layer=overlay
          anchor=top-right
          margin=20,20,0,0

          # Appearance
          font=JetBrainsMono Nerd Font 11
          width=400
          height=150
          padding=16
          border-size=1
          border-radius=0

          # Behavior
          default-timeout=5000
          ignore-timeout=0
          icons=1
          max-icon-size=48
          markup=1
          actions=1

          [urgency=low]
          border-color=#3e4451

          [urgency=normal]
          border-color=#61afef

          [urgency=critical]
          border-color=#e06c75
          default-timeout=0
        '';
      };
    };
}
