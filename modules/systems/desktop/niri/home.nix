{ ... }:

{
  flake.homeManagerModules.niri =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.custom.niri;
      niri-monitor = pkgs.writeShellScriptBin "niri-monitor" ''
        action="$1"
        n="$2"
        output=$(niri msg -j outputs | ${pkgs.jq}/bin/jq -r --argjson n "$n" \
          '[to_entries[] | {name: .key, x: .value.logical.x}] | sort_by(.x) | .[$n - 1].name // empty')
        [ -n "$output" ] && niri msg action "$action" "$output"
      '';
    in
    {
      options.custom.niri = {
        enable = lib.mkEnableOption "niri configuration";
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ niri-monitor ];

        # Write niri config as KDL
        xdg.configFile."niri/config.kdl".text = ''
          // Input configuration
          input {
              keyboard {
                  xkb {
                      layout "us"
                      options "compose:ralt"
                  }
              }

              mouse {
                  accel-speed 0.0
              }

              touchpad {
                  tap
                  natural-scroll
                  accel-speed 0.2
              }

              focus-follows-mouse max-scroll-amount="10%"
          }

          // Layout configuration
          layout {
              gaps 16
              center-focused-column "never"

              preset-column-widths {
                  proportion 0.33333
                  proportion 0.5
                  proportion 0.66667
              }

              default-column-width { proportion 0.5; }

              focus-ring {
                  width 2
                  active-color "#61afef"
                  inactive-color "#353b45"
              }
          }

          // Spawn at startup (lock first: greetd auto-logs in at boot)
          spawn-at-startup "hyprlock-wrapper"
          spawn-at-startup "quickshell-bar"
          spawn-at-startup "mako"
          spawn-at-startup "swww-daemon"
          spawn-at-startup "sh" "-c" "sleep 1 && swww img ~/nixos/assets/background.png"
          spawn-at-startup "xwayland-satellite"
          spawn-at-startup "nirimon" "-profile" "base"
          spawn-at-startup "cclipd" "-s" "2" "-t" "image/png" "-t" "image/*" "-t" "text/plain;charset=utf-8" "-t" "text/*"

          // Environment variables
          environment {
              DISPLAY ":0"
              GBM_BACKEND "nvidia-drm"
              __GLX_VENDOR_LIBRARY_NAME "nvidia"
              LIBVA_DRIVER_NAME "nvidia"
              GDK_SCALE "1.25"
              QT_SCALE_FACTOR "1.25"
              GTK_THEME "Adwaita:dark"
          }

          // Cursor
          cursor {
              xcursor-theme "Adwaita"
              xcursor-size 24
          }

          // Prefer no client-side decorations
          prefer-no-csd

          // Skip hotkey overlay at startup
          hotkey-overlay {
              skip-at-startup
          }

          // NVIDIA: hardware cursor plane shows garbage until the cursor first changes
          debug {
              disable-cursor-plane
          }

          // Disable hot corners (overview triggered by clicking bar instead)
          gestures {
              hot-corners {
                  off
              }
          }

          // Disable close animation: on NVIDIA the closing-window snapshot
          // renders as garbage and lingers on screen
          animations {
              window-close {
                  off
              }
          }

          // Window rules - floating popup windows
          window-rule {
              match app-id="popup"
              open-floating true
              default-column-width { fixed 450; }
              default-window-height { fixed 500; }
          }

          window-rule {
              match app-id="popup-term"
              open-floating true
              default-column-width { fixed 700; }
              default-window-height { fixed 500; }
          }

          // Keybindings
          binds {
              // Launch programs
              Mod+Return { spawn "emacs-terminal"; }
              Mod+Shift+Return { spawn "kitty"; }
              Mod+B { spawn "zen-beta"; }
              Mod+Space { spawn "kitty-popup" "-e" "otter-launcher" "-c" "/home/nicolaj-blach/.config/otter-launcher/config.toml"; }

              // Window management
              Mod+W { close-window; }
              Mod+F { maximize-column; }
              Mod+Shift+F { fullscreen-window; }
              Mod+T { toggle-window-floating; }
              Mod+O { toggle-overview; }

              // Focus (crosses monitors at edges)
              Mod+H { focus-column-or-monitor-left; }
              Mod+L { focus-column-or-monitor-right; }
              Mod+J { focus-window-down; }
              Mod+K { focus-window-up; }

              // Move windows (crosses monitors at edges)
              Mod+Shift+H { move-column-left-or-to-monitor-left; }
              Mod+Shift+L { move-column-right-or-to-monitor-right; }
              Mod+Shift+J { move-window-down; }
              Mod+Shift+K { move-window-up; }

              // Mouse wheel
              Mod+WheelScrollDown { focus-column-left; }
              Mod+WheelScrollUp { focus-column-right; }
              Mod+Shift+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
              Mod+Shift+WheelScrollUp cooldown-ms=150 { focus-workspace-up; }
              Mod+WheelScrollRight cooldown-ms=150 { focus-workspace-down; }
              Mod+WheelScrollLeft cooldown-ms=150 { focus-workspace-up; }
              Mod+Shift+TouchpadScrollDown { focus-workspace-down; }
              Mod+Shift+TouchpadScrollUp { focus-workspace-up; }

              // Monitors
              Mod+Ctrl+H { focus-monitor-left; }
              Mod+Ctrl+L { focus-monitor-right; }
              Mod+Ctrl+J { focus-workspace-down; }
              Mod+Ctrl+K { focus-workspace-up; }
              Mod+Ctrl+Shift+H { move-window-to-monitor-left; }
              Mod+Ctrl+Shift+L { move-window-to-monitor-right; }
              Mod+Ctrl+Shift+J { move-window-to-workspace-down; }
              Mod+Ctrl+Shift+K { move-window-to-workspace-up; }
              Mod+Ctrl+1 { spawn "niri-monitor" "focus-monitor" "1"; }
              Mod+Ctrl+2 { spawn "niri-monitor" "focus-monitor" "2"; }
              Mod+Ctrl+3 { spawn "niri-monitor" "focus-monitor" "3"; }
              Mod+Ctrl+4 { spawn "niri-monitor" "focus-monitor" "4"; }
              Mod+Ctrl+5 { spawn "niri-monitor" "focus-monitor" "5"; }
              Mod+Ctrl+6 { spawn "niri-monitor" "focus-monitor" "6"; }
              Mod+Ctrl+7 { spawn "niri-monitor" "focus-monitor" "7"; }
              Mod+Ctrl+8 { spawn "niri-monitor" "focus-monitor" "8"; }
              Mod+Ctrl+9 { spawn "niri-monitor" "focus-monitor" "9"; }
              Mod+Ctrl+Shift+1 { spawn "niri-monitor" "move-window-to-monitor" "1"; }
              Mod+Ctrl+Shift+2 { spawn "niri-monitor" "move-window-to-monitor" "2"; }
              Mod+Ctrl+Shift+3 { spawn "niri-monitor" "move-window-to-monitor" "3"; }
              Mod+Ctrl+Shift+4 { spawn "niri-monitor" "move-window-to-monitor" "4"; }
              Mod+Ctrl+Shift+5 { spawn "niri-monitor" "move-window-to-monitor" "5"; }
              Mod+Ctrl+Shift+6 { spawn "niri-monitor" "move-window-to-monitor" "6"; }
              Mod+Ctrl+Shift+7 { spawn "niri-monitor" "move-window-to-monitor" "7"; }
              Mod+Ctrl+Shift+8 { spawn "niri-monitor" "move-window-to-monitor" "8"; }
              Mod+Ctrl+Shift+9 { spawn "niri-monitor" "move-window-to-monitor" "9"; }

              // Workspaces
              Mod+1 { focus-workspace 1; }
              Mod+2 { focus-workspace 2; }
              Mod+3 { focus-workspace 3; }
              Mod+4 { focus-workspace 4; }
              Mod+5 { focus-workspace 5; }
              Mod+6 { focus-workspace 6; }
              Mod+7 { focus-workspace 7; }
              Mod+8 { focus-workspace 8; }
              Mod+9 { focus-workspace 9; }

              // Move to workspace
              Mod+Shift+1 { move-column-to-workspace 1; }
              Mod+Shift+2 { move-column-to-workspace 2; }
              Mod+Shift+3 { move-column-to-workspace 3; }
              Mod+Shift+4 { move-column-to-workspace 4; }
              Mod+Shift+5 { move-column-to-workspace 5; }
              Mod+Shift+6 { move-column-to-workspace 6; }
              Mod+Shift+7 { move-column-to-workspace 7; }
              Mod+Shift+8 { move-column-to-workspace 8; }
              Mod+Shift+9 { move-column-to-workspace 9; }

              // Resize
              Mod+R { switch-preset-column-width; }
              Mod+Alt+H { set-column-width "-10%"; }
              Mod+Alt+L { set-column-width "+10%"; }
              Mod+Alt+J { set-window-height "-10%"; }
              Mod+Alt+K { set-window-height "+10%"; }

              // Column management
              Mod+BracketLeft { consume-window-into-column; }
              Mod+BracketRight { spawn "sh" "-c" "niri msg action expel-window-from-column && niri msg action reset-window-height"; }
              Mod+Shift+BracketLeft { spawn "sh" "-c" "niri msg action consume-or-expel-window-left && niri msg action reset-window-height"; }
              Mod+Shift+BracketRight { spawn "sh" "-c" "niri msg action consume-or-expel-window-right && niri msg action reset-window-height"; }
              Mod+Shift+T { toggle-column-tabbed-display; }

              // Screenshots
              Print { screenshot; }
              Mod+Print { screenshot-window; }

              // Clipboard (Super+C / Super+V copy/paste are handled by kanata)
              Mod+Shift+V { spawn "kitty-popup" "-e" "fsel" "--cclip"; }

              // Notifications
              Mod+BackSpace { spawn "makoctl" "dismiss" "--all"; }
              Mod+N { spawn "kitty-popup" "-e" "fsel-notifications"; }

              // Emoji picker
              Mod+Period { spawn "kitty-popup" "-e" "fsel-emoji"; }

              // Session
              Mod+X { spawn "hyprlock-wrapper"; }
              Mod+Escape { spawn "kitty-popup" "-e" "fsel-system"; }
              Mod+Shift+E { quit; }
              Mod+Shift+Slash { show-hotkey-overlay; }

              // Media keys
              XF86AudioRaiseVolume allow-when-locked=true { spawn "swayosd-client" "--output-volume" "raise"; }
              XF86AudioLowerVolume allow-when-locked=true { spawn "swayosd-client" "--output-volume" "lower"; }
              XF86AudioMute allow-when-locked=true { spawn "swayosd-client" "--output-volume" "mute-toggle"; }
              XF86AudioNext allow-when-locked=true { spawn "playerctl" "next"; }
              XF86AudioPrev allow-when-locked=true { spawn "playerctl" "previous"; }
              XF86AudioPlay allow-when-locked=true { spawn "playerctl" "play-pause"; }
          }
        '';
      };
    };
}
