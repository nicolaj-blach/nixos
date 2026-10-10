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
      self.nixosModules.personal-computer
      self.nixosModules.sops
      self.nixosModules.ai
      ./_hw/hardware-configuration.nix

      ({ ... }: {
        networking.hostName = "personal-desktop";
        ai.enable = true;

        fileSystems."/" = {
          device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
        };
        fileSystems."/boot" = {
          device = "/dev/disk/by-label/boot";
          fsType = "vfat";
          options = [
            "fmask=0077"
            "dmask=0077"
          ];
        };

        hardware.nvidia = {
          modesetting.enable = true;
          powerManagement.enable = false;
          open = false;
          nvidiaSettings = true;
        };
        services.xserver.videoDrivers = [ "nvidia" ];

        home-manager.users.${metaOwner.username}.custom.niri = {
          environment = {
            GBM_BACKEND = "nvidia-drm";
            __GLX_VENDOR_LIBRARY_NAME = "nvidia";
            LIBVA_DRIVER_NAME = "nvidia";
          };
          # NVIDIA: the hardware cursor plane shows garbage until the cursor first
          # changes, and closing windows leave a garbage snapshot on screen
          extraConfig = ''
            debug {
                disable-cursor-plane
            }

            animations {
                window-open {
                    off
                }
                window-close {
                    off
                }
            }
          '';
        };
      })
    ];

    specialArgs = { inherit inputs metaOwner; };
  };
}
