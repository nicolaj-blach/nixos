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

        services.tlp = {
          enable = true;
          settings = {
            CPU_SCALING_GOVERNOR_ON_AC = "performance";
            CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
            CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
            CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
            USB_DENYLIST = "32ac:0012 32ac:0014";
          };
        };

        # Backlight write access for the video group
        services.udev.packages = [ pkgs.brightnessctl ];

        # Autosuspend on the input modules drops key-up events (stuck repeat)
        services.udev.extraRules = ''
          ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="32ac", ATTR{power/control}="on"
        '';
      })
    ];

    specialArgs = { inherit inputs metaOwner; };
  };
}
