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
      ./_hw/hardware-configuration.nix

      ({ config, ... }: {
        networking.hostName = "personal-desktop";

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
          # RTX 5070 Ti (Blackwell) requires the open kernel module
          open = true;
          nvidiaSettings = true;
          package = config.boot.kernelPackages.nvidiaPackages.stable;
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
