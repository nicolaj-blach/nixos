{ ... }:

{
  flake.homeManagerModules.desktop-services =
    { lib, pkgs, ... }:
    let
      session = "graphical-session.target";

      userService = description: exec: {
        Unit = {
          Description = description;
          PartOf = [ session ];
          After = [ session ];
        };
        Service = {
          ExecStart = exec;
          Restart = "on-failure";
          RestartSec = 3;
        };
        Install.WantedBy = [ session ];
      };

      clipboard-notify = pkgs.writeShellScript "clipboard-notify" ''
        exec ${pkgs.wl-clipboard}/bin/wl-paste --watch \
          ${pkgs.libnotify}/bin/notify-send --urgency=low --expire-time=750 \
          --app-name=clipboard "Copied to clipboard"
      '';
    in
    {
      # Volume/brightness OSD (swayosd-client in niri binds talks to this)
      services.swayosd = {
        enable = true;
        stylePath = pkgs.writeText "swayosd-style.css" ''
          window {
            background: transparent;
          }

          #osd {
            background-color: alpha(#282c34, 0.9);
            border: 1px solid #3e4451;
            border-radius: 0;
            padding: 16px 24px;
          }

          #osd image {
            color: #abb2bf;
            -gtk-icon-style: symbolic;
          }

          #osd #container {
            margin: 0;
          }

          #osd progressbar {
            min-height: 8px;
            border-radius: 0;
          }

          #osd progressbar trough {
            background-color: #3e4451;
            border-radius: 0;
            min-height: 8px;
          }

          #osd progressbar progress {
            background-color: #61afef;
            border-radius: 0;
            min-height: 8px;
          }

          #osd label {
            color: #abb2bf;
            font-family: "JetBrainsMono Nerd Font";
            font-size: 14px;
          }

          #osd .muted progressbar progress {
            background-color: #3e4451;
          }

          #osd .muted image {
            color: #3e4451;
          }

          #osd .capslock-on image {
            color: #c678dd;
          }

          #osd .capslock-off image {
            color: #3e4451;
          }
        '';
      };

      # Automount USB drives with a notification
      services.udiskie = {
        enable = true;
        automount = true;
        notify = true;
        tray = "never";
      };

      systemd.user.services = {
        clipboard-notify = userService "Notify when something is copied" "${clipboard-notify}";
        vesktop =
          lib.recursiveUpdate
            (userService "Vesktop (Discord), minimized" "${pkgs.vesktop}/bin/vesktop --start-minimized")
            {
              Service.Restart = "no";
            };
      };
    };
}
