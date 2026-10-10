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
      # The editor floats under the bar, so once the capture is taken (bar
      # included) hide the bar and grow the editor to the full monitor height.
      flameshot-niri = pkgs.writeShellScriptBin "flameshot-niri" ''
        jq=${pkgs.jq}/bin/jq
        focused=$(niri msg -j focused-output)
        output=$($jq -r .name <<<"$focused")
        height=$($jq -r .logical.height <<<"$focused")
        n=$(${pkgs.wayland-utils}/bin/wayland-info -i wl_output | ${pkgs.gawk}/bin/awk -v o="$output" \
          '/interface: .wl_output./ { i++ } $1 == "name:" && $2 == o { print i - 1; exit }')

        ${flameshot}/bin/flameshot screen --edit --number "''${n:-0}" &
        pid=$!
        trap 'quickshell-bar ipc call bar unhide' EXIT

        for _ in $(seq 100); do
          id=$(niri msg -j windows | $jq '.[] | select(.title == "flameshot") | .id' | head -1)
          [ -n "$id" ] && break
          kill -0 "$pid" 2>/dev/null || exit
          sleep 0.05
        done

        quickshell-bar ipc call bar hide
        [ -n "$id" ] && niri msg action set-window-height --id "$id" "$height"
        wait "$pid"
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
          // The capture window has no app-id. Float instead of fullscreen so
          // niri doesn't scroll to a new column.
          window-rule {
              match title="^flameshot$"
              open-fullscreen false
              open-floating true
              default-floating-position x=0 y=0
              focus-ring { off; }
              border { off; }
              shadow { off; }
          }

          window-rule {
              match title="^flameshot-pin$"
              open-floating true
          }
        '';
      };
    };
}
