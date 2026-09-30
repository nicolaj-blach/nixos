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
      services.swayosd.enable = true;

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
