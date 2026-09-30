{ ... }:

{
  flake.nixosModules.hyprlock = { ... }: {
    programs.hyprlock.enable = true;
    security.pam.services.hyprlock.nodelay = true;
  };

  flake.homeManagerModules.hyprlock =
    {
      config,
      lib,
      pkgs,
      osConfig,
      ...
    }:
    let
      cfg = config.custom.hyprlock;
      # Only enable fingerprint auth on hosts with fprintd (the laptop)
      fingerprint = if (osConfig.services.fprintd.enable or false) then "true" else "false";

      # Show the lock UI on the focused niri output (hyprlock reads $HYPRLOCK_MONITOR)
      # Absolute paths so it also works from the hypridle systemd service
      hyprlock-wrapper = pkgs.writeShellScriptBin "hyprlock-wrapper" ''
        ${pkgs.procps}/bin/pidof hyprlock >/dev/null && exit 0
        HYPRLOCK_MONITOR=$(${pkgs.niri}/bin/niri msg -j focused-output 2>/dev/null | ${pkgs.jq}/bin/jq -r '.name // empty')
        export HYPRLOCK_MONITOR
        exec ${pkgs.hyprlock}/bin/hyprlock "$@"
      '';

      hyprlockConf = ''
        # OneDark colors
        $lock_bg = rgba(282c34ee)
        $lock_bg_transparent = rgba(282c3400)
        $lock_border = rgb(3e4451)
        $lock_muted = rgb(545862)
        $lock_fg = rgb(abb2bf)
        $lock_red = rgb(e06c75)
        $lock_accent = rgb(c678dd)

        # Primary monitor for UI elements (set by hyprlock-wrapper)
        $primary = $HYPRLOCK_MONITOR

        general {
            grace = 0
            immediate_render = true
            hide_cursor = true
            fail_timeout = 10000
        }

        animations {
            enabled = false
        }

        auth {
            fingerprint {
                enabled = ${fingerprint}
                ready_message = scan fingerprint to unlock
                present_message = scanning...
            }
        }

        # Wallpaper background with blur
        background {
            monitor =
            path = ${config.home.homeDirectory}/nixos/assets/background.png
            blur_passes = 3
            blur_size = 6
            noise = 0.01
            brightness = 0.8
        }

        # Main panel
        shape {
            monitor = $primary
            size = 1200, 460
            color = $lock_bg
            rounding = 0
            border_size = 1
            border_color = $lock_border
            position = 0, 0
            halign = center
            valign = center
        }

        # Title
        label {
            monitor = $primary
            text = [ locked ]
            color = $lock_accent
            font_size = 14
            font_family = JetBrainsMono Nerd Font Bold
            position = 0, 205
            halign = center
            valign = center
        }

        # Time
        label {
            monitor = $primary
            text = cmd[update:1000] date +'%H:%M:%S'
            color = $lock_fg
            font_size = 80
            font_family = JetBrainsMono Nerd Font Bold
            position = 0, 120
            halign = center
            valign = center
        }

        # Date
        label {
            monitor = $primary
            text = cmd[update:60000] date +'%A, %B %d'
            color = $lock_muted
            font_size = 18
            font_family = JetBrainsMono Nerd Font
            position = 0, 40
            halign = center
            valign = center
        }

        # Separator
        shape {
            monitor = $primary
            size = 1120, 1
            color = $lock_border
            rounding = 0
            border_size = 0
            position = 0, -10
            halign = center
            valign = center
        }

        # Password prompt label
        label {
            monitor = $primary
            text = password >
            color = $lock_muted
            font_size = 16
            font_family = JetBrainsMono Nerd Font
            position = -460, -80
            halign = center
            valign = center
        }

        # Input field border
        shape {
            monitor = $primary
            size = 910, 60
            color = $lock_bg_transparent
            rounding = 0
            border_size = 1
            border_color = $lock_border
            position = 85, -80
            halign = center
            valign = center
        }

        # Password input
        input-field {
            monitor = $primary
            size = 890, 50
            outline_thickness = 0
            dots_size = 0.4
            dots_spacing = 0.3
            dots_center = false
            dots_rounding = 0
            dots_text_format = *
            outer_color = rgba(00000000)
            inner_color = $lock_bg_transparent
            font_color = $lock_red
            font_size = 18
            font_family = JetBrainsMono Nerd Font
            fade_on_empty = false
            placeholder_text =
            hide_input = false
            rounding = 0
            check_color = rgba(00000000)
            fail_color = rgba(00000000)
            fail_text =
            fail_transition = 0
            dots_fade_time = 0
            fade_timeout = 0
            position = 85, -80
            halign = center
            valign = center
        }

        # Failed attempts
        label {
            monitor = $primary
            text = cmd[update:500] [ $ATTEMPTS -gt 0 ] && echo "$ATTEMPTS failed attempts"
            color = $lock_red
            font_size = 14
            font_family = JetBrainsMono Nerd Font
            position = 0, -140
            halign = center
            valign = center
        }

        # Status line
        label {
            monitor = $primary
            text = cmd[update:1000] echo "$(whoami)@$(hostname)"
            color = $lock_border
            font_size = 12
            font_family = JetBrainsMono Nerd Font
            position = 0, -195
            halign = center
            valign = center
        }
      '';
    in
    {
      options.custom.hyprlock = {
        enable = lib.mkEnableOption "hyprlock lock screen";
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ hyprlock-wrapper ];

        xdg.configFile."hypr/hyprlock.conf".text = hyprlockConf;

        # Lock before suspend only (no idle auto-lock)
        services.hypridle = {
          enable = true;
          settings.general = {
            lock_cmd = "${hyprlock-wrapper}/bin/hyprlock-wrapper";
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "${pkgs.niri}/bin/niri msg action power-on-monitors";
          };
        };
      };
    };
}
