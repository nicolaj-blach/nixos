{
  self,
  inputs,
  metaOwner,
  ...
}:

{
  flake.nixosConfigurations.personal-laptop = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";

    modules = [
      self.nixosModules.personal-computer
      ./_hw/hardware-configuration.nix
      ./_luks.nix

      ({ pkgs, ... }: {
        networking.hostName = "personal-laptop";
        boot.kernelParams = [ "amdgpu.sg_display=0" ];
        ai.rocm = true;

        services.fprintd.enable = true;
        services.fwupd.enable = true;
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

        # Backlight write access for the video group
        services.udev.packages = [ pkgs.brightnessctl ];
      })
    ];

    specialArgs = { inherit inputs metaOwner; };
  };
}
