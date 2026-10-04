{ ... }:

{
  # Discord client
  flake.homeManagerModules.vesktop =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.vesktop ];

      custom.niri.binds."Mod+D" = [ "vesktop" ];

      # Start minimized with the session
      systemd.user.services.vesktop = {
        Unit = {
          Description = "Vesktop (Discord), minimized";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service.ExecStart = "${pkgs.vesktop}/bin/vesktop --start-minimized";
        Install.WantedBy = [ "graphical-session.target" ];
      };

      xdg.mimeApps.defaultApplications."x-scheme-handler/discord" = "vesktop.desktop";
    };
}
