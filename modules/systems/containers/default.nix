{ ... }:
{
  flake.nixosModules.podman =
    { config, pkgs, ... }:
    let
      pruneFlags = [ "--filter" "until=168h" ];
    in
    {
      virtualisation = {
        containers.enable = true;
        podman = {
          enable = true;
          dockerCompat = true;
          defaultNetwork.settings.dns_enabled = true;
          autoPrune = {
            enable = true;
            dates = "weekly";
            flags = pruneFlags;
          };
        };
      };

      # Rootless: lazydocker and other Docker clients talk to the user socket.
      environment.variables.DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";

      systemd.user.services.podman-prune = {
        description = "Prune rootless podman";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${config.virtualisation.podman.package}/bin/podman system prune -f ${toString pruneFlags}";
        };
      };
      systemd.user.timers.podman-prune = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "weekly";
          Persistent = true;
        };
      };

      environment.systemPackages = with pkgs; [
        podman-compose
        podman-tui
        dive
      ];
    };

  flake.homeManagerModules.podman = { ... }: {
    programs.zsh.shellAliases = {
      lzd = "lazydocker";
      ptui = "podman-tui";

      pps = "podman ps";
      ppsa = "podman ps -a";
      pimg = "podman images";
      plog = "podman logs -f";
      pex = "podman exec -it";
      prun = "podman run --rm -it";
      pprune = "podman system prune";

      pc = "podman-compose";
      pcu = "podman-compose up -d";
      pcd = "podman-compose down";
      pcl = "podman-compose logs -f";
    };
  };
}
