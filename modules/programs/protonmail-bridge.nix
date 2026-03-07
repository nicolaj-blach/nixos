{ pkgs, ... }:

{
  # Run protonmail-bridge as a headless systemd service for the user.
  # First-time setup: run `protonmail-bridge -c` to log in interactively,
  # then restart the service with `systemctl --user restart protonmail-bridge`.
  systemd.user.services.protonmail-bridge = {
    description = "Proton Mail Bridge";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "default.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --noninteractive --log-level info";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
