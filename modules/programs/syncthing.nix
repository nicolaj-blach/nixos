_: {
  services.syncthing = {
    enable = true;
    user = "nicolaj-blach";
    group = "users";
    dataDir = "/home/nicolaj-blach";
    configDir = "/home/nicolaj-blach/.config/syncthing";
    openDefaultPorts = true;

    settings = {
      devices."nixos-server" = {
        id = "QDOVMWX-6WCNT5Z-3CRAG47-3I4NVE6-MGSHBTG-EFUM2XM-TF5H7D7-HHZU5QN";
      };

      folders."silverbullet-space" = {
        path = "/home/nicolaj-blach/notes";
        id = "silverbullet-space";
        devices = [ "nixos-server" ];
        fsWatcherEnabled = true;
      };

      options = {
        relaysEnabled = true;
        natEnabled = true;
        globalAnnounceEnabled = true;
        localAnnounceEnabled = true;
      };
    };

    overrideDevices = true;
    overrideFolders = true;
  };

  systemd.tmpfiles.rules = [
    "d /home/nicolaj-blach/notes 0755 nicolaj-blach users -"
  ];
}
