{ ... }:

{
  # Apps and systems add their own binds, startup commands and rules through
  # custom.niri.*; this module renders them into one config.kdl.
  flake.homeManagerModules.niri =
    {
      config,
      lib,
      pkgs,
      unstablePkgs,
      ...
    }:
    let
      cfg = config.custom.niri;
      inherit (lib) types;

      quote = arg: ''"${arg}"'';
      spawn = args: "spawn ${lib.concatMapStringsSep " " quote args};";
      action = a: if builtins.isList a then spawn a else a;

      niri-monitor = pkgs.writeShellScriptBin "niri-monitor" ''
        action="$1"
        n="$2"
        output=$(niri msg -j outputs | ${pkgs.jq}/bin/jq -r --argjson n "$n" \
          '[to_entries[] | {name: .key, x: .value.logical.x}] | sort_by(.x) | .[$n - 1].name // empty')
        [ -n "$output" ] && niri msg action "$action" "$output"
      '';

      workspaces = lib.range 1 9;
      perWorkspace = f: lib.listToAttrs (map (n: lib.nameValuePair (f n).name (f n).value) workspaces);
    in
    {
      options.custom.niri = {
        enable = lib.mkEnableOption "niri configuration";

        binds = lib.mkOption {
          type = types.attrsOf (types.either types.str (types.listOf types.str));
          default = { };
          description = ''
            Key binds. A list spawns that command, a string is a niri action.
            Bind properties go in the name, e.g. "XF86AudioMute allow-when-locked=true".
          '';
          example = {
            "Mod+B" = [ "zen-beta" ];
            "Mod+W" = "close-window;";
          };
        };

        startup = lib.mkOption {
          type = types.listOf (types.listOf types.str);
          default = [ ];
          description = "Commands spawned at startup, in order.";
        };

        environment = lib.mkOption {
          type = types.attrsOf types.str;
          default = { };
        };

        extraConfig = lib.mkOption {
          type = types.lines;
          default = "";
          description = "Extra KDL, e.g. window rules.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [
          niri-monitor
          pkgs.awww
          unstablePkgs.nirimon
        ];

        custom.niri = {
          startup = [
            [ "awww-daemon" ]
            [ "xwayland-satellite" ]
            [
              "sh"
              "-c"
              "nirimon -profile base; sleep 0.5; awww img --transition-type none ${config.home.homeDirectory}/setup/nixos/assets/background.png"
            ]
          ];

          environment = {
            DISPLAY = ":0";
            GDK_SCALE = "1.25";
            QT_SCALE_FACTOR = "1.25";
            GTK_THEME = "Adwaita:dark";
          };

          binds = {
            # Windows
            "Mod+W" = "close-window;";
            "Mod+F" = "maximize-column;";
            "Mod+Shift+F" = "fullscreen-window;";
            "Mod+T" = "toggle-window-floating;";
            "Mod+G" = "switch-focus-between-floating-and-tiling;";
            "Mod+O" = "toggle-overview;";

            # Focus (crosses monitors at edges)
            "Mod+H" = "focus-column-or-monitor-left;";
            "Mod+L" = "focus-column-or-monitor-right;";
            "Mod+J" = "focus-window-or-workspace-down;";
            "Mod+K" = "focus-window-or-workspace-up;";

            # Move windows (crosses monitors and workspaces at edges)
            "Mod+Shift+H" = "move-column-left-or-to-monitor-left;";
            "Mod+Shift+L" = "move-column-right-or-to-monitor-right;";
            "Mod+Shift+J" = "move-window-down-or-to-workspace-down;";
            "Mod+Shift+K" = "move-window-up-or-to-workspace-up;";

            # Mouse wheel
            "Mod+WheelScrollDown" = "focus-column-left;";
            "Mod+WheelScrollUp" = "focus-column-right;";
            "Mod+Shift+WheelScrollDown cooldown-ms=150" = "focus-workspace-down;";
            "Mod+Shift+WheelScrollUp cooldown-ms=150" = "focus-workspace-up;";
            "Mod+WheelScrollRight cooldown-ms=150" = "focus-workspace-down;";
            "Mod+WheelScrollLeft cooldown-ms=150" = "focus-workspace-up;";
            "Mod+Shift+TouchpadScrollDown" = "focus-workspace-down;";
            "Mod+Shift+TouchpadScrollUp" = "focus-workspace-up;";

            # Monitors
            "Mod+Ctrl+H" = "focus-monitor-left;";
            "Mod+Ctrl+L" = "focus-monitor-right;";
            "Mod+Ctrl+J" = "focus-workspace-down;";
            "Mod+Ctrl+K" = "focus-workspace-up;";
            "Mod+Ctrl+Shift+H" = "move-window-to-monitor-left;";
            "Mod+Ctrl+Shift+L" = "move-window-to-monitor-right;";
            "Mod+Ctrl+Shift+J" = "move-window-to-workspace-down;";
            "Mod+Ctrl+Shift+K" = "move-window-to-workspace-up;";

            # Resize
            "Mod+R" = "switch-preset-column-width;";
            "Mod+Alt+H" = ''set-column-width "-10%";'';
            "Mod+Alt+L" = ''set-column-width "+10%";'';
            "Mod+Alt+J" = ''set-window-height "-10%";'';
            "Mod+Alt+K" = ''set-window-height "+10%";'';

            # Columns
            "Mod+BracketLeft" = "consume-window-into-column;";
            "Mod+BracketRight" = [
              "sh"
              "-c"
              "niri msg action expel-window-from-column && niri msg action reset-window-height"
            ];
            "Mod+Shift+BracketLeft" = [
              "sh"
              "-c"
              "niri msg action consume-or-expel-window-left && niri msg action reset-window-height"
            ];
            "Mod+Shift+BracketRight" = [
              "sh"
              "-c"
              "niri msg action consume-or-expel-window-right && niri msg action reset-window-height"
            ];
            "Mod+Shift+T" = "toggle-column-tabbed-display;";

            # Screenshots
            "Print" = "screenshot;";
            "Mod+Print" = "screenshot-window;";

            # Session
            "Mod+Shift+E" = "quit;";
            "Mod+Shift+Slash" = "show-hotkey-overlay;";
          }
          // perWorkspace (n: {
            name = "Mod+${toString n}";
            value = "focus-workspace ${toString n};";
          })
          // perWorkspace (n: {
            name = "Mod+Shift+${toString n}";
            value = "move-column-to-workspace ${toString n};";
          })
          // perWorkspace (n: {
            name = "Mod+Ctrl+${toString n}";
            value = [
              "niri-monitor"
              "focus-monitor"
              (toString n)
            ];
          })
          // perWorkspace (n: {
            name = "Mod+Ctrl+Shift+${toString n}";
            value = [
              "niri-monitor"
              "move-window-to-monitor"
              (toString n)
            ];
          });
        };

        xdg.configFile."niri/config.kdl".text = ''
          ${builtins.readFile ./base.kdl}
          ${lib.concatMapStrings (
            args: "spawn-at-startup ${lib.concatMapStringsSep " " quote args}\n"
          ) cfg.startup}
          environment {
          ${lib.concatStrings (lib.mapAttrsToList (n: v: "    ${n} ${quote v}\n") cfg.environment)}}

          binds {
          ${lib.concatStrings (lib.mapAttrsToList (key: a: "    ${key} { ${action a} }\n") cfg.binds)}}

          ${cfg.extraConfig}
        '';
      };
    };
}
