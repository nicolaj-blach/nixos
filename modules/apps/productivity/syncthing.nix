{ metaOwner, ... }:

{
  flake.nixosModules.syncthing =
    { ... }:

    {
      services.syncthing = {
        enable = true;
        user = metaOwner.username;
        dataDir = "/home/${metaOwner.username}";
        configDir = "/home/${metaOwner.username}/.config/syncthing";
        openDefaultPorts = true;
        settings.folders."silverbullet-space".path = "/home/${metaOwner.username}/notes";
      };
    };
}
