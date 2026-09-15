{
  self,
  inputs,
  metaOwner,
  ...
}:

{
  flake.nixosConfigurations.personal-desktop = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    modules = [
      inputs.home-manager.nixosModules.home-manager
      self.nixosModules.personal-computer
      self.nixosModules.personal-desktop-hardware

      ({ ... }: {
        networking.hostName = "personal-desktop";

        hardware.nvidia = {
          modesetting.enable = true;
          powerManagement.enable = false;
          open = false;
          nvidiaSettings = true;
        };
        services.xserver.videoDrivers = [ "nvidia" ];
      })
    ];

    specialArgs = { inherit inputs metaOwner; };
  };
}
