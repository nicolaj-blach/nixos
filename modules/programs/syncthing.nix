{ config, ... }:

{
  services.syncthing = {
    enable = true;
    user = "nicolaj-blach";
    group = "users";
    dataDir = "/home/nicolaj-blach";
    configDir = "/home/nicolaj-blach/.config/syncthing";
    openDefaultPorts = true;

    settings = {
      folders."silverbullet-space" = {
        path = "/home/nicolaj-blach/notes";
        id = "silverbullet-space";
        fsWatcherEnabled = true;
      };

      options = {
        relaysEnabled = true;
        natEnabled = true;
        globalAnnounceEnabled = true;
        localAnnounceEnabled = true;
      };
    };

    overrideDevices = false;
    overrideFolders = false;
  };
}
