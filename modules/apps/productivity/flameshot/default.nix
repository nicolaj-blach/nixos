{ ... }:

{
  # Screenshot editor on Mod+P; needs the multi-monitor portal fix in niri (see AGENTS.md)
  flake.homeManagerModules.flameshot =
    { config, pkgs, unstablePkgs, ... }:
    let
      # The niri-wide QT_SCALE_FACTOR=1.25 stretches the 1:1 capture past the screen
      flameshot = pkgs.symlinkJoin {
        name = "flameshot";
        paths = [ unstablePkgs.flameshot ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = "wrapProgram $out/bin/flameshot --set QT_SCALE_FACTOR 1";
      };

      # Opens the editor on the focused monitor. Qt numbers screens in
      # wl_output order, not left to right, so look the index up there.
      flameshot-niri = pkgs.writeShellScriptBin "flameshot-niri" ''
        output=$(niri msg -j focused-output | ${pkgs.jq}/bin/jq -r .name)
        n=$(${pkgs.wayland-utils}/bin/wayland-info -i wl_output | ${pkgs.gawk}/bin/awk -v o="$output" \
          '/interface: .wl_output./ { i++ } $1 == "name:" && $2 == o { print i - 1; exit }')
        exec ${flameshot}/bin/flameshot screen --edit --number "''${n:-0}"
      '';
    in
    {
      home.packages = [
        flameshot
        flameshot-niri
      ];

      xdg.configFile."flameshot/flameshot.ini".text = ''
        [General]
        savePath=${config.home.homeDirectory}/media/pictures/screenshots
        savePathFixed=true
        filenamePattern=Screenshot from %F %H-%M-%S
        disabledTrayIcon=true
        showStartupLaunchMessage=false
        showHelp=false
        showDesktopNotification=false
        autoCloseIdleDaemon=false
        uiColor=#61afef
        contrastUiColor=#282c34
        drawColor=#e06c75
        userColors=picker, #e06c75, #e5c07b, #98c379, #61afef, #c678dd, #abb2bf, #282c34
      '';

      custom.niri = {
        startup = [ [ "flameshot" ] ];
        binds."Mod+P" = [ "flameshot-niri" ];
        extraConfig = ''
          window-rule {
              match app-id="flameshot"
              focus-ring { off; }
              border { off; }
              shadow { off; }
          }

          window-rule {
              match app-id="flameshot" title="flameshot-pin"
              open-fullscreen false
              open-floating true
          }
        '';
      };
    };
}
