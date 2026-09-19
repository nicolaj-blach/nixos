{ ... }:
{
  flake.homeManagerModules.hyprland =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.wayland.windowManager.hyprland;
    in
    {
      config = lib.mkIf (cfg.enable or false) {
        # Prevent Hyprland from using Lua config - force it to use hyprland.conf
        xdg.configFile."hypr/hyprland.lua".text = ''
          -- Load the declarative config instead of Lua
          hl.source("~/.config/hypr/hyprland.conf")
        '';

        wayland.windowManager.hyprland = {
          settings = {
            # Program variables
            "$mainMod" = "SUPER";
            "$terminal" = "ghostty";
            "$fileManager" = "yazi";
            "$browser" = "zen";
            "$menu" = "ghostty --title=terminal-float -e fsel --detach";

            # Color variables (defaults, can be overridden by tinty)
            "$active_border_1" = "rgb(61afef)";
            "$active_border_2" = "rgb(c678dd)";
            "$inactive_border" = "rgb(353b45)";
            "$shadow_color" = "rgb(282c34)";

            # Environment variables
            env = [
              # XWayland HiDPI - render at native res, scale via toolkit
              "GDK_SCALE,1.25"
              "QT_SCALE_FACTOR,1.25"

              # Cursor
              "XCURSOR_THEME,Adwaita"
              "XCURSOR_SIZE,30"
              "HYPRCURSOR_SIZE,30"

              # Dark theme for GTK and QT applications
              "GTK_THEME,Adwaita:dark"
              # Enable compose key support in GTK 4.20+ apps (like Ghostty)
              "GTK_IM_MODULE,simple"
              "QT_QPA_PLATFORMTHEME,qt5ct"

              # NVIDIA Wayland
              "GBM_BACKEND,nvidia-drm"
              "__GLX_VENDOR_LIBRARY_NAME,nvidia"
              "WLR_NO_HARDWARE_CURSORS,1"
              "LIBVA_DRIVER_NAME,nvidia"
              "__GL_GSYNC_ALLOWED,1"
              "__GL_VRR_ALLOWED,1"
            ];

            # General settings
            general = {
              gaps_in = 5;
              gaps_out = 15;
              border_size = 1;
              "col.active_border" = "$active_border_1";
              "col.inactive_border" = "$inactive_border";
              resize_on_border = false;
              allow_tearing = true;
              layout = "dwindle";
            };

            # Decoration settings
            decoration = {
              rounding = 0;
              active_opacity = 0.9;
              inactive_opacity = 0.85;

              shadow = {
                enabled = false;
              };

              blur = {
                enabled = true;
                size = 6;
                passes = 3;
                vibrancy = 0.1696;
              };
            };

            # Animation settings
            animations = {
              enabled = true;

              bezier = [
                "easeOutQuint, 0.23, 1, 0.32, 1"
                "easeInOutCubic, 0.65, 0.05, 0.36, 1"
                "linear, 0, 0, 1, 1"
                "almostLinear, 0.5, 0.5, 0.75, 1"
                "quick, 0.15, 0, 0.1, 1"
              ];

              animation = [
                "global, 1, 10, default"
                "border, 1, 5.39, easeOutQuint"
                "windows, 1, 4.79, easeOutQuint"
                "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
                "windowsOut, 1, 1.49, linear, popin 87%"
                "fadeIn, 1, 1.73, almostLinear"
                "fadeOut, 1, 1.46, almostLinear"
                "fade, 1, 3.03, quick"
                "layers, 1, 3.81, easeOutQuint"
                "layersIn, 1, 4, easeOutQuint, fade"
                "layersOut, 1, 1.5, linear, fade"
                "fadeLayersIn, 1, 1.79, almostLinear"
                "fadeLayersOut, 1, 1.39, almostLinear"
                "workspaces, 1, 1.94, almostLinear, fade"
                "workspacesIn, 1, 1.21, almostLinear, fade"
                "workspacesOut, 1, 1.94, almostLinear, fade"
                "zoomFactor, 1, 7, quick"
              ];
            };

            # Dwindle layout settings
            dwindle = {
              preserve_split = true;
            };

            # Master layout settings
            master = {
              new_status = "master";
            };

            # Misc settings
            misc = {
              force_default_wallpaper = -1;
              disable_hyprland_logo = true;
            };

            # XWayland settings
            xwayland = {
              force_zero_scaling = true;
            };

            # Input settings
            input = {
              kb_layout = "us";
              kb_variant = "";
              kb_model = "";
              kb_options = "compose:ralt";
              kb_rules = "";
              follow_mouse = 1;
              sensitivity = 0;

              touchpad = {
                natural_scroll = false;
              };
            };

            # Gestures
            gestures = {
              workspace_swipe = false;
            };

            # Device-specific input settings
            device = {
              name = "epic-mouse-v1";
              sensitivity = -0.5;
            };

            # Load split-monitor-workspaces plugin
            # FIXME: Disabled - ABI mismatch with current Hyprland version
            # plugin = [
            #   "/run/current-system/sw/lib/libsplit-monitor-workspaces.so"
            # ];

            # Exec-once commands (autostart)
            exec-once = [
              # Clipboard daemon
              "systemctl --user start cclipd"

              # Lock screen on startup
              "hyprlock-wrapper"

              # System services
              "udiskie --automount --notify"
              "swayosd-server"
              "mako"
              "~/.local/bin/clipboard-notify"

              # Wallpaper
              "swww-daemon"
              "sleep 1 && ~/.config/hypr/scripts/random-wallpaper.sh"

              # Theme sync
              "tinty sync && tinty init"

              # Status bar
              "while true; do top-bar; sleep 1; done"

              # Auto-start apps
              "vesktop --start-minimized"

              # GPG agent
              "gpg-connect-agent /bye"

              # Mail client in special workspace
              "hyprctl dispatch -- exec [workspace special:mail silent] ghostty -e aerc"
            ];

            # Keybindings
            bind = [
              # Launch programs
              "$mainMod, RETURN, exec, $terminal"
              "$mainMod, E, exec, $terminal --title terminal-float-large -e ~/.local/bin/yazi-picker"
              "$mainMod, SPACE, exec, $menu"
              "$mainMod, B, exec, $browser"
              "$mainMod SHIFT, D, exec, chromium --app=https://discord.com/app"
              "$mainMod SHIFT, E, exec, $terminal -e aerc"
              "$mainMod SHIFT, F, exec, $terminal --title terminal-float-large -e fleeting-note"
              "$mainMod, X, exec, $terminal -e screensaver"
              "$mainMod SHIFT, X, exec, hyprlock-wrapper"

              # Power menu
              "$mainMod, ESCAPE, exec, $terminal --title terminal-float -e power-menu"

              # Utilities
              "$mainMod SHIFT, SPACE, exec, $terminal --title terminal-float -e clipboard-picker"
              "$mainMod, C, exec, $terminal --title terminal-float-large -e qalc"
              "$mainMod, period, exec, $terminal --title terminal-float -e emoji-picker"

              # Floating terminals
              "$mainMod SHIFT, W, exec, ~/.local/bin/tui-wifi"
              "$mainMod SHIFT, B, exec, ~/.local/bin/tui-bluetooth"
              "$mainMod SHIFT, A, exec, ~/.local/bin/tui-audio"

              # Notes
              "$mainMod, semicolon, exec, $terminal --title terminal-float-large --directory $HOME/notes -e nvim"
              "$mainMod SHIFT, semicolon, togglespecialworkspace, notes"

              # Window management
              "$mainMod, W, killactive,"
              "$mainMod, V, togglefloating,"
              "$mainMod SHIFT, P, exec, ~/.config/hypr/scripts/pin-image.sh"
              "$mainMod, F, fullscreen, 0"
              "$mainMod, T, layoutmsg, togglesplit"

              # Move focus
              "$mainMod, H, movefocus, l"
              "$mainMod, L, movefocus, r"
              "$mainMod, K, movefocus, u"
              "$mainMod, J, movefocus, d"

              # Move windows
              "$mainMod SHIFT, H, movewindow, l"
              "$mainMod SHIFT, L, movewindow, r"
              "$mainMod SHIFT, K, movewindow, u"
              "$mainMod SHIFT, J, movewindow, d"

              # Workspaces
              "$mainMod, 1, workspace, 1"
              "$mainMod, 2, workspace, 2"
              "$mainMod, 3, workspace, 3"
              "$mainMod, 4, workspace, 4"
              "$mainMod, 5, workspace, 5"
              "$mainMod, 6, workspace, 6"
              "$mainMod, 7, workspace, 7"
              "$mainMod, 8, workspace, 8"
              "$mainMod, 9, workspace, 9"

              # Move window to workspace (and follow)
              "$mainMod SHIFT, 1, movetoworkspace, 1"
              "$mainMod SHIFT, 2, movetoworkspace, 2"
              "$mainMod SHIFT, 3, movetoworkspace, 3"
              "$mainMod SHIFT, 4, movetoworkspace, 4"
              "$mainMod SHIFT, 5, movetoworkspace, 5"
              "$mainMod SHIFT, 6, movetoworkspace, 6"
              "$mainMod SHIFT, 7, movetoworkspace, 7"
              "$mainMod SHIFT, 8, movetoworkspace, 8"
              "$mainMod SHIFT, 9, movetoworkspace, 9"

              # Special workspace (scratchpad)
              "$mainMod, S, togglespecialworkspace, magic"
              "$mainMod SHIFT, S, movetoworkspace, special:magic"

              # Scroll through workspaces
              "$mainMod, mouse_down, workspace, +1"
              "$mainMod, mouse_up, workspace, -1"

              # Monitor focus (generic next/prev)
              "$mainMod CTRL, H, focusmonitor, +1"
              "$mainMod CTRL, L, focusmonitor, -1"

              # Move window to monitor (generic next/prev)
              "$mainMod CTRL SHIFT, H, movewindow, mon:+1"
              "$mainMod CTRL SHIFT, L, movewindow, mon:-1"

              # Resize mode
              "$mainMod, R, submap, resize"

              # Notifications
              "$mainMod, N, exec, notification-menu"
              "$mainMod SHIFT, N, exec, package-menu"
              "$mainMod, BACKSPACE, exec, makoctl dismiss --all"

              # Screenshot
              ", Print, exec, ~/.config/hypr/scripts/screenshot.sh"

              # Color picker
              "$mainMod SHIFT, C, exec, hyprpicker -a"
            ];

            # Repeatable bindings (for resize)
            binde = [
              # Resize windows (direct) - use ALT instead of CTRL
              "$mainMod ALT, H, resizeactive, -20 0"
              "$mainMod ALT, L, resizeactive, 20 0"
              "$mainMod ALT, K, resizeactive, 0 -20"
              "$mainMod ALT, J, resizeactive, 0 20"
            ];

            # Mouse bindings
            bindm = [
              "$mainMod, mouse:272, movewindow"
              "$mainMod, mouse:273, resizewindow"
            ];

            # Locked bindings (work even when locked)
            bindl = [
              ", XF86AudioNext, exec, playerctl next"
              ", XF86AudioPause, exec, playerctl play-pause"
              ", XF86AudioPlay, exec, playerctl play-pause"
              ", XF86AudioPrev, exec, playerctl previous"
            ];

            # Repeatable locked bindings (for media keys)
            bindel = [
              ", XF86AudioRaiseVolume, exec, swayosd-focused --output-volume raise"
              ", XF86AudioLowerVolume, exec, swayosd-focused --output-volume lower"
              ", XF86AudioMute, exec, swayosd-focused --output-volume mute-toggle"
              ", XF86AudioMicMute, exec, swayosd-focused --input-volume mute-toggle"
              ", XF86MonBrightnessUp, exec, swayosd-focused --brightness raise"
              ", XF86MonBrightnessDown, exec, swayosd-focused --brightness lower"
            ];

            # Window rules
            windowrule = [
              # Ignore maximize requests from apps
              "match:class .*, suppress_event maximize"

              # Fix some dragging issues with XWayland
              "match:class ^$, match:title ^$, match:xwayland true, match:float true, match:fullscreen false, match:pin false, no_focus on"

              # Floating terminals - centered
              "match:title ^terminal-float$, float on"
              "match:title ^terminal-float$, size 800 500"
              "match:title ^terminal-float$, center on"

              # Floating terminals - large
              "match:title ^terminal-float-large$, float on"
              "match:title ^terminal-float-large$, size 1400 900"
              "match:title ^terminal-float-large$, center on"

              # Screensaver - fullscreen, no decorations
              "match:title ^screensaver$, fullscreen on"
              "match:title ^screensaver$, no_anim on"

              # Gaming optimizations
              "match:class ^steam_app_.*$, immediate on"
              "match:class ^steam_app_.*$, opaque on"
              "match:class ^steam_app_.*$, no_blur on"
              "match:class ^steam_app_.*$, fullscreen on"
            ];

            # Layer rules
            layerrule = [
              # AGS bar - blur background
              "blur on, match:namespace bar"
              "ignore_alpha 0.3, match:namespace bar"
            ];

            # Workspace rules
            workspace = [
              # Notes special workspace - launch nvim on first open
              "special:notes, on-created-empty:$terminal --directory $HOME/notes -e nvim"
            ];
          };

          # Extra config for submap
          extraConfig = ''
            # Resize submap
            submap = resize
            binde = , H, resizeactive, -20 0
            binde = , L, resizeactive, 20 0
            binde = , K, resizeactive, 0 -20
            binde = , J, resizeactive, 0 20
            binde = SHIFT, H, resizeactive, -80 0
            binde = SHIFT, L, resizeactive, 80 0
            binde = SHIFT, K, resizeactive, 0 -80
            binde = SHIFT, J, resizeactive, 0 80
            bind = , ESCAPE, submap, reset
            bind = , RETURN, submap, reset
            submap = reset

            # Source host-specific config (monitors, etc.) if it exists
            source = ~/.config/hypr/local.conf
          '';
        };
      };
    };
}
