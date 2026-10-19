{
  self,
  inputs,
  metaOwner,
  ...
}:

{
  flake.nixosConfigurations.personal-labtop = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    modules = [
      self.nixosModules.personal-computer
      ./_hw/hardware-configuration.nix

      ({ ... }: {
        networking.hostName = "personal-labtop";
        ai.rocm = true;

        services.fprintd.enable = true;
        services.thermald.enable = true;
        powerManagement.powertop.enable = true;

        services.tlp = {
          enable = true;
          settings = {
            CPU_SCALING_GOVERNOR_ON_AC = "performance";
            CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
            CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
            CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
          };
        };

        programs.light.enable = true;
      })
    ];

    specialArgs = { inherit inputs metaOwner; };
  };
}
